import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/utils/text_utils.dart';
import '../../data/db/app_database.dart';
import '../text/entity_matcher.dart';
import 'library_codec.dart';

/// 导入结果，用来在界面上说清楚"到底同步了什么"。
class ImportOutcome {
  const ImportOutcome({
    required this.created,
    required this.updated,
    required this.removed,
    required this.skipped,
    required this.notes,
  });

  final List<String> created;
  final List<String> updated;

  /// 因为别人删了，本地跟着删掉的
  final List<String> removed;
  final List<String> skipped;
  final List<String> notes;

  static const empty =
      ImportOutcome(created: [], updated: [], removed: [], skipped: [], notes: []);

  bool get changed => created.isNotEmpty || updated.isNotEmpty || removed.isNotEmpty;
}

/// 把本地书库导出成一份可同步的快照。
Future<LibraryBundle> exportLibrary(
  AppDatabase db, {
  required String deviceId,
  DateTime? now,
}) async {
  await db.ensureSyncIds();
  final projects = await db.allProjects();
  final bundles = <ProjectBundle>[];

  // 一年前的删除记录不再携带：再久的设备离线回来，也认不出那本书了
  final cutoff = (now ?? DateTime.now()).toUtc().subtract(const Duration(days: 365));
  final tombstones = [
    for (final tombstone in await db.allTombstones())
      if (tombstone.deletedAt.toUtc().isAfter(cutoff))
        TombstoneBundle(
          syncId: tombstone.syncId,
          title: tombstone.title,
          deviceId: tombstone.deviceId,
          deletedAt: tombstone.deletedAt,
        ),
  ];

  for (final project in projects) {
    final entities = await db.entitiesOf(project.id);
    final relations = await db.relationsOf(project.id);
    final chapters = await db.chaptersOf(project.id);
    final foreshadows = await db.foreshadowsOf(project.id);
    final byId = {for (final entity in entities) entity.id: entity};

    bundles.add(ProjectBundle(
      syncId: project.syncId ?? '',
      title: project.title,
      genre: project.genre,
      synopsis: project.synopsis,
      wordGoal: project.wordGoal,
      updatedAt: project.updatedAt,
      chapters: [
        for (final chapter in chapters)
          ChapterBundle(
            index: chapter.index,
            title: chapter.title,
            body: chapter.body,
            status: chapter.status,
            note: chapter.note,
          ),
      ],
      entities: [
        for (final entity in entities)
          EntityBundle(
            name: entity.name,
            kind: entity.kind,
            aliases: parseStringList(entity.aliases),
            summary: entity.summary,
            importance: entity.importance,
            status: entity.status,
            deathChapter: entity.deathChapter,
          ),
      ],
      relations: [
        for (final relation in relations)
          if (byId[relation.fromId] != null && byId[relation.toId] != null)
            RelationBundle(
              from: byId[relation.fromId]!.name,
              to: byId[relation.toId]!.name,
              kind: relation.kind,
              strength: relation.strength,
              note: relation.note,
              validFrom: relation.validFrom,
              validTo: relation.validTo,
            ),
      ],
      deletedAt: project.deletedAt,
      foreshadows: [
        for (final item in foreshadows)
          ForeshadowBundle(
            hook: item.hook,
            plantedChapter: item.plantedChapter,
            resolvedChapter: item.resolvedChapter,
            note: item.note,
          ),
      ],
    ));
  }

  return LibraryBundle(
    projects: bundles,
    tombstones: tombstones,
    deviceId: deviceId,
    exportedAt: (now ?? DateTime.now()).toUtc(),
  );
}

/// 把远端快照并入本地：新项目直接建，旧项目按 updatedAt 比谁新。
/// 项目是同步的原子单位——这样合并规则简单到能一眼说清，也不会半本书半本地。
Future<ImportOutcome> importLibrary(AppDatabase db, LibraryBundle bundle) async {
  final created = <String>[];
  final updated = <String>[];
  final removed = <String>[];
  final skipped = <String>[];
  final notes = <String>[];

  // 第一步：把远端墓碑并进来（同一 syncId 取更晚的那个）
  for (final tombstone in bundle.tombstones) {
    if (tombstone.syncId.isEmpty) continue;
    await db.recordTombstone(
      syncId: tombstone.syncId,
      title: tombstone.title,
      deletedAt: tombstone.deletedAt,
    );
  }
  final tombstones = {for (final t in await db.allTombstones()) t.syncId: t};

  // 第二步：本地有、但别人删得比我改得晚 → 跟着删。
  // 反过来：我改得比删除晚 → 说明删除之后我还动过，保留，并清掉墓碑（复活）。
  for (final project in await db.allProjects()) {
    final syncId = project.syncId;
    if (syncId == null || syncId.isEmpty) continue;
    final tombstone = tombstones[syncId];
    if (tombstone == null) continue;
    if (project.updatedAt.isAfter(tombstone.deletedAt)) {
      await db.removeTombstone(syncId);
      tombstones.remove(syncId);
      notes.add('${project.title} 在删除之后又被改过，保留');
      continue;
    }
    await db.deleteProjectRow(project.id);
    removed.add(project.title);
  }

  // 第三步：合并远端项目；比墓碑旧的不再复活
  for (final remote in bundle.projects) {
    if (remote.syncId.isEmpty) {
      notes.add('跳过一个没有 syncId 的项目：${remote.title}');
      continue;
    }
    final tombstone = tombstones[remote.syncId];
    if (tombstone != null) {
      if (!remote.updatedAt.isAfter(tombstone.deletedAt)) {
        skipped.add(remote.title);
        continue;
      }
      // 远端比墓碑新：复活
      await db.removeTombstone(remote.syncId);
      tombstones.remove(remote.syncId);
    }

    final local = await db.projectBySyncId(remote.syncId);
    if (local == null) {
      await _insertProject(db, remote);
      created.add(remote.title);
      continue;
    }
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      await _overwriteProject(db, local.id, remote);
      updated.add(remote.title);
    } else {
      skipped.add(remote.title);
    }
  }

  return ImportOutcome(
    created: created,
    updated: updated,
    removed: removed,
    skipped: skipped,
    notes: notes,
  );
}

