import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/graph/force_layout.dart';
import '../../domain/graph/graph_builder.dart';
import '../../domain/snapshot/snapshot_rules.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';
import '../graph/graph_painter.dart';

/// 章节快照：把时间拨到第 N 章，看那一刻的世界长什么样。
///
/// 布局只在整图上算一次，拖动章节只做「哪些点、哪些边已经出现」的过滤，
/// 所以色带会随着章节生长，而节点不会乱跳。
class SnapshotScreen extends ConsumerStatefulWidget {
  const SnapshotScreen({super.key, required this.projectId, this.initialChapter});

  final int projectId;
  final int? initialChapter;

  @override
  ConsumerState<SnapshotScreen> createState() => _SnapshotScreenState();
}

class _SnapshotScreenState extends ConsumerState<SnapshotScreen> {
  final _labels = LabelCache();

  ForceLayout? _fullLayout;
  Map<int, Entity> _entities = const {};
  List<Relation> _relations = const [];
  List<Relation> _edgeRelations = const [];
  Map<int, int> _firstSeen = const {};
  Map<int, int> _mentionCounts = const {};
  Map<int, int> _chaptersById = const {};

  String _signature = '';
  int _chapter = 1;
  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _lastSize = Size.zero;
  bool _initialised = false;

  void _sync(
    List<Entity> entities,
    List<Relation> relations,
    List<Chapter> chapters,
    List<Mention> mentions,
    Map<int, int> counts,
  ) {
    final signature = '${entities.length}|${relations.length}|${chapters.length}|${mentions.length}';
    final chapterIndexById = {for (final c in chapters) c.id: c.index};
    final maxChapter = chapters.isEmpty
        ? 0
        : chapters.map((c) => c.index).reduce((a, b) => a > b ? a : b);

    if (signature == _signature && _initialised) return;
    _signature = signature;

    final firstSeen = computeFirstSeen(
      entities: entities,
      mentions: mentions,
      chapterIndexById: chapterIndexById,
    );

    final scene = buildGraphScene(entities, relations);
    final layout = scene.layout;
    if (!_initialised) {
      layout.seed(spacing: 100);
      var guard = 0;
      while (!layout.isSettled && guard < 500) {
        layout.step();
        guard++;
      }
    }

    _entities = scene.entityById;
    _relations = relations;
    _edgeRelations = scene.edgeRelations;
    _firstSeen = firstSeen;
    _mentionCounts = counts;
    _chaptersById = chapterIndexById;
    _fullLayout = layout;

    if (!_initialised) {
      _initialised = true;
      _chapter = (widget.initialChapter ?? maxChapter).clamp(1, math.max(maxChapter, 1));
    }
    _chapter = _chapter.clamp(1, math.max(maxChapter, 1));
    _fitIfNeeded();
  }

  void _fitIfNeeded({bool force = false}) {
    final layout = _fullLayout;
    if (layout == null || layout.nodes.isEmpty || _lastSize.isEmpty) return;
    if (!force && _scale != 1) return;
    final bounds = layout.bounds();
    const padding = 48.0;
    final scaleX = (_lastSize.width - padding) / math.max(bounds.width, 1);
    final scaleY = (_lastSize.height - padding) / math.max(bounds.height, 1);
    _scale = math.min(scaleX, scaleY).clamp(0.12, 1.3);
    _offset = Offset(_lastSize.width / 2, _lastSize.height / 2) - bounds.center * _scale;
  }

  /// 可见子图：沿用整图算好的坐标，只挑出「这一刻已经存在」的点和边。
  ({ForceLayout layout, List<String> kinds}) _subset(SnapshotSlice slice) {
    final full = _fullLayout!;
    final visibleIds = slice.entityIds;
    final activeIds = {for (final relation in slice.relations) relation.id};

    final nodes = <ForceNode>[];
    final indexOf = <int, int>{};
    for (final node in full.nodes) {
      if (!visibleIds.contains(node.id)) continue;
      indexOf[node.id] = nodes.length;
      nodes.add(node);
    }

    final edges = <ForceEdge>[];
    final kinds = <String>[];
    for (var i = 0; i < full.edges.length; i++) {
      final edge = full.edges[i];
      final fromId = full.nodes[edge.a].id;
      final toId = full.nodes[edge.b].id;
      if (!visibleIds.contains(fromId) || !visibleIds.contains(toId)) continue;

      if (i >= _edgeRelations.length) continue;
      final relation = _edgeRelations[i];
      if (!activeIds.contains(relation.id)) continue;

      edges.add(ForceEdge(a: indexOf[fromId]!, b: indexOf[toId]!, strength: edge.strength));
      kinds.add(relation.kind);
    }

    return (
      layout: ForceLayout(nodes: nodes, edges: edges),
      kinds: kinds,
    );
  }

  /// 人物在该章是否已经身故：没到退场章就还是活的。
  Entity _statusAt(Entity entity, int chapter) {
    final status = statusAt(entity, chapter);
    return status == entity.status ? entity : entity.copyWith(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final chapters = ref.watch(chaptersProvider(widget.projectId)).value ?? const <Chapter>[];
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final relations = ref.watch(relationsProvider(widget.projectId)).value ?? const <Relation>[];
    final mentions = ref.watch(mentionsProvider(widget.projectId)).value ?? const <Mention>[];
    final counts = ref.watch(mentionCountsProvider(widget.projectId)).value ?? const <int, int>{};

    if (chapters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('章节快照')),
        body: const EmptyState(
          icon: Icons.layers_outlined,
          title: '还没有章节',
          description: '快照是按章节时间轴走的，先把正文写起来（或导进来）。',
        ),
      );
    }

