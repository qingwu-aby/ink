import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../domain/suggest/suggestion_engine.dart';
import '../../providers.dart';
import '../entities/entity_sheet.dart';

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key, required this.projectId});

  final int projectId;

  static IconData iconOf(SuggestionKind kind) => switch (kind) {
        SuggestionKind.unshownRelation => Icons.link_off,
        SuggestionKind.missingCharacter => Icons.hourglass_empty,
        SuggestionKind.unusedEntity => Icons.inventory_2_outlined,
        SuggestionKind.unlinkedPair => Icons.add_link,
      };

  static Color colorOf(SuggestionKind kind, BuildContext context) => switch (kind) {
        SuggestionKind.unshownRelation => Theme.of(context).colorScheme.primary,
        SuggestionKind.missingCharacter => Mo.gold,
        SuggestionKind.unusedEntity => context.muted,
        SuggestionKind.unlinkedPair => Mo.jade,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(suggestionsProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('接下来写什么')),
      body: suggestions.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, _) => Center(child: Text('$error')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: '没有空档',
              description: '关系都写到了，人也都在场，\n档案里的素材都被用上了。',
            );
          }
          final grouped = <SuggestionKind, List<Suggestion>>{};
          for (final item in list) {
            grouped.putIfAbsent(item.kind, () => []).add(item);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.sunken,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text(
                  '这里只找「还没写的」，不找错别字和矛盾——那些在校对里。'
                  '建议都是从你已有的实体、关系和正文里算出来的，没有猜。',
                  style: context.texts.bodySmall?.copyWith(height: 1.7),
                ),
              ),
              for (final entry in grouped.entries) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(iconOf(entry.key), size: 14, color: colorOf(entry.key, context)),
                    const SizedBox(width: 6),
                    Text(entry.key.label, style: context.texts.labelMedium?.copyWith(letterSpacing: 1.1)),
                    const SizedBox(width: 8),
                    Expanded(child: Divider(color: context.border)),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in entry.value)
                  _SuggestionCard(
                    suggestion: item,
                    color: colorOf(entry.key, context),
                    icon: iconOf(entry.key),
                    onTap: item.entityIds.isEmpty
                        ? null
                        : () => showEntityPeek(
                              context,
                              projectId: projectId,
                              entityId: item.entityIds.first,
                            ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final Suggestion suggestion;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: context.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion.title, style: context.texts.titleMedium),
                    const SizedBox(height: 3),
                    Text(suggestion.detail, style: context.texts.bodySmall?.copyWith(height: 1.6)),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: context.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
