import 'dart:convert';

/// 同步文件的格式版本。改结构时 +1，读的时候能识别旧文件。
const int kLibraryFormatVersion = 1;

/// 一份完整的书库快照。这也是写进 GitHub 那个 JSON 文件的内容。
class LibraryBundle {
  const LibraryBundle({
    required this.projects,
    required this.deviceId,
    required this.exportedAt,
    this.tombstones = const [],
    this.version = kLibraryFormatVersion,
  });

  final int version;
  final String deviceId;
  final DateTime exportedAt;
  final List<ProjectBundle> projects;

  /// 已删除项目的墓碑：别的设备据此把本地同名项目也删掉
  final List<TombstoneBundle> tombstones;

  bool get isEmpty => projects.isEmpty;

  Map<String, dynamic> toJson() => {
        'format': 'mopu.library',
        'version': version,
        'deviceId': deviceId,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'projects': [for (final project in projects) project.toJson()],
        if (tombstones.isNotEmpty)
          'tombstones': [for (final tombstone in tombstones) tombstone.toJson()],
      };

  String encode({bool pretty = true}) =>
      pretty ? const JsonEncoder.withIndent('  ').convert(toJson()) : jsonEncode(toJson());

  /// 只覆盖内容、不含导出时间的哈希：用来判断「要不要推」。
  String get contentHash => _stableHash(jsonEncode({
        'projects': [for (final project in projects) project.toJson()],
        'tombstones': [for (final tombstone in tombstones) tombstone.toJson()],
      }));

  static LibraryBundle fromJson(Map<String, dynamic> json) {
    final rawProjects = json['projects'];
    return LibraryBundle(
      version: _int(json['version'], kLibraryFormatVersion),
      deviceId: '${json['deviceId'] ?? ''}',
      exportedAt: DateTime.tryParse('${json['exportedAt'] ?? ''}') ?? DateTime.now().toUtc(),
      projects: [
        if (rawProjects is List)
          for (final raw in rawProjects)
            if (raw is Map) ProjectBundle.fromJson(raw.cast<String, dynamic>()),
      ],
      tombstones: [
        if (json['tombstones'] is List)
          for (final raw in _list(json['tombstones']))
            if (raw is Map) TombstoneBundle.fromJson(raw.cast<String, dynamic>()),
      ],
    );
  }

  static LibraryBundle decode(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('同步文件不是 JSON 对象');
    final map = decoded.cast<String, dynamic>();
    if (map['format'] != 'mopu.library') {
      throw const FormatException('这不是墨谱的同步文件');
    }
    final version = _int(map['version'], 1);
    if (version > kLibraryFormatVersion) {
      throw FormatException('同步文件版本 $version 比当前 App 新，请先升级');
    }
    return LibraryBundle.fromJson(map);
  }
}

class ProjectBundle {
  const ProjectBundle({
    required this.syncId,
    required this.title,
    required this.genre,
    required this.synopsis,
    required this.wordGoal,
    required this.updatedAt,
    required this.chapters,
    this.deletedAt,
    required this.entities,
    required this.relations,
    required this.foreshadows,
  });

  final String syncId;
  final String title;
  final String genre;
  final String synopsis;
  final int wordGoal;
  final DateTime updatedAt;

  /// 非空 = 在回收站里（同步过去，别的设备也进回收站）
  final DateTime? deletedAt;
  final List<ChapterBundle> chapters;
  final List<EntityBundle> entities;
  final List<RelationBundle> relations;
  final List<ForeshadowBundle> foreshadows;

  Map<String, dynamic> toJson() => {
        'syncId': syncId,
        'title': title,
        'genre': genre,
        'synopsis': synopsis,
        'wordGoal': wordGoal,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        if (deletedAt != null) 'deletedAt': deletedAt!.toUtc().toIso8601String(),
        'chapters': [for (final chapter in chapters) chapter.toJson()],
        'entities': [for (final entity in entities) entity.toJson()],
        'relations': [for (final relation in relations) relation.toJson()],
        'foreshadows': [for (final item in foreshadows) item.toJson()],
      };

  static ProjectBundle fromJson(Map<String, dynamic> json) => ProjectBundle(
        syncId: '${json['syncId'] ?? ''}',
        title: '${json['title'] ?? '未命名'}',
        genre: '${json['genre'] ?? ''}',
        synopsis: '${json['synopsis'] ?? ''}',
        wordGoal: _int(json['wordGoal'], 0),
        updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json['deletedAt'] == null ? null : DateTime.tryParse('${json['deletedAt']}'),
        chapters: [
          for (final raw in _list(json['chapters']))
            if (raw is Map) ChapterBundle.fromJson(raw.cast<String, dynamic>()),
        ],
        entities: [
          for (final raw in _list(json['entities']))
            if (raw is Map) EntityBundle.fromJson(raw.cast<String, dynamic>()),
        ],
        relations: [
          for (final raw in _list(json['relations']))
            if (raw is Map) RelationBundle.fromJson(raw.cast<String, dynamic>()),
        ],
        foreshadows: [
          for (final raw in _list(json['foreshadows']))
            if (raw is Map) ForeshadowBundle.fromJson(raw.cast<String, dynamic>()),
        ],
      );
}

