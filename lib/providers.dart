import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../domain/lint/lint_engine.dart';
import '../domain/llm/ai_settings_store.dart';
import '../domain/llm/llm_client.dart';
import '../domain/text/entity_matcher.dart';

/// 由 main() 覆盖为真实实例，避免重复打开数据库。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final projectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(databaseProvider).watchProjects();
});

final trashProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(databaseProvider).watchTrash();
});

final projectProvider = StreamProvider.family<Project?, int>((ref, id) {
  return ref.watch(databaseProvider).watchProjects().map((list) {
    for (final project in list) {
      if (project.id == id) return project;
    }
    return null;
  });
});

final chaptersProvider = StreamProvider.family<List<Chapter>, int>((ref, pid) {
  return ref.watch(databaseProvider).watchChapters(pid);
});

final chapterProvider = StreamProvider.family<Chapter, int>((ref, cid) {
  return ref.watch(databaseProvider).watchChapter(cid);
});

final entitiesProvider = StreamProvider.family<List<Entity>, int>((ref, pid) {
  return ref.watch(databaseProvider).watchEntities(pid);
});

final entityProvider = StreamProvider.family<Entity, int>((ref, eid) {
  return ref.watch(databaseProvider).watchEntity(eid);
});

final relationsProvider = StreamProvider.family<List<Relation>, int>((ref, pid) {
  return ref.watch(databaseProvider).watchRelations(pid);
});

final foreshadowsProvider = StreamProvider.family<List<Foreshadow>, int>((ref, pid) {
  return ref.watch(databaseProvider).watchForeshadows(pid);
});

final mentionsProvider = StreamProvider.family<List<Mention>, int>((ref, pid) {
  return ref.watch(databaseProvider).watchAllMentions(pid);
});

final mentionCountsProvider = FutureProvider.family<Map<int, int>, int>((ref, pid) async {
  ref.watch(mentionsProvider(pid));
  return ref.watch(databaseProvider).mentionCounts(pid);
});

final statsProvider = FutureProvider.family<ProjectStats, int>((ref, pid) async {
  // 依赖三张表，任何一张变化都要重算
  ref.watch(chaptersProvider(pid));
  ref.watch(entitiesProvider(pid));
  ref.watch(relationsProvider(pid));
  ref.watch(foreshadowsProvider(pid));
  return ref.watch(databaseProvider).statsOf(pid);
});

final lintProvider = FutureProvider.family<LintReport, int>((ref, pid) async {
  final chapters = await ref.watch(chaptersProvider(pid).future);
  final entities = await ref.watch(entitiesProvider(pid).future);
  final relations = await ref.watch(relationsProvider(pid).future);
  final mentions = await ref.watch(mentionsProvider(pid).future);
  final foreshadows = await ref.watch(foreshadowsProvider(pid).future);
  return LintEngine.analyse(
    chapters: chapters,
    entities: entities,
    relations: relations,
    mentions: mentions,
    foreshadows: foreshadows,
  );
});

/// 每本书一个匹配器，实体表变了才重建。
final matcherProvider = Provider.family<EntityMatcher, int>((ref, pid) {
  final entities = ref.watch(entitiesProvider(pid)).value ?? const <Entity>[];
  return EntityMatcher(entities);
});

// ───────────────────────────── 设置 ─────────────────────────────

/// 书架上的同步状态。用设置表的流驱动，同步完自动刷新。
class SyncStatus {
  const SyncStatus({
    required this.configured,
    required this.autoDaily,
    this.lastSyncAt,
    this.lastError,
  });

  final bool configured;
  final bool autoDaily;
  final DateTime? lastSyncAt;
  final String? lastError;

  static const unknown = SyncStatus(configured: false, autoDaily: true);

  bool get hasError => lastError != null && lastError!.isNotEmpty;
}

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSettings().map((rows) {
    final map = {for (final row in rows) row.key: row.value};
    final repo = map['sync.repository'] ?? '';
    return SyncStatus(
      configured: repo.trim().isNotEmpty,
      autoDaily: map['sync.autoDaily'] != '0',
      lastSyncAt: DateTime.tryParse(map['sync.lastAt'] ?? ''),
      lastError: map['sync.lastAutoError'],
    );
  });
});

final aiStoreProvider = Provider<AiSettingsStore>((ref) {
  return AiSettingsStore(ref.watch(databaseProvider));
});

class AiConfigState {
  const AiConfigState({required this.enabled, required this.config});
  final bool enabled;
  final LlmConfig config;

  AiConfigState copyWith({bool? enabled, LlmConfig? config}) =>
      AiConfigState(enabled: enabled ?? this.enabled, config: config ?? this.config);
}

class AiConfigNotifier extends AsyncNotifier<AiConfigState> {
  @override
  Future<AiConfigState> build() async {
    final store = ref.watch(aiStoreProvider);
    return AiConfigState(
      enabled: await store.isEnabled(),
      config: await store.load(),
    );
  }

  Future<void> save(AiConfigState next) async {
    final store = ref.read(aiStoreProvider);
    await store.save(enabled: next.enabled, config: next.config);
    ref.invalidateSelf();
    await future;
  }
}

final aiConfigProvider = AsyncNotifierProvider<AiConfigNotifier, AiConfigState>(AiConfigNotifier.new);

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  static const _key = 'ui.themeMode';

  @override
  Future<ThemeMode> build() async {
    final raw = await ref.watch(databaseProvider).getSetting(_key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    await ref.read(databaseProvider).setSetting(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    state = AsyncData(mode);
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
