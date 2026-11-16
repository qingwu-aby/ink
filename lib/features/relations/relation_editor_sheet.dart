import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';

/// 编辑一条关系：方向、类型、亲疏、生效章节。
Future<bool?> showRelationEditor(
  BuildContext context, {
  required int projectId,
  required int fromId,
  required int toId,
  int? relationId,
  String kind = 'other',
  int strength = 3,
  String note = '',
  int validFrom = 1,
  int? validTo,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RelationEditor(
      projectId: projectId,
      fromId: fromId,
      toId: toId,
      relationId: relationId,
      initialKind: kind,
      initialStrength: strength,
      initialNote: note,
      initialFrom: validFrom,
      initialTo: validTo,
    ),
  );
}

class _RelationEditor extends ConsumerStatefulWidget {
  const _RelationEditor({
    required this.projectId,
    required this.fromId,
    required this.toId,
    required this.relationId,
    required this.initialKind,
    required this.initialStrength,
    required this.initialNote,
    required this.initialFrom,
    required this.initialTo,
  });

  final int projectId;
  final int fromId;
  final int toId;
  final int? relationId;
  final String initialKind;
  final int initialStrength;
  final String initialNote;
  final int initialFrom;
  final int? initialTo;

  @override
  ConsumerState<_RelationEditor> createState() => _RelationEditorState();
}

class _RelationEditorState extends ConsumerState<_RelationEditor> {
  late String _kind = widget.initialKind;
  late int _strength = widget.initialStrength;
  late final _note = TextEditingController(text: widget.initialNote);
  late final _from = TextEditingController(text: '${widget.initialFrom}');
  late final _to = TextEditingController(text: widget.initialTo?.toString() ?? '');

  @override
  void dispose() {
    _note.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const [];
    final from = entities.where((e) => e.id == widget.fromId).toList();
    final to = entities.where((e) => e.id == widget.toId).toList();
    final fromName = from.isEmpty ? '?' : from.first.name;
    final toName = to.isEmpty ? '?' : to.first.name;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.relationId == null ? '新建关系' : '编辑关系',
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.sunken,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fromName,
                      textAlign: TextAlign.center,
                      style: context.texts.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward, size: 16, color: context.muted),
                  ),
                  Expanded(
                    child: Text(
                      toName,
                      textAlign: TextAlign.center,
                      style: context.texts.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('关系', style: context.texts.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in RelationKind.all)
                  GestureDetector(
                    onTap: () => setState(() => _kind = kind.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _kind == kind.key
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
                            : context.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _kind == kind.key
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
                              : context.border,
                        ),
                      ),
                      child: Text(
                        kind.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _kind == kind.key
                              ? Theme.of(context).colorScheme.primary
                              : context.soft,
                          fontWeight: _kind == kind.key ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('亲疏', style: context.texts.titleSmall),
                const SizedBox(width: 10),
                Text(relationStrengthLabels[_strength] ?? '', style: context.texts.bodySmall),
                Expanded(
                  child: Slider(
                    value: _strength.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setState(() => _strength = value.round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _from,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '自第几章起'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _to,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '到第几章止（空=至今）'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(labelText: '备注', hintText: '这段关系的由来，一句话即可'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (widget.relationId != null) ...[
                  TextButton(
                    onPressed: () async {
                      await ref.read(databaseProvider).deleteRelation(widget.relationId!);
                      if (context.mounted) Navigator.of(context).pop(true);
                    },
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text('删除'),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () async {
                    await ref.read(databaseProvider).upsertRelation(
                          id: widget.relationId,
                          projectId: widget.projectId,
                          fromId: widget.fromId,
                          toId: widget.toId,
                          kind: _kind,
                          strength: _strength,
                          note: _note.text.trim(),
                          validFrom: int.tryParse(_from.text.trim()) ?? 1,
                          validTo: int.tryParse(_to.text.trim()),
                        );
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
