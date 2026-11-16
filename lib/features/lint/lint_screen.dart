import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../domain/lint/lint_engine.dart';
import '../../providers.dart';

class LintScreen extends ConsumerStatefulWidget {
  const LintScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<LintScreen> createState() => _LintScreenState();
}

class _LintScreenState extends ConsumerState<LintScreen> {
  LintLevel? _filter;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(lintProvider(widget.projectId));
    final chapters = ref.watch(chaptersProvider(widget.projectId)).value ?? const [];

    return report.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (error, _) => Center(child: Text('$error')),
      data: (data) {
        final findings = _filter == null
            ? data.findings
            : data.findings.where((f) => f.level == _filter).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(lintProvider(widget.projectId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  children: [
                    ScoreRing(score: data.score, size: 88),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.findings.isEmpty ? '这一版很干净' : _verdict(data),
                            style: context.texts.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(_advice(data), style: context.texts.bodySmall?.copyWith(height: 1.6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _LevelChip(
                    label: '全部 ${data.findings.length}',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final level in LintLevel.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _LevelChip(
                        label: '${level.label} ${data.countOf(level)}',
                        selected: _filter == level,
                        color: _colorOf(level, context),
                        onTap: () => setState(() => _filter = _filter == level ? null : level),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (findings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      _filter == null ? '没有发现矛盾。' : '这一档没有条目。',
                      style: context.texts.bodyMedium,
                    ),
                  ),
                )
              else
                for (final finding in findings)
                  _FindingTile(
                    finding: finding,
                    onTap: finding.chapterIndex == null
                        ? null
                        : () {
                            for (final chapter in chapters) {
                              if (chapter.index == finding.chapterIndex) {
                                context.push('/p/${widget.projectId}/chapter/${chapter.id}');
                                return;
                              }
                            }
                          },
                  ),
            ],
          ),
        );
      },
    );
  }

  String _verdict(LintReport report) {
    if (report.countOf(LintLevel.issue) > 0) return '有硬伤要先修';
    if (report.countOf(LintLevel.warning) > 0) return '有几处对不上';
    return '只有一些小提示';
  }

  String _advice(LintReport report) {
    if (report.findings.isEmpty) return '规则层面没有矛盾。剩下的是审美问题，那是你自己的事。';
    if (report.countOf(LintLevel.issue) > 0) {
      return '错误是会真的让读者出戏的那一类：死人出场、关系区间颠倒、称呼打架。';
    }
    return '警告多半是时间线提前或伏笔拖太久，回头看一眼就能改掉，不改也行。';
  }

  Color _colorOf(LintLevel level, BuildContext context) => switch (level) {
        LintLevel.issue => Mo.vermilion,
        LintLevel.warning => Mo.gold,
        LintLevel.hint => Theme.of(context).colorScheme.secondary,
      };
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
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
    return GestureDetector(
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
    );
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({required this.finding, this.onTap});

  final LintFinding finding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (finding.level) {
      LintLevel.issue => Mo.vermilion,
      LintLevel.warning => Mo.gold,
      LintLevel.hint => Theme.of(context).colorScheme.secondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: context.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 34,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(finding.title, style: context.texts.titleMedium)),
                        if (finding.chapterIndex != null) ...[
                          const SizedBox(width: 8),
                          Text('第 ${finding.chapterIndex} 章', style: context.texts.labelSmall),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(finding.detail, style: context.texts.bodySmall?.copyWith(height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                finding.rule,
                style: context.texts.labelSmall?.copyWith(color: color, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
