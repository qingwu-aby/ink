import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';

class EntitiesScreen extends ConsumerStatefulWidget {
  const EntitiesScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<EntitiesScreen> createState() => _EntitiesScreenState();
}

class _EntitiesScreenState extends ConsumerState<EntitiesScreen> {
  String _query = '';
  String? _kind;

  @override
  Widget build(BuildContext context) {
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final relations = ref.watch(relationsProvider(widget.projectId)).value ?? const <Relation>[];

    final degree = <int, int>{};
    for (final r in relations) {
      degree[r.fromId] = (degree[r.fromId] ?? 0) + 1;
      degree[r.toId] = (degree[r.toId] ?? 0) + 1;
    }

    final counts = <String, int>{};
    for (final e in entities) {
      counts[e.kind] = (counts[e.kind] ?? 0) + 1;
    }

    final query = _query.trim();
    final filtered = entities.where((e) {
      if (_kind != null && e.kind != _kind) return false;
      if (query.isEmpty) return true;
      return e.name.contains(query) ||
          e.aliases.contains(query) ||
          e.summary.contains(query) ||
          e.tags.contains(query);
    }).toList();

    final grouped = <EntityKind, List<Entity>>{};
    for (final entity in filtered) {
      grouped.putIfAbsent(EntityKind.parse(entity.kind), () => []).add(entity);
    }
    final orderedKinds = EntityKind.values.where((k) => grouped.containsKey(k)).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: '搜名字、别称、简介',
                prefixIcon: const Icon(Icons.search, size: 19),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                fillColor: context.sunken,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.border),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChipLabel(
                  label: '全部 ${entities.length}',
                  selected: _kind == null,
                  onTap: () => setState(() => _kind = null),
                ),
                for (final kind in EntityKind.values.where((k) => (counts[k.key] ?? 0) > 0))
                  _FilterChipLabel(
                    label: '${kind.label} ${counts[kind.key]}',
                    selected: _kind == kind.key,
                    color: kind.color(Theme.of(context).brightness),
                    onTap: () => setState(() => _kind = _kind == kind.key ? null : kind.key),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.person_search_outlined,
                    title: entities.isEmpty ? '还没有实体' : '没有匹配的结果',
                    description: entities.isEmpty
                        ? '人物、地点、势力、物品……先建几个，图谱才有东西可连。'
                        : '换个关键词，或者清掉筛选。',
                    action: entities.isEmpty
                        ? FilledButton.icon(
                            onPressed: () => _openEditor(context, 0),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('新建实体'),
                          )
                        : null,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      for (final kind in orderedKinds) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                          child: Row(
                            children: [
                              Icon(kind.icon, size: 13, color: kind.color(Theme.of(context).brightness)),
                              const SizedBox(width: 6),
                              Text(
                                kind.label,
                                style: context.texts.labelMedium?.copyWith(letterSpacing: 1.2),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Divider(color: context.border)),
                            ],
                          ),
                        ),
                        for (final entity in grouped[kind]!)
                          _EntityRow(
                            entity: entity,
                            relationCount: degree[entity.id] ?? 0,
                            onTap: () => _openEditor(context, entity.id),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: filtered.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _openEditor(context, 0),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _openEditor(BuildContext context, int entityId) {
    context.push('/p/${widget.projectId}/entity/$entityId');
  }
}

class _FilterChipLabel extends StatelessWidget {
  const _FilterChipLabel({
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? base.withValues(alpha: 0.14) : context.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? base.withValues(alpha: 0.45) : context.border),
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

class _EntityRow extends StatelessWidget {
  const _EntityRow({required this.entity, required this.relationCount, required this.onTap});

  final Entity entity;
  final int relationCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = EntityKind.parse(entity.kind);
    final aliases = entity.aliases;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              KindAvatar(kind: kind, name: entity.name, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entity.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.titleMedium,
                          ),
                        ),
                        if (entity.status == 'dead') ...[
                          const SizedBox(width: 6),
                          const TagPill(label: '已故', color: Mo.vermilion),
                        ],
                        if (aliases.length > 3) ...[
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    if (entity.summary.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entity.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$relationCount', style: context.texts.labelLarge),
                  Text('关系', style: context.texts.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
