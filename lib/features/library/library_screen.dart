import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(onSettings: () => context.push('/settings'))),
            projects.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.error_outline, title: '书架打不开', description: '$error'),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: '书架还空着',
                      description: '建第一本书，然后从「人物」开始铺图谱。\n写到第三章时，它会开始还你利息。',
                      action: FilledButton.icon(
                        onPressed: () => _newProject(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('新建作品'),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => _ProjectCard(project: list[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: projects.value?.isNotEmpty ?? false
          ? FloatingActionButton.extended(
              onPressed: () => _newProject(context, ref),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('新建作品'),
            )
          : null,
    );
  }

  Future<void> _newProject(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<_NewProjectDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewProjectSheet(),
    );
    if (draft == null) return;
    final id = await ref.read(databaseProvider).createProject(
          title: draft.title,
          genre: draft.genre,
          wordGoal: draft.goal,
        );
    if (context.mounted) context.go('/p/$id');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '墨',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontFamily: Serif.family,
                          fontFamilyFallback: Serif.fallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('墨谱', style: context.texts.headlineMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('正文与图谱，互为注脚', style: context.texts.bodySmall),
                    const SizedBox(width: 10),
                    const Flexible(child: _SyncBadge()),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.tune, size: 21),
            tooltip: '设置',
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider(project.id)).value ?? ProjectStats.empty;
    final progress = project.wordGoal > 0 ? stats.wordCount / project.wordGoal : 0.0;

    return InkWell(
      onTap: () => context.go('/p/${project.id}'),
      onLongPress: () => _showActions(context, ref),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: context.border),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(project.title, style: context.texts.headlineSmall, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (project.genre.isNotEmpty) TagPill(label: project.genre),
              ],
            ),
            if (project.synopsis.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                project.synopsis,
                style: context.texts.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(value: formatCount(stats.wordCount), label: '字数'),
                const SizedBox(width: 18),
                _MiniStat(value: '${stats.entityCount}', label: '实体'),
                const SizedBox(width: 18),
                _MiniStat(value: '${stats.relationCount}', label: '关系'),
                const Spacer(),
                _KindCluster(counts: stats.kindCounts),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ProgressLine(value: progress)),
                const SizedBox(width: 10),
                Text(
                  project.wordGoal > 0
                      ? '${(progress * 100).clamp(0, 100).toStringAsFixed(1)}%'
                      : formatCount(stats.wordCount),
                  style: context.texts.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on _ProjectCard {
  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(project.title, style: context.texts.titleMedium),
              subtitle: Text('长按作品可以在这里管理', style: context.texts.labelSmall),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text(
                '移到回收站',
                style: context.texts.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              subtitle: Text('保留 30 天，期间随时可以恢复', style: context.texts.labelSmall),
              onTap: () => Navigator.of(context).pop('trash'),
            ),
          ],
        ),
      ),
    );
    if (action != 'trash' || !context.mounted) return;

    await ref.read(databaseProvider).deleteProject(project.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('《${project.title}》已移到回收站'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => ref.read(databaseProvider).restoreProject(project.id),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: Serif.family,
            fontFamilyFallback: Serif.fallback,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: context.texts.labelSmall),
      ],
    );
  }
}

class _KindCluster extends StatelessWidget {
  const _KindCluster({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final present = EntityKind.values
        .where((k) => (counts[k.key] ?? 0) > 0)
        .take(4)
        .toList();
    if (present.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 22.0 + 13 * (present.length - 1),
      height: 22,
      child: Stack(
        children: [
          for (var i = 0; i < present.length; i++)
            Positioned(
              left: i * 13.0,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: present[i].tint(Theme.of(context).brightness),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.surface, width: 1.6),
                ),
                child: Icon(
                  present[i].icon,
                  size: 10,
                  color: present[i].color(Theme.of(context).brightness),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewProjectDraft {
  const _NewProjectDraft(this.title, this.genre, this.goal);
  final String title;
  final String genre;
  final int goal;
}

class _NewProjectSheet extends StatefulWidget {
  const _NewProjectSheet();

  @override
  State<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<_NewProjectSheet> {
  final _title = TextEditingController();
  final _genre = TextEditingController();
  final _goal = TextEditingController(text: '100000');

  @override
  void dispose() {
    _title.dispose();
    _genre.dispose();
    _goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('新建作品', style: context.texts.headlineSmall),
          const SizedBox(height: 4),
          Text('先给书起个名字，人物和关系随时可以补。', style: context.texts.bodySmall),
          const SizedBox(height: 18),
          TextField(
            controller: _title,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: '书名', hintText: '例如：听雨录'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _genre,
                  decoration: const InputDecoration(labelText: '类型', hintText: '武侠 / 悬疑'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _goal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '目标字数'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final title = _title.text.trim();
                if (title.isEmpty) return;
                Navigator.of(context).pop(_NewProjectDraft(
                  title,
                  _genre.text.trim(),
                  int.tryParse(_goal.text.trim()) ?? 0,
                ));
              },
              child: const Text('开始'),
            ),
          ),
        ],
      ),
    );
  }
}


/// 书架上的同步状态：不点进设置也能知道上次同步是什么时候、有没有失败。
class _SyncBadge extends ConsumerWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).value ?? SyncStatus.unknown;

    final (label, color) = _describe(context, status);

    return InkWell(
      onTap: () => context.push('/settings/sync'),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall?.copyWith(color: context.muted, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _describe(BuildContext context, SyncStatus status) {
    if (!status.configured) return ('未配置同步', context.muted);
    if (status.hasError) return ('上次同步失败', Mo.vermilion);
    final last = status.lastSyncAt;
    if (last == null) return ('尚未同步', Mo.gold);
    final relative = _relative(last.toLocal());
    return ('$relative已同步', Mo.jade);
  }

  String _relative(DateTime time) {
    final gap = DateTime.now().difference(time);
    if (gap.inMinutes < 1) return '刚刚';
    if (gap.inMinutes < 60) return '${gap.inMinutes} 分钟前';
    if (gap.inHours < 24) return '${gap.inHours} 小时前';
    if (gap.inDays < 30) return '${gap.inDays} 天前';
    return '${(gap.inDays / 30).floor()} 个月前';
  }
}