/// 冲突时选「用远端的」：不管时间戳，直接用远端覆盖本地。
Future<void> forcePullProject(AppDatabase db, ProjectBundle bundle) async {
  final local = await db.projectBySyncId(bundle.syncId);
  if (local == null) {
    await _insertProject(db, bundle);
    return;
  }
  await _overwriteProject(db, local.id, bundle);
}

/// 冲突时选「两个都留」：把远端那份存成一本新书，换一个 syncId。
Future<int> importProjectCopy(
  AppDatabase db,
  ProjectBundle bundle, {
  required String syncId,
  required String title,
}) {
  return _insertProject(
    db,
    ProjectBundle(
      syncId: syncId,
      title: title,
      genre: bundle.genre,
      synopsis: bundle.synopsis,
      wordGoal: bundle.wordGoal,
      updatedAt: bundle.updatedAt,
      deletedAt: bundle.deletedAt,
      chapters: bundle.chapters,
      entities: bundle.entities,
      relations: bundle.relations,
      foreshadows: bundle.foreshadows,
    ),
  );
}

Future<int> _insertProject(AppDatabase db, ProjectBundle bundle) async {
  return db.transaction(() async {
    final projectId = await db.into(db.projects).insert(
          ProjectsCompanion.insert(
            syncId: Value(bundle.syncId),
            title: bundle.title,
            genre: Value(bundle.genre),
            synopsis: Value(bundle.synopsis),
            wordGoal: Value(bundle.wordGoal),
            createdAt: Value(bundle.updatedAt),
            updatedAt: Value(bundle.updatedAt),
            deletedAt: Value(bundle.deletedAt),
          ),
        );
    await _writeChildren(db, projectId, bundle);
    return projectId;
  });
}

Future<void> _overwriteProject(AppDatabase db, int projectId, ProjectBundle bundle) async {
  await db.transaction(() async {
    await (db.update(db.projects)..where((t) => t.id.equals(projectId))).write(
      ProjectsCompanion(
        title: Value(bundle.title),
        genre: Value(bundle.genre),
        synopsis: Value(bundle.synopsis),
        wordGoal: Value(bundle.wordGoal),
        updatedAt: Value(bundle.updatedAt),
        deletedAt: Value(bundle.deletedAt),
      ),
    );
    // 先清空子表再重建，避免 id 对不上导致的错位
    await (db.delete(db.chapters)..where((t) => t.projectId.equals(projectId))).go();
    await (db.delete(db.entities)..where((t) => t.projectId.equals(projectId))).go();
    await (db.delete(db.foreshadows)..where((t) => t.projectId.equals(projectId))).go();
    await _writeChildren(db, projectId, bundle);
  });
}

Future<void> _writeChildren(AppDatabase db, int projectId, ProjectBundle bundle) async {
  final nameToId = <String, int>{};
  for (final entity in bundle.entities) {
    final name = entity.name.trim();
    if (name.isEmpty) continue;
    final id = await db.into(db.entities).insert(
          EntitiesCompanion.insert(
            projectId: projectId,
            name: name,
            kind: Value(entity.kind),
            aliases: Value(jsonEncode(entity.aliases)),
            summary: Value(entity.summary),
            importance: Value(entity.importance),
            status: Value(entity.status),
            deathChapter: Value(entity.deathChapter),
            updatedAt: Value(bundle.updatedAt),
          ),
        );
    nameToId[name] = id;
  }

  for (final relation in bundle.relations) {
    final fromId = nameToId[relation.from];
    final toId = nameToId[relation.to];
    // 名字对不上就跳过：不猜、不建半个关系
    if (fromId == null || toId == null || fromId == toId) continue;
    await db.into(db.relations).insert(
          RelationsCompanion.insert(
            projectId: projectId,
            fromId: fromId,
            toId: toId,
            kind: Value(relation.kind),
            strength: Value(relation.strength),
            note: Value(relation.note),
            validFrom: Value(relation.validFrom),
            validTo: Value(relation.validTo),
            updatedAt: Value(bundle.updatedAt),
          ),
        );
  }

  for (final item in bundle.foreshadows) {
    if (item.hook.trim().isEmpty) continue;
    await db.into(db.foreshadows).insert(
          ForeshadowsCompanion.insert(
            projectId: projectId,
            hook: item.hook,
            plantedChapter: Value(item.plantedChapter),
            resolvedChapter: Value(item.resolvedChapter),
            note: Value(item.note),
          ),
        );
  }

  // 正文实体用正文重新索引，不依赖同步过来的位置数据
  final entities = await db.entitiesOf(projectId);
  final matcher = entities.isEmpty ? null : EntityMatcher(entities);

  for (final chapter in bundle.chapters) {
    final chapterId = await db.into(db.chapters).insert(
          ChaptersCompanion.insert(
            projectId: projectId,
            index: chapter.index,
            title: Value(chapter.title),
            body: Value(chapter.body),
            status: Value(chapter.status),
            wordCount: Value(countWords(chapter.body)),
            note: Value(chapter.note),
            updatedAt: Value(bundle.updatedAt),
          ),
        );
    if (matcher != null) {
      await db.replaceMentions(chapterId, matcher.scan(chapter.body));
    }
    await db.reindexParagraphs(
      chapterId: chapterId,
      projectId: projectId,
      body: chapter.body,
    );
  }
}
