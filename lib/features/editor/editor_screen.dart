import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/utils/text_utils.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/llm/llm_client.dart';
import '../../domain/taxonomy.dart';
import '../../domain/text/entity_matcher.dart';
import '../../providers.dart';
import '../entities/entity_sheet.dart';
import 'highlight_controller.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    required this.projectId,
    required this.chapterId,
    this.initialOffset,
  });

  final int projectId;
  final int chapterId;

  /// 从检索结果点进来时，直接落到命中的段落
  final int? initialOffset;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  EntityHighlightController? _body;
  final _title = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  Chapter? _chapter;
  AppDatabase? _db;
  bool _focusMode = false;
  bool _saving = false;
  String? _peekEntityId;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final db = ref.read(databaseProvider);
    _db = db;
    final chapter = await db.getChapter(widget.chapterId);
    if (!mounted || chapter == null) return;
    final entities = await db.entitiesOf(widget.projectId);
    if (!mounted) return;

    _chapter = chapter;
    _title.text = chapter.title;
    _body = EntityHighlightController(
      matcher: EntityMatcher(entities),
      entityById: {for (final e in entities) e.id: e},
      dark: Theme.of(context).brightness == Brightness.dark,
    )
      ..text = chapter.body
      ..addListener(_onBodyChanged);
    setState(() {});

    final offset = widget.initialOffset;
    if (offset != null && offset > 0 && offset <= chapter.body.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        _body?.selection = TextSelection.collapsed(offset: offset);
      });
    }
  }

  void _onBodyChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _persist);
    setState(() {});
  }

  Future<void> _persist() async {
    final chapter = _chapter;
    final controller = _body;
    if (chapter == null || controller == null) return;
    setState(() => _saving = true);

    final db = ref.read(databaseProvider);
    final entities = await db.entitiesOf(widget.projectId);
    if (!mounted) return;
    final spans = EntityMatcher(entities).scan(controller.text);
    await db.saveChapterBody(chapter.id, controller.text);
    await db.replaceMentions(chapter.id, spans);
    await db.reindexParagraphs(
      chapterId: chapter.id,
      projectId: widget.projectId,
      body: controller.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // 退出前把没落盘的最后一次改动写掉
    final chapter = _chapter;
    final controller = _body;
    if (chapter != null && controller != null && controller.text != chapter.body) {
      _db?.saveChapterBody(chapter.id, controller.text);
    }
    _body?.dispose();
    _title.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _body;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    ref.listen<AsyncValue<List<Entity>>>(entitiesProvider(widget.projectId), (previous, next) {
      final list = next.value;
      if (list == null) return;
      controller.update(entityById: {for (final e in list) e.id: e}, dark: dark);
    });

    final mentioned = controller.spans.map((s) => s.entityId).toSet().toList();
    final mentionedEntities = entities.where((e) => mentioned.contains(e.id)).toList();
    final peek = entities.where((e) => '${e.id}' == _peekEntityId).toList();

    return Scaffold(
      appBar: AppBar(
        title: _TitleField(
          controller: _title,
          onChanged: (value) {
            if (_chapter != null) {
              ref.read(databaseProvider).updateChapterMeta(_chapter!.id, title: value);
            }
          },
        ),
        actions: [
          if (_saving)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('保存中', style: context.texts.labelSmall),
              ),
            ),
          IconButton(
            tooltip: _focusMode ? '退出专注' : '专注模式',
            onPressed: () => setState(() => _focusMode = !_focusMode),
            icon: Icon(_focusMode ? Icons.fullscreen_exit : Icons.fullscreen, size: 20),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: _onMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'snapshot', child: Text('看本章的图谱')),
              PopupMenuItem(value: 'status', child: Text('设置状态')),
              PopupMenuItem(value: 'rename', child: Text('重命名章节')),
              PopupMenuItem(value: 'ai', child: Text('AI 审校本章')),
              PopupMenuItem(value: 'delete', child: Text('删除章节')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _focusMode ? 24 : 18,
                _focusMode ? 18 : 6,
                _focusMode ? 24 : 18,
                0,
              ),
              child: TextField(
                controller: controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: _focusMode ? 18.5 : 17.5,
                  height: 1.95,
                  letterSpacing: 0.25,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: Serif.family,
                  fontFamilyFallback: Serif.fallback,
                ),
                decoration: InputDecoration(
                  hintText: '从这里开始写……',
                  hintStyle: TextStyle(color: context.muted, fontSize: 17),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  final offset = controller.selection.baseOffset;
                  if (offset < 0) return;
                  final entity = controller.entityAt(offset);
                  setState(() => _peekEntityId = entity?.id.toString());
                },
              ),
            ),
          ),
          if (peek.isNotEmpty && !_focusMode)
            _PeekBar(
              entity: peek.first,
              onOpen: () => showEntityPeek(
                context,
                projectId: widget.projectId,
                entityId: peek.first.id,
              ),
              onClose: () => setState(() => _peekEntityId = null),
            ),
          if (!_focusMode)
            _MentionBar(
              entities: mentionedEntities,
              counts: _countsByEntity(controller.spans),
              wordCount: countWords(controller.text),
              onTap: (entity) => showEntityPeek(
                context,
                projectId: widget.projectId,
                entityId: entity.id,
              ),
            ),
        ],
      ),
    );
  }

  Map<int, int> _countsByEntity(List<MentionSpan> spans) {
    final counts = <int, int>{};
    for (final span in spans) {
      counts[span.entityId] = (counts[span.entityId] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _onMenu(String value) async {
    final chapter = _chapter;
    if (chapter == null) return;
    final db = ref.read(databaseProvider);

    switch (value) {
      case 'snapshot':
        context.push('/p/${widget.projectId}/snapshot?c=${chapter.index}');
        break;
      case 'status':
        final picked = await showModalBottomSheet<ChapterStatus>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final status in ChapterStatus.values)
                  ListTile(
                    title: Text(status.label),
                    trailing: ChapterStatus.parse(chapter.status) == status
                        ? const Icon(Icons.check, size: 18)
                        : null,
                    onTap: () => Navigator.of(context).pop(status),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) {
          await db.updateChapterMeta(chapter.id, status: picked.key);
          if (mounted) setState(() => _chapter = _chapter?.copyWith(status: picked.key));
        }
        break;
      case 'rename':
        final controller = TextEditingController(text: chapter.title);
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('章节标题'),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('保存'),
              ),
            ],
          ),
        );
        if (result != null && result.isNotEmpty) {
          await db.updateChapterMeta(chapter.id, title: result);
          if (mounted) setState(() => _title.text = result);
        }
        break;
      case 'ai':
        await _runAiReview(chapter);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除这一章？'),
            content: const Text('正文和这一章的实体提及都会一起删掉。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await db.deleteChapter(chapter.id);
          if (mounted) context.pop();
        }
        break;
    }
  }

  Future<void> _runAiReview(Chapter chapter) async {
    final aiState = ref.read(aiConfigProvider).value;
    if (aiState == null || !aiState.enabled || !aiState.config.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 助手还没开启，去设置里填 API Key 和模型')),
      );
      return;
    }
    final text = _body?.text ?? chapter.body;
    if (text.trim().length < 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这一章还太短，先写点东西')),
      );
      return;
    }

    final entities = ref.read(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final bible = entities
        .map((e) => '${e.name}（${EntityKind.parse(e.kind).label}）：${e.summary}')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _BusyDialog(text: '正在比对设定档…'),
    );

    try {
      final client = LlmClient(aiState.config);
      final issues = await client.review(bible: bible, chapterText: text);
      if (!mounted) return;
      Navigator.of(context).pop();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _IssueSheet(issues: issues),
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('审校失败'),
          content: SingleChildScrollView(child: Text('$error', style: context.texts.bodySmall)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
          ],
        ),
      );
    }
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: Serif.family,
        fontFamilyFallback: Serif.fallback,
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: '章节标题',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintStyle: TextStyle(fontSize: 16, color: context.muted),
      ),
    );
  }
}

