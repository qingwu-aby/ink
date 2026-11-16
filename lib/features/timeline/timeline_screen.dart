import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';
import '../relations/relation_editor_sheet.dart';

/// 关系演化：把「谁和谁的关系从第几章到第几章」画成一条时间带。
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  int? _focusEntity;

  @override
  Widget build(BuildContext context) {
    final chapters = ref.watch(chaptersProvider(widget.projectId)).value ?? const <Chapter>[];
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final relations = ref.watch(relationsProvider(widget.projectId)).value ?? const <Relation>[];
    final foreshadows =
        ref.watch(foreshadowsProvider(widget.projectId)).value ?? const <Foreshadow>[];

    final byId = {for (final entity in entities) entity.id: entity};
    final chapterCount = chapters.isEmpty
        ? 0
        : chapters.map((c) => c.index).reduce((a, b) => a > b ? a : b);

    final visible = _focusEntity == null
        ? relations
        : relations
            .where((r) => r.fromId == _focusEntity || r.toId == _focusEntity)
            .toList();

    final sorted = [...visible]..sort((a, b) {
        final byStart = a.validFrom.compareTo(b.validFrom);
        if (byStart != 0) return byStart;
        return a.id.compareTo(b.id);
      });

    // 有关系的实体，按连线数排前面，用来做筛选条
    final degree = <int, int>{};
    for (final relation in relations) {
      degree[relation.fromId] = (degree[relation.fromId] ?? 0) + 1;
      degree[relation.toId] = (degree[relation.toId] ?? 0) + 1;
    }
    final filterable = entities.where((e) => degree.containsKey(e.id)).toList()
      ..sort((a, b) => (degree[b.id] ?? 0).compareTo(degree[a.id] ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('关系演化')),
      body: chapterCount == 0
          ? const EmptyState(
              icon: Icons.timeline_outlined,
              title: '还没有章节',
              description: '关系是按章节区间记录的，先写（或导入）正文，这张时间带才有意义。',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Text(
                  '第 1–$chapterCount 章 · ${relations.length} 条关系',
                  style: context.texts.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '一条色带就是一段关系：起点是关系成立那一章，终点是失效那一章；'
                  '没有终点的会一直延伸到最新一章。',
                  style: context.texts.bodySmall?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: '全部 ${relations.length}',
                        selected: _focusEntity == null,
                        onTap: () => setState(() => _focusEntity = null),
                      ),
                      for (final entity in filterable)
                        _FilterChip(
                          label: entity.name,
                          selected: _focusEntity == entity.id,
                          color: EntityKind.parse(entity.kind)
                              .color(Theme.of(context).brightness),
                          onTap: () => setState(
                            () => _focusEntity = _focusEntity == entity.id ? null : entity.id,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Axis(labelWidth: _labelWidth, chapterCount: chapterCount),
                const SizedBox(height: 4),
                if (sorted.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('这个范围里没有关系。', style: context.texts.bodyMedium),
                    ),
                  )
                else
                  for (final relation in sorted)
                    _RelationTrack(
                      relation: relation,
                      from: byId[relation.fromId],
                      to: byId[relation.toId],
                      chapterCount: chapterCount,
                      labelWidth: _labelWidth,
                      onTap: () => showRelationEditor(
                        context,
                        projectId: widget.projectId,
                        fromId: relation.fromId,
                        toId: relation.toId,
                        relationId: relation.id,
                        kind: relation.kind,
                        strength: relation.strength,
                        note: relation.note,
                        validFrom: relation.validFrom,
                        validTo: relation.validTo,
                      ),
                    ),
                if (foreshadows.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('伏笔', style: context.texts.titleMedium),
                  const SizedBox(height: 8),
                  for (final hook in foreshadows)
                    _HookTrack(
                      hook: hook,
                      chapterCount: chapterCount,
                      labelWidth: _labelWidth,
                    ),
                ],
              ],
            ),
    );
  }

  double get _labelWidth => MediaQuery.sizeOf(context).width < 420 ? 108 : 140;
}

class _Axis extends StatelessWidget {
  const _Axis({required this.labelWidth, required this.chapterCount});

  final double labelWidth;
  final int chapterCount;

