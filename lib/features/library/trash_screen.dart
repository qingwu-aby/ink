import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';

/// 回收站：删掉的作品留 30 天，误删能捞回来；彻底删除才写墓碑、才跨设备消失。
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = ref.watch(trashProvider).value ?? const <Project>[];

    return Scaffold(
      appBar: AppBar(title: const Text('回收站')),
      body: trash.isEmpty
          ? const EmptyState(
              icon: Icons.delete_outline,
              title: '回收站是空的',
              description: '删掉的作品会先放进来，留 30 天。超过 30 天才会真正从本机消失。',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.sunken,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    '这里的作品还完整存在本机，恢复即可继续写。30 天后自动清理；'
                    '彻底删除后会留下墓碑，别的设备同步时也会跟着删。',
                    style: context.texts.bodySmall?.copyWith(height: 1.7),
                  ),
                ),
                const SizedBox(height: 14),
                for (final project in trash)
                  _TrashTile(project: project),
              ],
            ),
    );
  }
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedAt = project.deletedAt;
    final days = deletedAt == null ? 0 : DateTime.now().difference(deletedAt).inDays;
    final left = (30 - days).clamp(0, 30);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.title, style: context.texts.titleMedium),
            const SizedBox(height: 3),
            Text(
              deletedAt == null ? '已删除' : '删除于 $days 天前 · 还有 $left 天清理',
              style: context.texts.labelSmall,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(databaseProvider).restoreProject(project.id);
                    if (context.mounted) {
                      // 先清掉可能还挂着的「已移到回收站」，免得自相矛盾
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(content: Text('已恢复《${project.title}》')),
                        );
                    }
                  },
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('恢复'),
                ),
                TextButton.icon(
                  onPressed: () => _purge(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined, size: 16),
                  label: const Text('彻底删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purge(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('彻底删除《${project.title}》？'),
        content: const Text('本机数据会被抹掉，并留下一条删除记录，别的设备同步时也会删掉它。不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(databaseProvider);
    final deviceId = await db.getSetting('sync.deviceId') ?? '';
    await db.purgeProject(project.id, deviceId: deviceId);
  }
}
