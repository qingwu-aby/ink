import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../data/db/app_database.dart';
import '../../core/widgets/common.dart';
import '../../domain/import/chapter_splitter.dart';
import '../../domain/llm/llm_client.dart';
import '../../domain/text/entity_matcher.dart';
import '../../providers.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _paste = TextEditingController();
  List<DraftChapter>? _drafts;
  String _sourceName = '';
  bool _busy = false;
  bool _withAi = false;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  void _accept(String text, String source) {
    final drafts = ChapterSplitter.split(text);
    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没读出任何内容')));
      return;
    }
    setState(() {
      _drafts = drafts;
      _sourceName = source;
    });
  }

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md', 'markdown', 'text'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();
      final text = utf8.decode(bytes, allowMalformed: true);
      if (!mounted) return;
      _accept(text, file.name);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('读文件失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = ref.watch(aiConfigProvider).value;
    final aiReady = ai != null && ai.enabled && ai.config.isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('导入旧稿')),
      body: _drafts == null ? _buildSource(aiReady) : _buildPreview(aiReady),
    );
  }

  Widget _buildSource(bool aiReady) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: [
        Text('把已经写好的稿子搬进来', style: context.texts.headlineSmall),
        const SizedBox(height: 6),
        Text(
          '支持 txt / md。会按「第 X 章」「楔子」「## 标题」这类行自动切章，切错了可以在下一步勾掉。',
          style: context.texts.bodySmall?.copyWith(height: 1.7),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('选择文件'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: context.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('或者直接粘贴', style: context.texts.labelMedium),
            ),
            Expanded(child: Divider(color: context.border)),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _paste,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: '把正文粘到这里……',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _accept(_paste.text, '粘贴的文本'),
          child: const Text('解析分章'),
        ),
        if (aiReady) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.sunken,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: context.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '已开启 AI 助手：导入后可以让它顺手把人物和关系抽出来。',
                    style: context.texts.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreview(bool aiReady) {
    final drafts = _drafts!;
    final total = drafts.fold<int>(0, (sum, d) => sum + d.wordCount);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            itemCount: drafts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '识别到 ${drafts.length} 章 · $total 字',
                              style: context.texts.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _drafts = null;
                              _paste.clear();
                            }),
                            child: const Text('重来'),
                          ),
                        ],
                      ),
                      Text(_sourceName, style: context.texts.labelSmall),
                    ],
                  ),
                );
              }
              final draft = drafts[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text('${index}', style: context.texts.labelMedium),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${draft.wordCount} 字',
                              style: context.texts.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(top: BorderSide(color: context.border)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                if (aiReady)
                  CheckboxListTile(
                    value: _withAi,
                    onChanged: (value) => setState(() => _withAi = value ?? false),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text('导入后让 AI 抽取人物与关系', style: context.texts.bodySmall),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _doImport(withAi: _withAi && aiReady),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('导入 ${drafts.length} 章'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _doImport({required bool withAi}) async {
    final drafts = _drafts;
    if (drafts == null) return;
    setState(() => _busy = true);

    final db = ref.read(databaseProvider);
    for (final draft in drafts) {
      final id = await db.createChapter(
        projectId: widget.projectId,
        title: draft.title,
        body: draft.body,
      );
      final entities = await db.entitiesOf(widget.projectId);
      if (entities.isNotEmpty) {
        await db.replaceMentions(id, EntityMatcher(entities).scan(draft.body));
      }
    }

    if (!mounted) return;
    setState(() => _busy = false);

    if (withAi) {
      final ai = ref.read(aiConfigProvider).value;
      if (ai != null) {
        final text = drafts.map((d) => d.body).join('\n\n');
        final entities = await ref.read(databaseProvider).entitiesOf(widget.projectId);
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Expanded(child: Text('正在读稿，抽人物与关系…')),
              ],
            ),
          ),
        );
        try {
          final result = await LlmClient(ai.config).extract(
            text: text,
            knownNames: entities.map((e) => e.name).toList(),
            projectTitle: '旧稿',
          );
          if (!mounted) return;
          Navigator.of(context).pop();
          await showExtractionReview(
            context,
            projectId: widget.projectId,
            extraction: result,
          );
        } catch (error) {
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('AI 抽取失败：$error')),
          );
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

/// AI 抽取结果的人工复核面板。
Future<void> showExtractionReview(
  BuildContext context, {
  required int projectId,
  required AiExtraction extraction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExtractionReview(projectId: projectId, extraction: extraction),
  );
}

class _ExtractionReview extends ConsumerStatefulWidget {
  const _ExtractionReview({required this.projectId, required this.extraction});

  final int projectId;
  final AiExtraction extraction;

  @override
  ConsumerState<_ExtractionReview> createState() => _ExtractionReviewState();
}

class _ExtractionReviewState extends ConsumerState<_ExtractionReview> {
  final _pickedEntities = <int>{};
  final _pickedRelations = <int>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.extraction.entities.length; i++) {
      _pickedEntities.add(i);
    }
    for (var i = 0; i < widget.extraction.relations.length; i++) {
      _pickedRelations.add(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extraction = widget.extraction;
    final existing = ref.watch(entitiesProvider(widget.projectId)).value ?? const [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              children: [
                Text('AI 抽出来的东西', style: context.texts.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '它只是读了正文的字面。确认后再写进图谱，误判的自己划掉。',
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 16),
                Text('实体 ${extraction.entities.length}', style: context.texts.titleMedium),
                const SizedBox(height: 6),
                for (var i = 0; i < extraction.entities.length; i++)
                  _PickTile(
                    selected: _pickedEntities.contains(i),
                    title: extraction.entities[i].name,
                    subtitle: extraction.entities[i].summary,
                    badge: extraction.entities[i].kind.label,
                    onChanged: (value) => setState(() {
                      if (value) {
                        _pickedEntities.add(i);
                      } else {
                        _pickedEntities.remove(i);
                      }
                    }),
                  ),
                if (extraction.relations.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('关系 ${extraction.relations.length}', style: context.texts.titleMedium),
                  const SizedBox(height: 6),
                  for (var i = 0; i < extraction.relations.length; i++)
                    _PickTile(
                      selected: _pickedRelations.contains(i),
                      title: '${extraction.relations[i].from} → ${extraction.relations[i].to}',
                      subtitle: extraction.relations[i].note,
                      badge: extraction.relations[i].kind,
                      onChanged: (value) => setState(() {
                        if (value) {
                          _pickedRelations.add(i);
                        } else {
                          _pickedRelations.remove(i);
                        }
                      }),
                    ),
                ],
                if (existing.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    '已有 ${existing.length} 个实体，重名的会自动跳过。',
                    style: context.texts.labelSmall,
                  ),
                ],
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('全部不要'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : () => _commit(existing),
                    child: Text('写入 ${_pickedEntities.length + _pickedRelations.length} 条'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _commit(List<Entity> existing) async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final nameToId = <String, int>{};
    for (final entity in existing) {
      nameToId[entity.name.toLowerCase()] = entity.id;
    }

    for (var i = 0; i < widget.extraction.entities.length; i++) {
      if (!_pickedEntities.contains(i)) continue;
      final draft = widget.extraction.entities[i];
      final key = draft.name.toLowerCase();
      if (nameToId.containsKey(key)) continue;
      final id = await db.createEntity(
        projectId: widget.projectId,
        name: draft.name,
        kind: draft.kind.key,
        aliases: draft.aliases,
        summary: draft.summary,
        importance: 3,
      );
      nameToId[key] = id;
    }

    for (var i = 0; i < widget.extraction.relations.length; i++) {
      if (!_pickedRelations.contains(i)) continue;
      final draft = widget.extraction.relations[i];
      final from = nameToId[draft.from.toLowerCase()];
      final to = nameToId[draft.to.toLowerCase()];
      if (from == null || to == null || from == to) continue;
      await db.upsertRelation(
        projectId: widget.projectId,
        fromId: from,
        toId: to,
        kind: draft.kind,
        note: draft.note,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已写入 ${_pickedEntities.length} 个实体、${_pickedRelations.length} 条关系')),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onChanged,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String badge;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? context.sunken : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: context.border),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyLarge,
              ),
            ),
            const SizedBox(width: 8),
            TagPill(label: badge),
          ],
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.texts.bodySmall),
      ),
    );
  }
}
