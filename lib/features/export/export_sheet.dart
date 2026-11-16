import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/export/export_service.dart';
import '../../domain/graph/graph_image.dart';
import '../../providers.dart';

Future<void> showExportSheet(BuildContext context, {required int projectId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExportSheet(projectId: projectId),
  );
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({required this.projectId});

  final int projectId;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  String? _busy;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(widget.projectId)).value;
    final chapters = ref.watch(chaptersProvider(widget.projectId)).value ?? const <Chapter>[];
    final entities = ref.watch(entitiesProvider(widget.projectId)).value ?? const <Entity>[];
    final relations = ref.watch(relationsProvider(widget.projectId)).value ?? const <Relation>[];
    final foreshadows =
        ref.watch(foreshadowsProvider(widget.projectId)).value ?? const <Foreshadow>[];
    final counts = ref.watch(mentionCountsProvider(widget.projectId)).value;

    final ready = project != null && counts != null && chapters.isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text('导出', style: context.texts.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '导到别处也读得懂：正文带章节标题，表格带表头，图谱带书名。',
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 18),
          _GroupLabel('正文'),
          _ExportRow(
            icon: Icons.description_outlined,
            title: '整书 TXT',
            subtitle: '${chapters.length} 章 · 章节标题与正文分行',
            busy: _busy == 'txt',
            enabled: ready,
            onTap: () => _run('txt', () => ExportService.bookText(project!, chapters)),
          ),
          _ExportRow(
            icon: Icons.article_outlined,
            title: '整书 Markdown',
            subtitle: '带书名、简介与分级标题，适合放进笔记软件',
            busy: _busy == 'md',
            enabled: ready,
            onTap: () => _run('md', () => ExportService.bookMarkdown(project!, chapters)),
          ),
          const SizedBox(height: 16),
          _GroupLabel('数据表'),
          _ExportRow(
            icon: Icons.table_chart_outlined,
            title: '实体表 CSV',
            subtitle: '类型、别称、状态、关系数、出现次数',
            busy: _busy == 'entities',
            enabled: project != null && counts != null,
            onTap: () => _run(
              'entities',
              () => ExportService.entitiesCsv(project!, entities, relations, counts!),
            ),
          ),
          _ExportRow(
            icon: Icons.share_outlined,
            title: '关系表 CSV',
            subtitle: '${relations.length} 条，含方向与生效章节',
            busy: _busy == 'relations',
            enabled: project != null,
            onTap: () => _run('relations', () => ExportService.relationsCsv(project!, entities, relations)),
          ),
          _ExportRow(
            icon: Icons.bookmark_border,
            title: '伏笔表 CSV',
            subtitle: '${foreshadows.length} 条，标出回收状态',
            busy: _busy == 'foreshadows',
            enabled: project != null,
            onTap: () => _run('foreshadows', () => ExportService.foreshadowsCsv(project!, foreshadows)),
          ),
          const SizedBox(height: 16),
          _GroupLabel('图像'),
          _ExportRow(
            icon: Icons.image_outlined,
            title: '图谱 PNG',
            subtitle: entities.isEmpty ? '还没有实体' : '${entities.length} 个实体 · 2800×2000',
            busy: _busy == 'png',
            enabled: project != null && entities.isNotEmpty && counts != null,
            onTap: () => _runPng(project!, entities, relations, counts!),
          ),
          const SizedBox(height: 20),
          Text(
            '文件通过系统「另存为」对话框保存，不会上传到任何地方。',
            style: context.texts.labelSmall,
          ),
        ],
      ),
    );
  }

  Future<void> _run(String key, ExportFile Function() build) async {
    setState(() => _busy = key);
    try {
      final file = build();
      await _save(file);
    } catch (error) {
      if (mounted) _toast('导出失败：$error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _runPng(
    Project project,
    List<Entity> entities,
    List<Relation> relations,
    Map<int, int> counts,
  ) async {
    setState(() => _busy = 'png');
    try {
      final bytes = await renderGraphPng(
        entities: entities,
        relations: relations,
        mentionCounts: counts,
        title: project.title,
        dark: Theme.of(context).brightness == Brightness.dark,
      );
      await _save(ExportFile(
        fileName: '${ExportService.safeName(project.title)}_图谱.png',
        bytes: bytes,
        mimeType: 'image/png',
      ));
    } catch (error) {
      if (mounted) _toast('图谱导出失败：$error');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _save(ExportFile file) async {
    // 首选系统「另存为」；某些设备/权限下拿不到 SAF 时退回应用目录，别让导出直接失败
    try {
      final uri = await FilePicker.saveFile(
        fileName: file.fileName,
        bytes: file.bytes,
        mimeType: file.mimeType,
      );
      if (!mounted) return;
      if (uri == null) return; // 用户取消
      _toast('已保存 ${file.fileName}（${_sizeText(file.size)}）');
      return;
    } catch (_) {
      // 继续走兜底
    }
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/${file.fileName}');
    await target.writeAsBytes(file.bytes, flush: true);
    if (!mounted) return;
    _toast('已保存到应用目录：${target.path}（${_sizeText(file.size)}）');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _sizeText(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text, style: context.texts.labelMedium?.copyWith(letterSpacing: 1.2)),
    );
  }
}

class _ExportRow extends StatelessWidget {
  const _ExportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: Border.all(color: context.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: active ? context.soft : context.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.texts.titleMedium?.copyWith(
                        color: active
                            ? Theme.of(context).colorScheme.onSurface
                            : context.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: context.texts.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.file_download_outlined,
                  size: 18,
                  color: active ? Theme.of(context).colorScheme.primary : context.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
