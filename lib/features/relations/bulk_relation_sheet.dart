import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';

/// 多选之后的批量建边：选一个中心，把其余的都连过去。
/// 长篇里最常见的场景就是这个——"这一批人都是某势力的人"。
Future<bool?> showBulkRelationSheet(
  BuildContext context, {
  required int projectId,
  required List<int> entityIds,
  required List<Entity> entities,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _BulkRelationSheet(
      projectId: projectId,
      entityIds: entityIds,
      entities: entities,
    ),
  );
}

class _BulkRelationSheet extends ConsumerStatefulWidget {
  const _BulkRelationSheet({
    required this.projectId,
    required this.entityIds,
    required this.entities,
  });

  final int projectId;
  final List<int> entityIds;
  final List<Entity> entities;

  @override
  ConsumerState<_BulkRelationSheet> createState() => _BulkRelationSheetState();
}

class _BulkRelationSheetState extends ConsumerState<_BulkRelationSheet> {
  late int _center = widget.entityIds.first;
  String _kind = 'ally';
  bool _centerFirst = true;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final entity in widget.entities) entity.id: entity};
    final others = widget.entityIds.where((id) => id != _center).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              children: [
                Text('批量建边', style: context.texts.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '选中了 ${widget.entityIds.length} 个实体。挑一个中心，其余的都连到它。',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 18),
                Text('中心实体', style: context.texts.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in widget.entityIds)
                      _Chip(
                        label: byId[id]?.name ?? '?',
                        selected: _center == id,
                        onTap: () => setState(() => _center = id),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('关系', style: context.texts.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in RelationKind.all)
                      _Chip(
                        label: kind.label,
                        selected: _kind == kind.key,
                        onTap: () => setState(() => _kind = kind.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('方向', style: context.texts.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Chip(
                      label: '${byId[_center]?.name ?? '中心'} → 其余',
                      selected: _centerFirst,
                      onTap: () => setState(() => _centerFirst = true),
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      label: '其余 → ${byId[_center]?.name ?? '中心'}',
                      selected: !_centerFirst,
                      onTap: () => setState(() => _centerFirst = false),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.sunken,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('将建立 ${others.length} 条关系', style: context.texts.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        others
                            .map((id) => _centerFirst
                                ? '${byId[_center]?.name} → ${byId[id]?.name}'
                                : '${byId[id]?.name} → ${byId[_center]?.name}')
                            .join('\n'),
                        style: context.texts.bodySmall?.copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(top: BorderSide(color: context.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving || others.isEmpty ? null : _commit,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('建立 ${others.length} 条'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _commit() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    for (final id in widget.entityIds) {
      if (id == _center) continue;
      await db.upsertRelation(
        projectId: widget.projectId,
        fromId: _centerFirst ? _center : id,
        toId: _centerFirst ? id : _center,
        kind: _kind,
        strength: 3,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? base.withValues(alpha: 0.13) : context.sunken,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? base.withValues(alpha: 0.42) : context.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: selected ? base : context.soft,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