  @override
  Widget build(BuildContext context) {
    final step = math.max(1, (chapterCount / 6).ceil());
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text('关系', style: context.texts.labelSmall),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final unit = constraints.maxWidth / chapterCount;
              return SizedBox(
                height: 16,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var chapter = 1; chapter <= chapterCount; chapter += step)
                      Positioned(
                        left: (chapter - 1) * unit,
                        child: Text(
                          '$chapter',
                          style: context.texts.labelSmall?.copyWith(fontSize: 9.5),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RelationTrack extends StatelessWidget {
  const _RelationTrack({
    required this.relation,
    required this.from,
    required this.to,
    required this.chapterCount,
    required this.labelWidth,
    required this.onTap,
  });

  final Relation relation;
  final Entity? from;
  final Entity? to;
  final int chapterCount;
  final double labelWidth;
  final VoidCallback onTap;

  Color _color(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (relation.kind) {
      'enemy' => dark ? const Color(0xFFDD7A69) : Mo.vermilion,
      'ally' || 'friend' || 'peer' || 'clan' => dark ? const Color(0xFF6FB3A4) : Mo.jade,
      'spouse' || 'crush' => dark ? const Color(0xFFB08AA4) : Mo.plum,
      'mentor' || 'liege' || 'parent' => dark ? const Color(0xFF8FB7C9) : Mo.indigo,
      _ => dark ? const Color(0xFFD9A84E) : Mo.gold,
    };
  }

  @override
  Widget build(BuildContext context) {
    final kind = RelationKind.parse(relation.kind);
    final start = relation.validFrom.clamp(1, chapterCount);
    final end = (relation.validTo ?? chapterCount).clamp(start, chapterCount);
    final open = relation.validTo == null;
    final color = _color(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          kind.symmetric ? Icons.swap_horiz : Icons.east,
                          size: 12,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${from?.name ?? '?'} · ${to?.name ?? '?'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 11.5,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(kind.label, style: context.texts.labelSmall?.copyWith(fontSize: 9.5)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final unit = constraints.maxWidth / chapterCount;
                  final left = (start - 1) * unit;
                  final width = math.max(unit, (end - start + 1) * unit);
                  return SizedBox(
                    height: 30,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 14.5,
                          child: Container(height: 1, color: context.border),
                        ),
                        Positioned(
                          left: left,
                          top: 6,
                          width: width,
                          height: 17,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: open ? 0.30 : 0.20),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withValues(alpha: 0.55)),
                            ),
                            child: width > 46
                                ? Center(
                                    child: Text(
                                      open ? '至今' : '第 $start–$end 章',
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(
                                        fontSize: 9,
                                        height: 1,
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HookTrack extends StatelessWidget {
  const _HookTrack({required this.hook, required this.chapterCount, required this.labelWidth});

  final Foreshadow hook;
  final int chapterCount;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = hook.resolvedChapter;
    final color = resolved == null ? Mo.gold : Mo.jade;
    final start = hook.plantedChapter.clamp(1, chapterCount);
    final end = (resolved ?? chapterCount).clamp(start, chapterCount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                hook.hook,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySmall?.copyWith(fontSize: 11),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final unit = constraints.maxWidth / chapterCount;
                final left = (start - 1) * unit;
                final width = math.max(unit, (end - start + 1) * unit);
                return SizedBox(
                  height: 26,
                  child: Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: 12,
                        width: width,
                        child: resolved == null
                            ? CustomPaint(
                                size: Size(width, 1),
                                painter: _DashedLinePainter(
                                  color: color.withValues(alpha: 0.5),
                                ),
                              )
                            : Container(height: 1, color: color.withValues(alpha: 0.45)),
                      ),
                      Positioned(
                        left: left - 3,
                        top: 9,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                      ),
                      if (resolved != null)
                        Positioned(
                          left: left + width - 4,
                          top: 8,
                          child: Icon(Icons.check, size: 10, color: color),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawLine(Offset(x, 0.5), Offset(math.min(x + 3, size.width), 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? base.withValues(alpha: 0.13) : context.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? base.withValues(alpha: 0.42) : context.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? base : context.soft,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
