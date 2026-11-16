import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../core/utils/text_utils.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../providers.dart';
import '../project/project_shell.dart';
import '../relations/relation_editor_sheet.dart';

class EntityEditorScreen extends ConsumerStatefulWidget {
  const EntityEditorScreen({
    super.key,
    required this.projectId,
    required this.entityId,
  });

  final int projectId;
  final int entityId;

  @override
  ConsumerState<EntityEditorScreen> createState() => _EntityEditorScreenState();
}

class _EntityEditorScreenState extends ConsumerState<EntityEditorScreen> {
  final _name = TextEditingController();
  final _aliases = TextEditingController();
  final _summary = TextEditingController();
  final _deathChapter = TextEditingController();

  int _savedId = 0;
  EntityKind _kind = EntityKind.character;
  EntityStatus _status = EntityStatus.alive;
  int _importance = 3;
  bool _loading = true;
  bool _dirty = false;
  String _savedHint = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _savedId = widget.entityId;
    if (_savedId > 0) {
      _load();
    } else {
      _loading = false;
    }
    _name.addListener(_onChanged);
    _aliases.addListener(_onChanged);
    _summary.addListener(_onChanged);
    _deathChapter.addListener(_onChanged);
  }

  Future<void> _load() async {
    final entity = await ref.read(databaseProvider).getEntity(_savedId);
    if (!mounted) return;
    setState(() {
      if (entity != null) {
        _name.text = entity.name;
        _aliases.text = parseStringList(entity.aliases).join(' ');
        _summary.text = entity.summary;
        _kind = EntityKind.parse(entity.kind);
        _status = EntityStatus.parse(entity.status);
        _importance = entity.importance;
        if (entity.deathChapter != null) _deathChapter.text = '${entity.deathChapter}';
      }
      _loading = false;
      _dirty = false;
      _savedHint = entity == null ? '' : '已载入';
    });
  }

  void _onChanged() {
    if (_loading) return;
    setState(() => _dirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _save);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final db = ref.read(databaseProvider);

    if (_savedId == 0) {
      final id = await db.createEntity(
        projectId: widget.projectId,
        name: name,
        kind: _kind.key,
        aliases: splitAliases(_aliases.text),
        summary: _summary.text.trim(),
        importance: _importance,
        status: _status.key,
      );
      if (!mounted) return;
      setState(() => _savedId = id);
      _savedHint = '已创建';
      _dirty = false;
      return;
    }

    final existing = await db.getEntity(_savedId);
    if (existing == null) return;
    await db.updateEntity(
      existing.copyWith(
        name: name,
        kind: _kind.key,
        aliases: encodeStringList(splitAliases(_aliases.text)),
        summary: _summary.text.trim(),
        importance: _importance,
        status: _status.key,
        deathChapter: Value(_status == EntityStatus.dead ? int.tryParse(_deathChapter.text.trim()) : null),
      ),
    );
    if (!mounted) return;
    setState(() {
      _dirty = false;
      _savedHint = '已保存';
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _aliases.dispose();
    _summary.dispose();
    _deathChapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final relations = ref.watch(relationsProvider(widget.projectId)).value ?? const <Relation>[];
    final mentions = ref.watch(mentionsProvider(widget.projectId)).value ?? const <Mention>[];
    final chapters = ref.watch(chaptersProvider(widget.projectId)).value ?? const <Chapter>[];

    final byId = <int, Entity>{for (final e in entities) e.id: e};
    final myRelations = _savedId == 0
        ? <Relation>[]
        : (relations.where((r) => r.fromId == _savedId || r.toId == _savedId).toList()
          ..sort((a, b) => b.strength.compareTo(a.strength)));

    final myMentions = mentions.where((m) => m.entityId == _savedId).toList();
    final chapterIndexById = {for (final c in chapters) c.id: c};
    // 同一章出现多次只算一次
    final appearedMap = <int, Chapter>{};
    for (final mention in myMentions) {
      final chapter = chapterIndexById[mention.chapterId];
      if (chapter != null) appearedMap[chapter.id] = chapter;
    }
    final appearedChapters = appearedMap.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Scaffold(
      appBar: AppBar(
        title: Text(_savedId == 0 ? '新建实体' : '实体档案'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                _dirty ? '编辑中…' : _savedHint,
                style: context.texts.labelSmall,
              ),
            ),
          ),
          if (_savedId > 0)
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('删除这个实体？'),
                    content: Text('「${_name.text.trim()}」的关系会一并删除，正文里的提及也会消失。'),
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
                if (ok != true) return;
                await ref.read(databaseProvider).deleteEntity(_savedId);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _name,
                        style: context.texts.headlineSmall,
                        decoration: const InputDecoration(
                          labelText: '名字',
                          hintText: '沈砚之',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Divider(color: context.border, height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final kind in EntityKind.values)
                            _Choice(
                              label: kind.label,
                              icon: kind.icon,
                              selected: _kind == kind,
                              color: kind.color(Theme.of(context).brightness),
                              onTap: () {
                                setState(() => _kind = kind);
                                _onChanged();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _aliases,
                        decoration: const InputDecoration(
                          labelText: '别称 / 字号 / 绰号',
                          hintText: '用空格或逗号分隔，正文高亮会用上',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _summary,
                        minLines: 3,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: '档案',
                          hintText: '身份、动机、秘密。写给别人看的版本，也写给自己看的版本。',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text('重要度', style: context.texts.titleSmall),
                          const SizedBox(width: 10),
                          Text(
                            const ['道具', '过场', '配角', '重要', '主角'][_importance - 1],
                            style: context.texts.bodySmall,
                          ),
                          Expanded(
                            child: Slider(
                              value: _importance.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: '${_importance}',
                              onChanged: (value) {
                                setState(() => _importance = value.round());
                                _onChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: '状态',
                  subtitle: '「已故」会参与一致性校验：死人再出场会被抓出来',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in EntityStatus.values)
                            _Choice(
                              label: status.label,
                              selected: _status == status,
                              color: status == EntityStatus.dead ? Mo.vermilion : null,
                              onTap: () {
                                setState(() => _status = status);
                                _onChanged();
                              },
                            ),
                        ],
                      ),
                      if (_status == EntityStatus.dead) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _deathChapter,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '在第几章退场',
                            hintText: '例如 12',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_savedId > 0) ...[
                  const SizedBox(height: 14),
                  SectionCard(
                    title: '出场',
                    subtitle: appearedChapters.isEmpty
                        ? '还没在任何章节里出现过'
                        : '共 ${myMentions.length} 次，横跨 ${appearedChapters.length} 章',
                    action: appearedChapters.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () => context.push(
                              '/p/${widget.projectId}/search?eid=$_savedId',
                            ),
                            child: const Text('看所有段落'),
                          ),
                    child: appearedChapters.isEmpty
                        ? Text('在正文里写下这个名字，这里就会自动出现记录。', style: context.texts.bodySmall)
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final chapter in appearedChapters.take(12))
                                GestureDetector(
                                  onTap: () => context.push('/p/${widget.projectId}/chapter/${chapter.id}'),
                                  child: TagPill(
                                    label: '第 ${chapter.index} 章',
                                    color: EntityKind.parse(_kind.key)
                                        .color(Theme.of(context).brightness),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: '关系',
                    subtitle: '${myRelations.length} 条连线',
                    action: TextButton.icon(
                      onPressed: () => _addRelation(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加'),
                    ),
                    child: myRelations.isEmpty
                        ? Text('还没有连线。孤立的角色在长篇里几乎等于不存在。', style: context.texts.bodySmall)
                        : Column(
                            children: [
                              for (final relation in myRelations)
                                _RelationTile(
                                  relation: relation,
                                  selfId: _savedId,
                                  other: byId[relation.fromId == _savedId ? relation.toId : relation.fromId],
                                  onTap: () async {
                                    final other = byId[relation.fromId == _savedId ? relation.toId : relation.fromId];
                                    if (other == null) return;
                                    await showRelationEditor(
                                      context,
                                      projectId: widget.projectId,
                                      fromId: relation.fromId,
                                      toId: relation.toId,
                                      relationId: relation.id,
                                      kind: relation.kind,
                                      strength: relation.strength,
                                      note: relation.note,
                                      validFrom: relation.validFrom,
                                      validTo: relation.validTo,
                                    );
                                  },
                                ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _addRelation(BuildContext context) async {
    final picked = await showModalBottomSheet<Entity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EntityPicker(projectId: widget.projectId, excludeId: _savedId),
    );
    if (picked == null || !context.mounted) return;
    await showRelationEditor(
      context,
      projectId: widget.projectId,
      fromId: _savedId,
      toId: picked.id,
    );
  }
}

class _RelationTile extends StatelessWidget {
  const _RelationTile({
    required this.relation,
    required this.selfId,
    required this.other,
    required this.onTap,
  });

  final Relation relation;
  final int selfId;
  final Entity? other;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = RelationKind.parse(relation.kind);
    final outgoing = relation.fromId == selfId;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(
              kind.symmetric ? Icons.swap_horiz : (outgoing ? Icons.east : Icons.west),
              size: 15,
              color: context.muted,
            ),
            const SizedBox(width: 8),
            Text(kind.label, style: context.texts.labelLarge),
            const SizedBox(width: 10),
            if (other != null) ...[
              KindAvatar(kind: EntityKind.parse(other!.kind), name: other!.name, size: 22),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                other?.name ?? '（已删除）',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            Text(
              relation.validTo == null ? '第 ${relation.validFrom} 章起' : '第 ${relation.validFrom}–${relation.validTo} 章',
              style: context.texts.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? base.withValues(alpha: 0.13) : context.sunken,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? base.withValues(alpha: 0.42) : context.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? base : context.muted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: selected ? base : context.soft,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityPicker extends ConsumerStatefulWidget {
  const _EntityPicker({required this.projectId, required this.excludeId});

  final int projectId;
  final int excludeId;

  @override
  ConsumerState<_EntityPicker> createState() => _EntityPickerState();
}

class _EntityPickerState extends ConsumerState<_EntityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final list = entities
        .where((e) => e.id != widget.excludeId)
        .where((e) => _query.isEmpty || e.name.contains(_query) || e.aliases.contains(_query))
        .toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              autofocus: false,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: '选择要连线的实体',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('没有可选的实体'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final entity = list[index];
                      final kind = EntityKind.parse(entity.kind);
                      return ListTile(
                        dense: true,
                        leading: KindAvatar(kind: kind, name: entity.name, size: 32),
                        title: Text(entity.name, style: context.texts.bodyLarge),
                        subtitle: entity.summary.isEmpty
                            ? null
                            : Text(entity.summary, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: KindPill(kind: kind, dense: true),
                        onTap: () => Navigator.of(context).pop(entity),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