class _PeekBar extends StatelessWidget {
  const _PeekBar({required this.entity, required this.onOpen, required this.onClose});

  final Entity entity;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final kind = EntityKind.parse(entity.kind);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: kind.tint(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: kind.color(Theme.of(context).brightness).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          KindAvatar(kind: kind, name: entity.name, size: 26),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              entity.summary.isEmpty ? entity.name : '${entity.name} · ${entity.summary}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall?.copyWith(color: context.soft),
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('档案')),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MentionBar extends StatelessWidget {
  const _MentionBar({
    required this.entities,
    required this.counts,
    required this.wordCount,
    required this.onTap,
  });

  final List<Entity> entities;
  final Map<int, int> counts;
  final int wordCount;
  final ValueChanged<Entity> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: entities.isEmpty
                  ? Text('本章还没有出现任何已建档的实体', style: context.texts.labelSmall)
                  : SizedBox(
                      height: 30,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: entities.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final entity = entities[index];
                          final kind = EntityKind.parse(entity.kind);
                          final color = kind.color(Theme.of(context).brightness);
                          return GestureDetector(
                            onTap: () => onTap(entity),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: color.withValues(alpha: 0.28)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    entity.name,
                                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${counts[entity.id] ?? 0}',
                                    style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Text('$wordCount 字', style: context.texts.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _BusyDialog extends StatelessWidget {
  const _BusyDialog({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _IssueSheet extends StatelessWidget {
  const _IssueSheet({required this.issues});

  final List<AiIssue> issues;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            children: [
              Text('AI 审校', style: context.texts.headlineSmall),
              const SizedBox(width: 10),
              TagPill(label: '${issues.length} 条', color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text('AI 会犯错，这只是一份提示，改不改由你。', style: context.texts.bodySmall),
          const SizedBox(height: 16),
          if (issues.isEmpty)
            Text('这一章和设定档没有明显冲突。', style: context.texts.bodyLarge)
          else
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.sunken,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(issue.title, style: context.texts.titleMedium),
                      if (issue.detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(issue.detail, style: context.texts.bodySmall?.copyWith(height: 1.6)),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