class TombstoneBundle {
  const TombstoneBundle({
    required this.syncId,
    required this.title,
    required this.deletedAt,
    this.deviceId = '',
  });

  final String syncId;
  final String title;
  final String deviceId;
  final DateTime deletedAt;

  Map<String, dynamic> toJson() => {
        'syncId': syncId,
        'title': title,
        if (deviceId.isNotEmpty) 'deviceId': deviceId,
        'deletedAt': deletedAt.toUtc().toIso8601String(),
      };

  static TombstoneBundle fromJson(Map<String, dynamic> json) => TombstoneBundle(
        syncId: '${json['syncId'] ?? ''}',
        title: '${json['title'] ?? ''}',
        deviceId: '${json['deviceId'] ?? ''}',
        deletedAt: DateTime.tryParse('${json['deletedAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class ChapterBundle {
  const ChapterBundle({
    required this.index,
    required this.title,
    required this.body,
    required this.status,
    required this.note,
  });

  final int index;
  final String title;
  final String body;
  final String status;
  final String note;

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'status': status,
        'note': note,
        'body': body,
      };

  static ChapterBundle fromJson(Map<String, dynamic> json) => ChapterBundle(
        index: _int(json['index'], 1),
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        status: '${json['status'] ?? 'draft'}',
        note: '${json['note'] ?? ''}',
      );
}

class EntityBundle {
  const EntityBundle({
    required this.name,
    required this.kind,
    required this.aliases,
    required this.summary,
    required this.importance,
    required this.status,
    required this.deathChapter,
  });

  final String name;
  final String kind;
  final List<String> aliases;
  final String summary;
  final int importance;
  final String status;
  final int? deathChapter;

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind,
        if (aliases.isNotEmpty) 'aliases': aliases,
        if (summary.isNotEmpty) 'summary': summary,
        'importance': importance,
        'status': status,
        if (deathChapter != null) 'deathChapter': deathChapter,
      };

  static EntityBundle fromJson(Map<String, dynamic> json) => EntityBundle(
        name: '${json['name'] ?? ''}',
        kind: '${json['kind'] ?? 'character'}',
        aliases: [
          for (final alias in _list(json['aliases'])) '$alias'.trim(),
        ].where((e) => e.isNotEmpty).toList(),
        summary: '${json['summary'] ?? ''}',
        importance: _int(json['importance'], 3),
        status: '${json['status'] ?? 'alive'}',
        deathChapter: json['deathChapter'] == null ? null : _int(json['deathChapter'], 0),
      );
}

class RelationBundle {
  const RelationBundle({
    required this.from,
    required this.to,
    required this.kind,
    required this.strength,
    required this.note,
    required this.validFrom,
    required this.validTo,
  });

  /// 用名字而不是本地 id 引用实体：仓库里的文件才是人能读的
  final String from;
  final String to;
  final String kind;
  final int strength;
  final String note;
  final int validFrom;
  final int? validTo;

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'kind': kind,
        'strength': strength,
        if (note.isNotEmpty) 'note': note,
        'validFrom': validFrom,
        if (validTo != null) 'validTo': validTo,
      };

  static RelationBundle fromJson(Map<String, dynamic> json) => RelationBundle(
        from: '${json['from'] ?? ''}',
        to: '${json['to'] ?? ''}',
        kind: '${json['kind'] ?? 'other'}',
        strength: _int(json['strength'], 3),
        note: '${json['note'] ?? ''}',
        validFrom: _int(json['validFrom'], 1),
        validTo: json['validTo'] == null ? null : _int(json['validTo'], 0),
      );
}

class ForeshadowBundle {
  const ForeshadowBundle({
    required this.hook,
    required this.plantedChapter,
    required this.resolvedChapter,
    required this.note,
  });

  final String hook;
  final int plantedChapter;
  final int? resolvedChapter;
  final String note;

  Map<String, dynamic> toJson() => {
        'hook': hook,
        'plantedChapter': plantedChapter,
        if (resolvedChapter != null) 'resolvedChapter': resolvedChapter,
        if (note.isNotEmpty) 'note': note,
      };

  static ForeshadowBundle fromJson(Map<String, dynamic> json) => ForeshadowBundle(
        hook: '${json['hook'] ?? ''}',
        plantedChapter: _int(json['plantedChapter'], 1),
        resolvedChapter: json['resolvedChapter'] == null ? null : _int(json['resolvedChapter'], 0),
        note: '${json['note'] ?? ''}',
      );
}

// ───────────────────────────── 工具 ─────────────────────────────

int _int(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

List<Object?> _list(Object? value) => value is List ? value : const [];

String _stableHash(String text) {
  // FNV-1a 32 位，够用来判断内容有没有变
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode(text)) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
