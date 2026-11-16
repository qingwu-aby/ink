import 'dart:convert';
import 'dart:typed_data';

import '../../data/db/app_database.dart';
import '../taxonomy.dart';

/// 一份可写出的文件。
class ExportFile {
  const ExportFile({required this.fileName, required this.bytes, required this.mimeType});

  final String fileName;
  final Uint8List bytes;
  final String mimeType;

  int get size => bytes.length;
}

/// 把项目导出成各种格式。纯函数，不碰文件系统，方便单测。
class ExportService {
  static final _illegal = RegExp(r'[\\/:*?"<>|\n\r]');

  /// 章节标题本身已经带「第X章」时不再重复加序号。
  static String chapterHeading(Chapter chapter) {
    final title = chapter.title.trim();
    if (title.isEmpty) return '第 ${chapter.index} 章';
    final prefixed = RegExp(
      r'^(第\s*[0-9零〇一二两三四五六七八九十百千]+\s*[章节回卷]|楔子|序章|序言|引|终章|尾声|后记|番外)',
    ).hasMatch(title);
    return prefixed ? title : '第 ${chapter.index} 章　$title';
  }

  static String safeName(String raw) {
    final trimmed = raw.trim().replaceAll(_illegal, '_');
    return trimmed.isEmpty ? '未命名' : trimmed;
  }

  // ───────────────────────────── 正文 ─────────────────────────────

  static ExportFile bookText(Project project, List<Chapter> chapters) {
    final buffer = StringBuffer()
      ..writeln(project.title)
      ..writeln()
      ..writeln('共 ${chapters.length} 章，${_totalWords(chapters)} 字')
      ..writeln()
      ..writeln('=' * 24)
      ..writeln();
    for (final chapter in chapters) {
      buffer
        ..writeln(chapterHeading(chapter))
        ..writeln()
        ..writeln(chapter.body.trimRight())
        ..writeln()
        ..writeln();
    }
    return ExportFile(
      fileName: '${safeName(project.title)}_全文.txt',
      bytes: _utf8(buffer.toString()),
      mimeType: 'text/plain',
    );
  }

  static ExportFile bookMarkdown(Project project, List<Chapter> chapters) {
    final buffer = StringBuffer()
      ..writeln('# ${project.title}')
      ..writeln();
    if (project.synopsis.isNotEmpty) {
      buffer
        ..writeln('> ${project.synopsis.replaceAll('\n', ' ')}')
        ..writeln();
    }
    if (project.genre.isNotEmpty) {
      buffer
        ..writeln('类型：${project.genre}')
        ..writeln();
    }
    buffer.writeln('---');
    buffer.writeln();
    for (final chapter in chapters) {
      buffer
        ..writeln('## ${chapterHeading(chapter)}')
        ..writeln()
        ..writeln(chapter.body.trimRight())
        ..writeln();
    }
    return ExportFile(
      fileName: '${safeName(project.title)}.md',
      bytes: _utf8(buffer.toString()),
      mimeType: 'text/markdown',
    );
  }

  // ───────────────────────────── 表格 ─────────────────────────────

  static ExportFile entitiesCsv(
    Project project,
    List<Entity> entities,
    List<Relation> relations,
    Map<int, int> mentionCounts,
  ) {
    final degree = <int, int>{};
    for (final relation in relations) {
      degree[relation.fromId] = (degree[relation.fromId] ?? 0) + 1;
      degree[relation.toId] = (degree[relation.toId] ?? 0) + 1;
    }

    final rows = <List<String>>[
      ['类型', '名称', '别称', '简介', '重要度', '状态', '退场章', '关系数', '出现次数'],
      for (final entity in entities)
        [
          EntityKind.parse(entity.kind).label,
          entity.name,
          _aliasText(entity.aliases),
          entity.summary,
          '${entity.importance}',
          EntityStatus.parse(entity.status).label,
          entity.deathChapter?.toString() ?? '',
          '${degree[entity.id] ?? 0}',
          '${mentionCounts[entity.id] ?? 0}',
        ],
    ];
    return ExportFile(
      fileName: '${safeName(project.title)}_实体表.csv',
      bytes: _utf8(_csv(rows), bom: true),
      mimeType: 'text/csv',
    );
  }

  static ExportFile relationsCsv(Project project, List<Entity> entities, List<Relation> relations) {
    final byId = {for (final entity in entities) entity.id: entity};
    final rows = <List<String>>[
      ['从', '关系', '到', '亲疏', '起始章', '结束章', '备注'],
      for (final relation in relations)
        [
          byId[relation.fromId]?.name ?? '(已删除)',
          RelationKind.parse(relation.kind).label,
          byId[relation.toId]?.name ?? '(已删除)',
          '${relation.strength}',
          '${relation.validFrom}',
          relation.validTo?.toString() ?? '',
          relation.note,
        ],
    ];
    return ExportFile(
      fileName: '${safeName(project.title)}_关系表.csv',
      bytes: _utf8(_csv(rows), bom: true),
      mimeType: 'text/csv',
    );
  }

  static ExportFile foreshadowsCsv(Project project, List<Foreshadow> foreshadows) {
    final rows = <List<String>>[
      ['伏笔', '埋于', '回收于', '状态', '备注'],
      for (final item in foreshadows)
        [
          item.hook,
          '第 ${item.plantedChapter} 章',
          item.resolvedChapter == null ? '' : '第 ${item.resolvedChapter} 章',
          item.resolvedChapter == null ? '未回收' : '已回收',
          item.note,
        ],
    ];
    return ExportFile(
      fileName: '${safeName(project.title)}_伏笔表.csv',
      bytes: _utf8(_csv(rows), bom: true),
      mimeType: 'text/csv',
    );
  }

  // ───────────────────────────── 工具 ─────────────────────────────

  static int _totalWords(List<Chapter> chapters) =>
      chapters.fold(0, (sum, chapter) => sum + chapter.wordCount);

  /// [bom] 为真时加 BOM：Windows 上的 Excel 打开中文 CSV 才不会乱码。
  static Uint8List _utf8(String text, {bool bom = false}) {
    final bytes = utf8.encode(text);
    return Uint8List.fromList(bom ? [0xEF, 0xBB, 0xBF, ...bytes] : bytes);
  }

  static String _aliasText(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '[]') return '';
    if (text.startsWith('[')) {
      return text
          .substring(1, text.length - 1)
          .split(',')
          .map((e) => e.replaceAll('"', '').trim())
          .where((e) => e.isNotEmpty)
          .join(' ');
    }
    return text;
  }

  static String _csv(List<List<String>> rows) => rows
      .map((row) => row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','))
      .join('\r\n');
}
