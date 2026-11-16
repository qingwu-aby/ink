import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';
import 'github_client.dart';

/// 同步配置：仓库地址、分支、Token。
class SyncSettings {
  const SyncSettings({
    required this.repository,
    required this.branch,
    required this.token,
  });

  final String repository;
  final String branch;
  final String token;

  bool get isReady => repository.trim().isNotEmpty && token.trim().isNotEmpty;

  String get slug {
    final parsed = GitHubClient.parseRepo(repository);
    return parsed == null ? repository : '${parsed.$1}/${parsed.$2}';
  }

  SyncSettings copyWith({String? repository, String? branch, String? token}) => SyncSettings(
        repository: repository ?? this.repository,
        branch: branch ?? this.branch,
        token: token ?? this.token,
      );

  static const empty = SyncSettings(repository: '', branch: 'main', token: '');
}

class SyncSettingsStore {
  SyncSettingsStore(this._db, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final AppDatabase _db;
  final FlutterSecureStorage _storage;

  static const _kRepo = 'sync.repository';
  static const _kBranch = 'sync.branch';
  static const _kLastAt = 'sync.lastAt';
  static const _kDevice = 'sync.deviceId';
  static const _kLastResult = 'sync.lastResult';
  static const _kAutoDaily = 'sync.autoDaily';
  static const _kLastAttempt = 'sync.lastAttemptAt';
  static const _kAutoError = 'sync.lastAutoError';
  static const _keychainKey = 'mopu_sync_token';

  Future<SyncSettings> load() async {
    return SyncSettings(
      repository: await _db.getSetting(_kRepo) ?? '',
      branch: await _db.getSetting(_kBranch) ?? 'main',
      token: await readToken() ?? '',
    );
  }

  Future<void> save(SyncSettings settings) async {
    await _db.setSetting(_kRepo, settings.repository.trim());
    await _db.setSetting(_kBranch, settings.branch.trim().isEmpty ? 'main' : settings.branch.trim());
    await writeToken(settings.token);
  }

  Future<DateTime?> lastSyncAt() async {
    final raw = await _db.getSetting(_kLastAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markSynced(DateTime at, String summary) async {
    await _db.setSetting(_kLastAt, at.toUtc().toIso8601String());
    await _db.setSetting(_kLastResult, summary);
  }

  Future<String?> lastResult() => _db.getSetting(_kLastResult);

  /// 每天自动同步（默认开）。真正连网前还会再检查「距上次是否满 24 小时」。
  Future<bool> autoDaily() async => (await _db.getSetting(_kAutoDaily)) != '0';

  Future<void> setAutoDaily(bool value) => _db.setSetting(_kAutoDaily, value ? '1' : '0');

  /// 上次尝试时间：失败时也要记，避免每次回到前台都重试。
  Future<DateTime?> lastAttemptAt() async {
    final raw = await _db.getSetting(_kLastAttempt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markAttempt(DateTime at) =>
      _db.setSetting(_kLastAttempt, at.toUtc().toIso8601String());

  Future<String?> lastAutoError() => _db.getSetting(_kAutoError);

  Future<void> markAutoError(String? message) async {
    if (message == null || message.isEmpty) {
      await _db.removeSetting(_kAutoError);
    } else {
      await _db.setSetting(_kAutoError, message);
    }
  }

  /// 设备 id 只生成一次，写进同步文件，方便在 git log 里认来源。
  Future<String> deviceId() async {
    final existing = await _db.getSetting(_kDevice);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = newDeviceId();
    await _db.setSetting(_kDevice, created);
    return created;
  }

  Future<String?> readToken() async {
    try {
      final value = await _storage.read(key: _keychainKey);
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // 钥匙串不可用，走回退
    }
    return _db.getSetting('$_keychainKey.fallback');
  }

  Future<void> writeToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      try {
        await _storage.delete(key: _keychainKey);
      } catch (_) {}
      await _db.removeSetting('$_keychainKey.fallback');
      return;
    }
    try {
      await _storage.write(key: _keychainKey, value: trimmed);
      await _db.removeSetting('$_keychainKey.fallback');
    } catch (_) {
      await _db.setSetting('$_keychainKey.fallback', trimmed);
    }
  }
}

/// 同步文件在仓库里的路径。放在固定目录下，将来要放别的东西也好扩展。
const String kSyncPath = 'mopu/library.json';

/// 冲突时怎么处理。
enum ConflictResolution {
  keepLocal('用我的'),
  keepRemote('用远端的'),
  keepBoth('两个都留');

  const ConflictResolution(this.label);
  final String label;
}

/// 一本书在两边都改过。
class SyncConflict {
  const SyncConflict({
    required this.syncId,
    required this.title,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
  });

  final String syncId;
  final String title;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;

  Map<String, dynamic> toJson() => {
        'syncId': syncId,
        'title': title,
        'local': localUpdatedAt.toUtc().toIso8601String(),
        'remote': remoteUpdatedAt.toUtc().toIso8601String(),
      };

  static SyncConflict fromJson(Map<String, dynamic> json) => SyncConflict(
        syncId: '${json['syncId'] ?? ''}',
        title: '${json['title'] ?? ''}',
        localUpdatedAt: DateTime.tryParse('${json['local']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
        remoteUpdatedAt: DateTime.tryParse('${json['remote']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// 同步结果，直接拿去展示。
class SyncOutcome {
  const SyncOutcome({
    required this.created,
    required this.updated,
    required this.removed,
    required this.skipped,
    required this.pushed,
    required this.branch,
    required this.commitSha,
    required this.at,
    required this.notes,
    this.conflicts = const [],
  });

  final List<String> created;
  final List<String> updated;

  /// 别人删了、本地跟着删的
  final List<String> removed;
  final List<String> skipped;
  final bool pushed;
  final String branch;
  final String? commitSha;
  final DateTime at;
  final List<String> notes;

  /// 非空表示「两边都改过」，还没动数据，等用户选
  final List<SyncConflict> conflicts;

  bool get needsDecision => conflicts.isNotEmpty;

  bool get changedAnything =>
      created.isNotEmpty || updated.isNotEmpty || removed.isNotEmpty || pushed;

  String get summary {
    final parts = <String>[];
    if (created.isNotEmpty) parts.add('拉取新项目 ${created.length}');
    if (updated.isNotEmpty) parts.add('更新 ${updated.length}');
    if (removed.isNotEmpty) parts.add('删除 ${removed.length}');
    if (skipped.isNotEmpty) parts.add('本地较新 ${skipped.length}');
    if (pushed) {
      parts.add('已推送');
    } else if (parts.isEmpty) {
      parts.add('已是最新');
    }
    return parts.join(' · ');
  }

  String encode() => jsonEncode({
        'created': created,
        'updated': updated,
        'removed': removed,
        'skipped': skipped,
        'pushed': pushed,
        'branch': branch,
        'commitSha': commitSha,
        'at': at.toUtc().toIso8601String(),
        'notes': notes,
        if (conflicts.isNotEmpty) 'conflicts': [for (final c in conflicts) c.toJson()],
      });

  static SyncOutcome? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      List<String> list(String key) => [
            for (final item in (json[key] as List? ?? [])) '$item',
          ];
      return SyncOutcome(
        created: list('created'),
        updated: list('updated'),
        removed: list('removed'),
        skipped: list('skipped'),
        pushed: json['pushed'] == true,
        branch: '${json['branch'] ?? 'main'}',
        commitSha: json['commitSha'] as String?,
        at: DateTime.tryParse('${json['at']}') ?? DateTime.now(),
        notes: list('notes'),
        conflicts: [
          for (final raw in (json['conflicts'] as List? ?? []))
            if (raw is Map) SyncConflict.fromJson(raw.cast<String, dynamic>()),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}