    _sync(entities, relations, chapters, mentions, counts);

    final maxChapter = chapters.map((c) => c.index).reduce((a, b) => a > b ? a : b);
    Chapter? chapter;
    for (final candidate in chapters) {
      if (candidate.index == _chapter) {
        chapter = candidate;
        break;
      }
    }
    final slice = _fullLayout == null
        ? null
        : sliceAt(
            chapter: _chapter,
            entities: entities,
            relations: relations,
            firstSeen: _firstSeen,
          );
    final subset = slice == null ? null : _subset(slice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('章节快照'),
        actions: [
          IconButton(
            tooltip: '回到整图',
            onPressed: () => context.push('/p/${widget.projectId}/timeline'),
            icon: const Icon(Icons.timeline, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          _Header(
            chapter: chapter,
            chapterCount: maxChapter,
            nodeCount: subset?.layout.nodes.length ?? 0,
            edgeCount: subset?.layout.edges.length ?? 0,
            onChanged: (value) => setState(() {
              _chapter = value.round().clamp(1, maxChapter);
            }),
            maxChapter: maxChapter,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
                _fitIfNeeded();
                if (subset == null || subset.layout.nodes.isEmpty) {
                  return const Center(child: Text('这一章之前还没有任何实体'));
                }
                final entitiesThen = <int, Entity>{
                  for (final entity in _entities.values)
                    entity.id: _statusAt(entity, _chapter),
                };
                return CustomPaint(
                  size: _lastSize,
                  painter: GraphPainter(
                    layout: subset.layout,
                    entityById: entitiesThen,
                    relationLabel: (index) =>
                        index < subset.kinds.length ? subset.kinds[index] : 'other',
                    scale: _scale,
                    offset: _offset,
                    dark: Theme.of(context).brightness == Brightness.dark,
                    selectedId: null,
                    focusId: null,
                    mentionCounts: _mentionCounts,
                    highlightKinds: const {},
                    labelCache: _labels,
                    forceLabels: true,
                  ),
                );
              },
            ),
          ),
          _DeltaPanel(slice: slice, entities: entities, relations: relations),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.chapter,
    required this.chapterCount,
    required this.nodeCount,
    required this.edgeCount,
    required this.onChanged,
    required this.maxChapter,
  });

  final Chapter? chapter;
  final int chapterCount;
  final int nodeCount;
  final int edgeCount;
  final ValueChanged<double> onChanged;
  final int maxChapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '第 ${chapter?.index ?? 1} 章',
                style: context.texts.titleLarge?.copyWith(fontSize: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall,
                ),
              ),
              Text('$nodeCount 点 · $edgeCount 线', style: context.texts.labelSmall),
            ],
          ),
          Slider(
            value: (chapter?.index ?? 1).toDouble().clamp(1, maxChapter.toDouble()),
            min: 1,
            max: maxChapter.toDouble() < 1 ? 1 : maxChapter.toDouble(),
            divisions: maxChapter > 1 ? maxChapter - 1 : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DeltaPanel extends StatelessWidget {
  const _DeltaPanel({
    required this.slice,
    required this.entities,
    required this.relations,
  });

  final SnapshotSlice? slice;
  final List<Entity> entities;
  final List<Relation> relations;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final entity in entities) entity.id: entity};
    final newcomers = slice?.newcomers ?? const <Entity>[];
    final started = slice?.started ?? const <Relation>[];
    final ended = slice?.ended ?? const <Relation>[];
    final died = slice?.departed ?? const <Entity>[];
    final empty = !(slice?.hasDelta ?? false);

    return Container(
      constraints: const BoxConstraints(maxHeight: 168),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          children: [
            Text('本章变化', style: context.texts.labelMedium?.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 8),
            if (empty)
              Text('这一章没有新登场、没有新关系。', style: context.texts.bodySmall)
            else ...[
              if (newcomers.isNotEmpty)
                _DeltaRow(
                  icon: Icons.person_add_alt,
                  color: Mo.jade,
                  label: '登场',
                  text: newcomers.map((e) => e.name).join('、'),
                ),
              if (started.isNotEmpty)
                _DeltaRow(
                  icon: Icons.call_made,
                  color: Theme.of(context).colorScheme.primary,
                  label: '关系开始',
                  text: started
                      .map((r) => '${byId[r.fromId]?.name ?? '?'}→${byId[r.toId]?.name ?? '?'}'
                          '（${RelationKind.parse(r.kind).label}）')
                      .join('、'),
                ),
              if (ended.isNotEmpty)
                _DeltaRow(
                  icon: Icons.call_received,
                  color: Mo.gold,
                  label: '关系结束',
                  text: ended
                      .map((r) => '${byId[r.fromId]?.name ?? '?'}↔${byId[r.toId]?.name ?? '?'}')
                      .join('、'),
                ),
              if (died.isNotEmpty)
                _DeltaRow(
                  icon: Icons.block,
                  color: Mo.vermilion,
                  label: '退场',
                  text: died.map((e) => e.name).join('、'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: context.texts.labelSmall?.copyWith(color: color, fontSize: 10.5),
            ),
          ),
          Expanded(
            child: Text(text, style: context.texts.bodySmall?.copyWith(height: 1.55)),
          ),
        ],
      ),
    );
  }
}
