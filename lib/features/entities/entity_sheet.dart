import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';

/// 实体速览：图谱点节点、正文点名字都落到这里。
Future<void> showEntityPeek(
  BuildContext context, {
  required int projectId,
  required int entityId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EntityPeek(projectId: projectId, entityId: entityId),
  );
}

class _EntityPeek extends ConsumerWidget {
  const _EntityPeek({required this.projectId, required this.entityId});

  final int projectId;
  final int entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(entitiesProvider(projectId)).value ?? const <Entity>[];
    final relations = ref.watch(relationsProvider(projectId)).value ?? const <Relation>[];
    final mentions = ref.watch(mentionsProvider(projectId)).value ?? const <Mention>[];

    Entity? entity;
    for (final candidate in entities) {
      if (candidate.id == entityId) {
        entity = candidate;
        break;
      }
    }
    if (entity == null) {
      return const SizedBox(height: 180, child: Center(child: Text('这条记录已经不在了')));
    }

    final byId = <int, Entity>{for (final e in entities) e.id: e};
    final kind = EntityKind.parse(entity.kind);
    final related = relations
        .where((r) => r.fromId == entityId || r.toId == entityId)
        .toList()
      ..sort((a, b) => b.strength.compareTo(a.strength));
    final myMentions = mentions.where((m) => m.entityId == entityId).toList();
    final chapterCount = myMentions.map((m) => m.chapterId).toSet().length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.56,
      minChildSize: 0.32,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KindAvatar(kind: kind, name: entity!.name, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entity.name, style: context.texts.headlineSmall),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          KindPill(kind: kind),
                          if (entity.status == 'dead')
                            const TagPill(label: '已故', color: Mo.vermilion)
                          else if (entity.status == 'unknown')
                            const TagPill(label: '下落不明', color: Mo.gold),
                          TagPill(
                            label: '正文 ${myMentions.length} 次 · $chapterCount 章',
                            icon: Icons.notes_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entity.summary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(entity.summary, style: context.texts.bodyLarge?.copyWith(height: 1.72)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Text('关系', style: context.texts.titleMedium),
                const SizedBox(width: 8),
                Text('${related.length}', style: context.texts.labelMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (related.isEmpty)
              Text('还没有和任何实体连线。', style: context.texts.bodySmall)
            else
              for (final relation in related)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RelationRow(
                    relation: relation,
                    selfId: entityId,
                    other: byId[relation.fromId == entityId ? relation.toId : relation.fromId],
                  ),
                ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push('/p/$projectId/entity/$entityId');
              },
              child: const Text('打开档案'),
            ),
          ],
        );
      },
    );
  }
}

class _RelationRow extends StatelessWidget {
  const _RelationRow({required this.relation, required this.selfId, this.other});

  final Relation relation;
  final int selfId;
  final Entity? other;

  @override
  Widget build(BuildContext context) {
    final kind = RelationKind.parse(relation.kind);
    final outgoing = relation.fromId == selfId;
    final span = relation.validTo == null
        ? '第 ${relation.validFrom} 章起'
        : '第 ${relation.validFrom}–${relation.validTo} 章';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.sunken,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        children: [
          Icon(
            kind.symmetric ? Icons.swap_horiz : (outgoing ? Icons.east : Icons.west),
            size: 15,
            color: context.muted,
          ),
          const SizedBox(width: 8),
          Text(kind.label, style: context.texts.labelLarge),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              other?.name ?? '（已删除）',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          Text(span, style: context.texts.labelSmall),
        ],
      ),
    );
  }
}
