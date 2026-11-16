import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/utils/text_utils.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';

class ChaptersScreen extends ConsumerWidget {
  const ChaptersScreen({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chaptersProvider(projectId)).value;
    final stats = ref.watch(statsProvider(projectId)).value ?? ProjectStats.empty;

    if (chapters == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Scaffold(
      body: chapters.isEmpty
          ? EmptyState(
              icon: Icons.edit_note_outlined,
              title: '还没有章节',
              description: '新写一章，或者把已经写好的 txt / md 稿子导进来。',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: () => _newChapter(context, ref),
                    child: const Text('新建章节'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => context.push('/p/$projectId/import'),
                    child: const Text('导入旧稿'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: chapters.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text('${chapters.length} 章', style: context.texts.titleMedium),
                        const SizedBox(width: 8),
                        Text('· ${formatCount(stats.wordCount)} 字', style: context.texts.bodySmall),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => context.push('/p/$projectId/import'),
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: const Text('导入'),
                        ),
                      ],
                    ),
                  );
                }
                final chapter = chapters[index - 1];
                return _ChapterTile(
                  chapter: chapter,
                  onTap: () => context.push('/p/$projectId/chapter/${chapter.id}'),
                );
              },
            ),
      floatingActionButton: chapters.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _newChapter(context, ref),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.add),
            ),
    );
  }

  Future<void> _newChapter(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final index = await db.nextChapterIndex(projectId);
    final id = await db.createChapter(projectId: projectId, title: '第 $index 章');
    if (context.mounted) context.push('/p/$projectId/chapter/$id');
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.chapter, required this.onTap});

  final Chapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = ChapterStatus.parse(chapter.status);
    final statusColor = switch (status) {
      ChapterStatus.draft => context.muted,
      ChapterStatus.revising => Mo.gold,
      ChapterStatus.done => Mo.jade,
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
              SizedBox(
                width: 26,
                child: Text(
                  '${chapter.index}',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: context.muted,
                    fontFamily: Serif.family,
                    fontFamilyFallback: Serif.fallback,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chapter.title.isEmpty ? '第 ${chapter.index} 章' : chapter.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${chapter.wordCount}',
                          style: context.texts.labelSmall,
                        ),
                      ],
                    ),
                    if (chapter.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        excerpt(chapter.body, max: 46),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
