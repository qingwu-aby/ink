import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/search/paragraph_clue.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';
import '../entities/entity_sheet.dart';

/// 正文检索：按情节找段落，也可以只看某个角色出现过的所有段落。
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.projectId, this.entityId});

  final int projectId;

  /// 从实体档案点进来时只看这个人
  final int? entityId;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<ParagraphHit> _hits = const [];
  Map<int, ParagraphClue> _clues = const {};
  List<Entity> _entityHits = const [];
  int? _entityFilter;
  String _effectiveQuery = '';
  bool _searching = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _entityFilter = widget.entityId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), _run);
  }

  Future<void> _run() async {
    final query = _controller.text.trim();
    final entityFilter = _entityFilter;
    if (query.isEmpty && entityFilter == null) {
      setState(() {
        _hits = const [];
        _entityHits = const [];
        _effectiveQuery = '';
      });
      return;
    }

    final token = ++_seq;
    setState(() => _searching = true);
    final db = ref.read(databaseProvider);
    final hits = await db.searchParagraphs(widget.projectId, query, entityId: entityFilter);
    final entities = query.isEmpty ? const <Entity>[] : await db.searchEntities(widget.projectId, query);

    // 线索要按段算，一次算完；不要在每帧 build 里重算
    Map<int, ParagraphClue> clues = const {};
    if (hits.isNotEmpty) {
      final mentions = await db.allMentions(widget.projectId);
      final relations = await db.relationsOf(widget.projectId);
      final byId = {for (final entity in await db.entitiesOf(widget.projectId)) entity.id: entity};
      clues = buildParagraphClues(
        hits: hits,
        mentions: mentions,
        relations: relations,
        entityById: byId,
      );
    }

    if (!mounted || token != _seq) return;
    setState(() {
      _hits = hits;
      _clues = clues;
      _entityHits = entities;
      _effectiveQuery = query;
      _searching = false;
    });
  }

  void _filterBy(Entity entity) {
    setState(() => _entityFilter = entity.id);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(widget.projectId)).value;
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final filtered = _entityFilter == null
        ? null
        : entities.where((e) => e.id == _entityFilter).toList();
    final grouped = <int, List<ParagraphHit>>{};
    for (final hit in _hits) {
      grouped.putIfAbsent(hit.chapterId, () => []).add(hit);
    }

    return Scaffold(
      appBar: AppBar(title: Text(project == null ? '检索' : '在《${project.title}》里找')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: TextField(
              controller: _controller,
              autofocus: widget.entityId == null,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜正文里的情节、对话、地名…',
                prefixIcon: const Icon(Icons.search, size: 19),
                isDense: true,
                fillColor: context.sunken,
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 17),
                        onPressed: () {
                          _controller.clear();
                          _run();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.border),
                ),
              ),
            ),
          ),
          if (filtered != null && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  TagPill(
                    label: '只看 ${filtered.first.name}',
                    color: EntityKind.parse(filtered.first.kind).color(Theme.of(context).brightness),
                    icon: Icons.filter_alt_outlined,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _entityFilter = null);
                      _run();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('取消筛选'),
                  ),
                ],
              ),
            ),
          if (_entityHits.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _entityHits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entity = _entityHits[index];
                  final kind = EntityKind.parse(entity.kind);
                  final color = kind.color(Theme.of(context).brightness);
                  return GestureDetector(
                    onTap: () => _filterBy(entity),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: color.withValues(alpha: 0.30)),
                      ),
                      child: Row(
                        children: [
                          KindAvatar(kind: kind, name: entity.name, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            entity.name,
                            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Text('实体', style: context.texts.labelSmall?.copyWith(fontSize: 9.5)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 4),
          Expanded(child: _buildResults(
            context,
            grouped,
            filtered,
            {for (final entity in entities) entity.id: entity},
          )),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    Map<int, List<ParagraphHit>> grouped,
    List<Entity>? filtered,
    Map<int, Entity> entityById,
  ) {
    if (_effectiveQuery.isEmpty && filtered == null) {
      return EmptyState(
        icon: Icons.manage_search,
        title: '找找看',
        description: '搜一个人名、一句台词、一个地名，\n也可以把结果限定在他出现过的段落里。',
      );
    }
    if (_searching && _hits.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: filtered == null ? '没有找到' : '${filtered.first.name} 还没在正文里出现',
        description: filtered == null ? '换个词试试。检索只看正文，不含设定档。' : '可能是还没写到，或者用了别的称呼。',
      );
    }

    final chapters = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapterId = chapters[index];
        final hits = grouped[chapterId]!;
        final first = hits.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '第 ${first.chapterIndex} 章',
                  style: context.texts.labelMedium?.copyWith(fontSize: 10.5, letterSpacing: 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    first.chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall,
                  ),
                ),
                Text('${hits.length} 段', style: context.texts.labelSmall?.copyWith(fontSize: 10)),
              ],
            ),
            const SizedBox(height: 6),
            for (final hit in hits)
              _HitTile(
                hit: hit,
                projectId: widget.projectId,
                clue: _clues[hit.paragraphId] ?? ParagraphClue.empty,
                entityById: entityById,
                keyword: _effectiveQuery,
                onTap: () => context.push(
                  '/p/${widget.projectId}/chapter/${hit.chapterId}?at=${hit.start}',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.hit,
    required this.projectId,
    required this.clue,
    required this.entityById,
    required this.keyword,
    required this.onTap,
  });

  final ParagraphHit hit;
  final int projectId;
  final ParagraphClue clue;
  final Map<int, Entity> entityById;
  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final people = _peopleOf(clue, entityById);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: Text.rich(
                _excerpt(context, hit.content, keyword),
                style: context.texts.bodyMedium?.copyWith(
                  height: 1.7,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (!clue.isEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final person in people.take(4))
                    GestureDetector(
                      onTap: () => showEntityPeek(
                        context,
                        projectId: projectId,
                        entityId: person.id,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(5, 3, 8, 3),
                        decoration: BoxDecoration(
                          color: EntityKind.parse(person.kind)
                              .color(Theme.of(context).brightness)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            KindAvatar(
                              kind: EntityKind.parse(person.kind),
                              name: person.name,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              person.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: EntityKind.parse(person.kind)
                                    .color(Theme.of(context).brightness),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (people.length > 4)
                    Text('+${people.length - 4}', style: context.texts.labelSmall),
                  TextButton.icon(
                    onPressed: () => showClueSheet(
                      context,
                      projectId: projectId,
                      hit: hit,
                      clue: clue,
                      entityById: entityById,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.account_tree_outlined, size: 13),
                    label: Text(
                      clue.links.isEmpty ? '线索' : '线索 ${clue.links.length}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 只展示命中点前后一小段，避免一条结果占满屏幕。
  TextSpan _excerpt(BuildContext context, String text, String keyword) {
    final highlight = Theme.of(context).colorScheme.primary;
    final scheme = TextStyle(
      color: highlight,
      fontWeight: FontWeight.w600,
      backgroundColor: highlight.withValues(alpha: 0.12),
    );

    if (keyword.isEmpty) {
      return TextSpan(text: text.length > 120 ? '${text.substring(0, 120)}…' : text);
    }

    final lower = text.toLowerCase();
    final target = keyword.toLowerCase();
    final index = lower.indexOf(target);
    if (index < 0) {
      return TextSpan(text: text.length > 120 ? '${text.substring(0, 120)}…' : text);
    }

    const window = 48;
    final start = (index - window).clamp(0, text.length);
    final end = (index + keyword.length + window).clamp(0, text.length);
    final visible = text.substring(start, end);
    final local = index - start;
    final matchEnd = local + keyword.length;

    return TextSpan(children: [
      if (start > 0) const TextSpan(text: '…'),
      TextSpan(text: visible.substring(0, local)),
      TextSpan(text: visible.substring(local, matchEnd), style: scheme),
      TextSpan(text: visible.substring(matchEnd)),
      if (end < text.length) const TextSpan(text: '…'),
    ]);
  }
}


/// 把线索里的实体 id 换成人。
List<Entity> _peopleOf(ParagraphClue clue, Map<int, Entity> entityById) => [
      for (final id in clue.entityIds)
        if (entityById[id] != null) entityById[id]!,
    ];

/// 一段正文的线索：谁在场、当时什么关系。点进去就能顺着人找到关系。
Future<void> showClueSheet(
  BuildContext context, {
  required int projectId,
  required ParagraphHit hit,
  required ParagraphClue clue,
  required Map<int, Entity> entityById,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              Text('第 ${hit.chapterIndex} 章的线索', style: context.texts.headlineSmall),
              const SizedBox(width: 10),
              TagPill(label: '${clue.entityIds.length} 人 · ${clue.links.length} 条关系'),
            ],
          ),
          const SizedBox(height: 4),
          Text(hit.chapterTitle, style: context.texts.bodySmall),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.sunken,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Text(
              hit.content,
              style: context.texts.bodyMedium?.copyWith(
                height: 1.8,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (clue.entityIds.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('这一段里的人', style: context.texts.titleMedium),
            const SizedBox(height: 8),
            for (final person in _peopleOf(clue, entityById))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => showEntityPeek(context, projectId: projectId, entityId: person.id),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: Row(
                    children: [
                      KindAvatar(kind: EntityKind.parse(person.kind), name: person.name, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          person.name,
                          style: context.texts.bodyLarge,
                        ),
                      ),
                      KindPill(kind: EntityKind.parse(person.kind), dense: true),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ),
          ],
          if (clue.links.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('这一刻生效的关系', style: context.texts.titleMedium),
            const SizedBox(height: 8),
            for (final relation in clue.links)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      RelationKind.parse(relation.kind).symmetric ? Icons.swap_horiz : Icons.east,
                      size: 13,
                      color: context.muted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entityById[relation.fromId]?.name ?? '?'} · '
                        '${RelationKind.parse(relation.kind).label} · '
                        '${entityById[relation.toId]?.name ?? '?'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      relation.validTo == null
                          ? '第 ${relation.validFrom} 章起'
                          : '第 ${relation.validFrom}–${relation.validTo} 章',
                      style: context.texts.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
