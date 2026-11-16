import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/lint/lint_engine.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';
import 'project_shell.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId)).value;
    final stats = ref.watch(statsProvider(projectId)).value ?? ProjectStats.empty;
    final lint = ref.watch(lintProvider(projectId)).value;
    final chapters = ref.watch(chaptersProvider(projectId)).value ?? const [];
    final foreshadows = ref.watch(foreshadowsProvider(projectId)).value ?? const [];

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final sortedChapters = [...chapters]..sort((a, b) => b.index.compareTo(a.index));
    final recent = sortedChapters.take(3).toList();
    final openHooks = foreshadows.where((f) => f.resolvedChapter == null).take(4).toList();
    final progress = project != null && project.wordGoal > 0 ? stats.wordCount / project.wordGoal : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: [
        _Hero(
          title: project?.title ?? '',
          genre: project?.genre ?? '',
          synopsis: project?.synopsis ?? '',
          wordCount: stats.wordCount,
          goal: project?.wordGoal ?? 0,
          progress: progress,
          onGraph: () => ref.read(projectTabProvider(projectId)).value = kTabGraph,
          onContinue: () {
            if (sortedChapters.isNotEmpty) {
              context.push('/p/$projectId/chapter/${sortedChapters.first.id}');
            } else {
              ref.read(projectTabProvider(projectId)).value = kTabChapters;
            }
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SectionCard(
                child: Row(
                  children: [
                    ScoreRing(score: lint?.score ?? 100, size: 78),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lint == null
                                ? '正在扫描…'
                                : lint.findings.isEmpty
                                    ? '没有发现硬伤'
                                    : '${lint.countOf(LintLevel.issue)} 处硬伤待修',
                            style: context.texts.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lint == null
                                ? ''
                                : '警告 ${lint.countOf(LintLevel.warning)} · 提示 ${lint.countOf(LintLevel.hint)}',
                            style: context.texts.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                ref.read(projectTabProvider(projectId)).value = kTabLint,
                            child: const Text('查看校对报告 →'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (wide) ...[
              const SizedBox(width: 14),
              Expanded(flex: 2, child: _StatsCard(stats: stats)),
            ],
          ],
        ),
        if (!wide) ...[
          const SizedBox(height: 14),
          _StatsCard(stats: stats),
        ],
        const SizedBox(height: 14),
        SectionCard(
          title: '实体构成',
          subtitle: '图谱里现在有多少东西',
          child: _KindBars(counts: stats.kindCounts),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: '时间与快照',
          subtitle: '同一段故事，两种看法',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.relationCount == 0
                    ? '写起正文、连上关系之后，这里会长出两张图。'
                    : '时间带看关系从哪章活到哪章；章节快照看某一章那一刻，世界是什么样。',
                style: context.texts.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/p/$projectId/timeline'),
                      icon: const Icon(Icons.timeline, size: 16),
                      label: const Text('关系时间带'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/p/$projectId/snapshot'),
                      icon: const Icon(Icons.layers_outlined, size: 16),
                      label: const Text('章节快照'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: '最近写到的',
          action: TextButton(
            onPressed: () => ref.read(projectTabProvider(projectId)).value = kTabChapters,
            child: const Text('全部'),
          ),
          child: recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('还没有章节。', style: context.texts.bodySmall),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0) Divider(color: context.border, height: 20),
                      InkWell(
                        onTap: () => context.push('/p/$projectId/chapter/${recent[i].id}'),
                        child: Row(
                          children: [
                            Text(
                              '${recent[i].index}',
                              style: context.texts.labelMedium?.copyWith(
                                fontFamily: Serif.family,
                                fontFamilyFallback: Serif.fallback,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                recent[i].title.isEmpty ? '第 ${recent[i].index} 章' : recent[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.bodyLarge,
                              ),
                            ),
                            Text('${formatCount(recent[i].wordCount)} 字', style: context.texts.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: '还没收的伏笔',
          subtitle: openHooks.isEmpty ? null : '写到这里的人最该看这张单子',
          child: openHooks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('暂无。', style: context.texts.bodySmall),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final hook in openHooks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Mo.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hook.hook,
                                style: context.texts.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('第 ${hook.plantedChapter} 章', style: context.texts.labelSmall),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.title,
    required this.genre,
    required this.synopsis,
    required this.wordCount,
    required this.goal,
    required this.progress,
    required this.onContinue,
    required this.onGraph,
  });

  final String title;
  final String genre;
  final String synopsis;
  final int wordCount;
  final int goal;
  final double progress;
  final VoidCallback onContinue;
  final VoidCallback onGraph;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: context.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.surface,
            Color.alphaBlend(
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              context.surface,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (genre.isNotEmpty) TagPill(label: genre, icon: Icons.local_offer_outlined),
              const Spacer(),
              Text(
                goal > 0 ? '${formatCount(wordCount)} / ${formatCount(goal)} 字' : '${formatCount(wordCount)} 字',
                style: context.texts.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title.isEmpty ? '未命名' : title, style: context.texts.displaySmall),
          if (synopsis.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              synopsis,
              style: context.texts.bodyMedium?.copyWith(height: 1.7),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          ProgressLine(value: progress, height: 5),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('继续写'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onGraph,
                icon: const Icon(Icons.hub_outlined, size: 17),
                label: const Text('图谱'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final ProjectStats stats;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '规模',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: StatBlock(value: '${stats.chapterCount}', label: '章节')),
              Expanded(child: StatBlock(value: '${stats.entityCount}', label: '实体')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: StatBlock(value: '${stats.relationCount}', label: '关系')),
              Expanded(child: StatBlock(value: '${stats.openForeshadows}', label: '未收伏笔')),
            ],
          ),
        ],
      ),
    );
  }
}

class _KindBars extends StatelessWidget {
  const _KindBars({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return Text('还没有建任何实体。', style: context.texts.bodySmall);
    }
    final present = EntityKind.values.where((k) => (counts[k.key] ?? 0) > 0).toList();
    present.sort((a, b) => (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0));

    return Column(
      children: [
        for (final kind in present) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(kind.label, style: context.texts.bodySmall),
                ),
                Expanded(
                  child: ProgressLine(
                    value: (counts[kind.key] ?? 0) / total,
                    color: kind.color(Theme.of(context).brightness),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${counts[kind.key]}',
                    textAlign: TextAlign.right,
                    style: context.texts.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
