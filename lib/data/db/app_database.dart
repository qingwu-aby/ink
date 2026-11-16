import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/utils/ids.dart';
import '../../domain/search/paragraph_splitter.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// 一条正文检索结果。
class ParagraphHit {
  const ParagraphHit({
    required this.paragraphId,
    required this.chapterId,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.start,
    required this.end,
    required this.content,
  });

  final int paragraphId;
  final int chapterId;
  final int chapterIndex;
  final String chapterTitle;

  /// 段落在章节正文里的区间，用来跳回原文
  final int start;
  final int end;
  final String content;
}

/// 一次提及（正文里的实体出现位置）。
class MentionSpan {
  const MentionSpan({
    required this.entityId,
    required this.start,
    required this.end,
    required this.surface,
  });

  final int entityId;
  final int start;
  final int end;
  final String surface;
}

/// 书架卡片用的汇总数字。
class ProjectStats {
  const ProjectStats({
    required this.entityCount,
    required this.relationCount,
    required this.chapterCount,
    required this.wordCount,
    required this.openForeshadows,
    required this.kindCounts,
    required this.lastChapterIndex,
  });

  final int entityCount;
  final int relationCount;
  final int chapterCount;
  final int wordCount;
  final int openForeshadows;
  final Map<String, int> kindCounts;
  final int lastChapterIndex;

  static const empty = ProjectStats(
    entityCount: 0,
    relationCount: 0,
    chapterCount: 0,
    wordCount: 0,
    openForeshadows: 0,
    kindCounts: {},
    lastChapterIndex: 0,
  );
}

@DriftDatabase(
  tables: [
    Projects,
    Chapters,
    Entities,
    Relations,
    Mentions,
    Events,
    Foreshadows,
    Paragraphs,
    ProjectTombstones,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'mopu'));

  /// 测试用：传内存数据库。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2：给项目加跨设备标识，老数据补号。
          //
          // 注意：SQLite 不允许 ALTER TABLE 直接加 UNIQUE 列，
          // 所以这里加普通列 + 唯一索引（新建库仍走表定义里的 UNIQUE）。
          if (from < 2) {
            try {
              await customStatement('ALTER TABLE "projects" ADD COLUMN "sync_id" TEXT');
            } catch (_) {
              // 列已存在（上次迁移中断过），继续往后走
            }
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_projects_sync_id ON "projects" ("sync_id")',
            );
            await ensureSyncIds();
          }
          // v3：删除墓碑，让删除也能跨设备传播
          if (from < 3) {
            await m.createTable(projectTombstones);
          }
          // v4：回收站（软删除）+ 墓碑记设备
          if (from == 3) {
            await m.addColumn(projectTombstones, projectTombstones.deviceId);
          }
          if (from < 4) {
            await m.addColumn(projects, projects.deletedAt);
          }
          // v5：段落索引（正文检索 + 按实体聚合段落）
          if (from < 5) {
            await m.createTable(paragraphs);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ───────────────────────────── 项目 ─────────────────────────────

  Stream<List<Project>> watchProjects() => (select(projects)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
      .watch();

  Future<Project?> getProject(int id) =>
      (select(projects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createProject({
    required String title,
    String genre = '',
    String synopsis = '',
    int wordGoal = 0,
  }) =>
      into(projects).insert(
        ProjectsCompanion.insert(
          syncId: Value(newSyncId()),
          title: title,
          genre: Value(genre),
          synopsis: Value(synopsis),
          wordGoal: Value(wordGoal),
        ),
        mode: InsertMode.insertOrReplace,
      );

  Future<void> updateProject(Project row) =>
      (update(projects)..where((t) => t.id.equals(row.id))).write(
        row.copyWith(updatedAt: DateTime.now()),
      );

  Future<void> touchProject(int id) => (update(projects)..where((t) => t.id.equals(id)))
      .write(ProjectsCompanion(updatedAt: Value(DateTime.now())));

  /// 移到回收站：数据还在，30 天内可以恢复。
  ///
  /// 同时抬一次 updatedAt，这样「删除」在项目级合并里能胜过别处的旧版本。
  Future<void> deleteProject(int id) =>
      (update(projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> restoreProject(int id) =>
      (update(projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Stream<List<Project>> watchTrash() => (select(projects)
        ..where((t) => t.deletedAt.isNotNull())
        ..orderBy([
          (t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc),
        ]))
      .watch();

  Future<List<Project>> trashedProjects() => (select(projects)
        ..where((t) => t.deletedAt.isNotNull())
        ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]))
      .get();

  /// 彻底删除：从库里抹掉，并留下墓碑，避免别的设备把它推回来。
  Future<void> purgeProject(int id, {String deviceId = ''}) async {
    final project = await getProject(id);
    await (delete(projects)..where((t) => t.id.equals(id))).go();
    final syncId = project?.syncId;
    if (syncId != null && syncId.isNotEmpty) {
      await into(projectTombstones).insertOnConflictUpdate(
        ProjectTombstonesCompanion.insert(
          syncId: syncId,
          title: Value(project?.title ?? ''),
          deviceId: Value(deviceId),
          deletedAt: DateTime.now(),
        ),
      );
    }
  }

  /// 回收站到期清理：超过 [days] 天的自动彻底删除（并留墓碑）。
  Future<int> purgeExpiredTrash({int days = 30, String deviceId = ''}) async {
    final deadline = DateTime.now().subtract(Duration(days: days));
    final expired = await (select(projects)
          ..where((t) => t.deletedAt.isNotNull() & t.deletedAt.isSmallerThanValue(deadline)))
        .get();
    for (final project in expired) {
      await purgeProject(project.id, deviceId: deviceId);
    }
    return expired.length;
  }

  /// 同步内部用：只删行，不再写墓碑（墓碑已经在同步文件里了）。
  Future<void> deleteProjectRow(int id) =>
      (delete(projects)..where((t) => t.id.equals(id))).go();

  Future<void> removeTombstone(String syncId) =>
      (delete(projectTombstones)..where((t) => t.syncId.equals(syncId))).go();

  Future<List<ProjectTombstone>> allTombstones() =>
      (select(projectTombstones)..orderBy([(t) => OrderingTerm(expression: t.deletedAt)]))
          .get();

  Future<ProjectTombstone?> tombstoneOf(String syncId) =>
      (select(projectTombstones)..where((t) => t.syncId.equals(syncId))).getSingleOrNull();

  Future<void> recordTombstone({
    required String syncId,
    required String title,
    required DateTime deletedAt,
  }) async {
    final existing = await tombstoneOf(syncId);
    if (existing != null && existing.deletedAt.isAfter(deletedAt)) return;
    await into(projectTombstones).insertOnConflictUpdate(
      ProjectTombstonesCompanion.insert(
        syncId: syncId,
        title: Value(title),
        deletedAt: deletedAt,
      ),
    );
  }

  /// 清掉过期墓碑，避免仓库里的同步文件无限长大。
  Future<int> pruneTombstones({required DateTime before}) =>
      (delete(projectTombstones)..where((t) => t.deletedAt.isSmallerThanValue(before))).go();

  Future<List<Project>> allProjects() =>
      (select(projects)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();

  /// 老数据（或从别处导入的数据）没有 syncId 时补一个。
  Future<void> ensureSyncIds() async {
    final missing = await (select(projects)
          ..where((t) => t.syncId.isNull()))
        .get();
    for (final project in missing) {
      await (update(projects)..where((t) => t.id.equals(project.id)))
          .write(ProjectsCompanion(syncId: Value(newSyncId())));
    }
  }

  Future<Project?> projectBySyncId(String syncId) =>
      (select(projects)..where((t) => t.syncId.equals(syncId))).getSingleOrNull();

  Future<List<StoryEvent>> eventsOf(int projectId) =>
      (select(events)..where((t) => t.projectId.equals(projectId))).get();

  // ───────────────────────────── 章节 ─────────────────────────────

  Stream<List<Chapter>> watchChapters(int projectId) => (select(chapters)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm(expression: t.index)]))
      .watch();

  Future<Chapter?> getChapter(int id) =>
      (select(chapters)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Chapter> watchChapter(int id) =>
      (select(chapters)..where((t) => t.id.equals(id))).watchSingle();

  Future<int> nextChapterIndex(int projectId) async {
    final row = await customSelect(
      'SELECT COALESCE(MAX("index"), 0) AS idx FROM chapters WHERE project_id = ?',
      variables: [Variable.withInt(projectId)],
      readsFrom: {chapters},
    ).getSingle();
    return (row.read<int?>('idx') ?? 0) + 1;
  }

  Future<int> createChapter({
    required int projectId,
    required String title,
    String body = '',
  }) async {
    final index = await nextChapterIndex(projectId);
    final chapterId = await into(chapters).insert(
      ChaptersCompanion.insert(
        projectId: projectId,
        index: index,
        title: Value(title),
        body: Value(body),
        wordCount: Value(_count(body)),
      ),
    );
    await touchProject(projectId);
    return chapterId;
  }

  Future<void> saveChapterBody(int id, String body) =>
      (update(chapters)..where((t) => t.id.equals(id))).write(
        ChaptersCompanion(
          body: Value(body),
          wordCount: Value(_count(body)),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateChapterMeta(
    int id, {
    String? title,
    String? status,
    String? note,
  }) =>
      (update(chapters)..where((t) => t.id.equals(id))).write(
        ChaptersCompanion(
          title: title == null ? const Value.absent() : Value(title),
          status: status == null ? const Value.absent() : Value(status),
          note: note == null ? const Value.absent() : Value(note),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteChapter(int id) =>
      (delete(chapters)..where((t) => t.id.equals(id))).go();

  Future<List<Chapter>> chaptersOf(int projectId) => (select(chapters)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm(expression: t.index)]))
      .get();

  static int _count(String text) {
    if (text.isEmpty) return 0;
    final cjk = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]').allMatches(text).length;
    final latin = RegExp(r"[A-Za-z0-9][A-Za-z0-9'\-]*").allMatches(text).length;
    return cjk + latin;
  }

  // ───────────────────────────── 实体 ─────────────────────────────

  Stream<List<Entity>> watchEntities(int projectId) => (select(entities)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.importance, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.name),
        ]))
      .watch();

  Future<List<Entity>> entitiesOf(int projectId) =>
      (select(entities)..where((t) => t.projectId.equals(projectId))).get();

  Future<Entity?> getEntity(int id) =>
      (select(entities)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Entity> watchEntity(int id) =>
      (select(entities)..where((t) => t.id.equals(id))).watchSingle();

  Future<int> createEntity({
    required int projectId,
    required String name,
    String kind = 'character',
    List<String> aliases = const [],
    String summary = '',
    int importance = 3,
    String status = 'alive',
    int? deathChapter,
  }) =>
      into(entities).insert(
        EntitiesCompanion.insert(
          projectId: projectId,
          name: name,
          kind: Value(kind),
          aliases: Value(_jsonList(aliases)),
          summary: Value(summary),
          importance: Value(importance),
          status: Value(status),
          deathChapter: Value(deathChapter),
        ),
      );

  Future<void> updateEntity(Entity row) =>
      (update(entities)..where((t) => t.id.equals(row.id))).write(
        row.copyWith(updatedAt: DateTime.now()),
      );

  Future<void> deleteEntity(int id) =>
      (delete(entities)..where((t) => t.id.equals(id))).go();

  Future<List<Entity>> searchEntities(int projectId, String query) async {
    final like = '%${query.replaceAll('%', '')}%';
    final rows = await customSelect(
      'SELECT * FROM entities WHERE project_id = ?1 AND (name LIKE ?2 OR aliases LIKE ?2 OR summary LIKE ?2) LIMIT 40',
      variables: [Variable.withInt(projectId), Variable.withString(like)],
      readsFrom: {entities},
    ).get();
    return Future.wait(rows.map((row) => entities.mapFromRow(row)));
  }

  /// 图谱要用的实体度（出现次数）统计。
  Future<Map<int, int>> mentionCounts(int projectId) async {
    final rows = await customSelect(
      '''SELECT m.entity_id AS eid, COUNT(*) AS c FROM mentions m
         JOIN chapters c ON c.id = m.chapter_id
         WHERE c.project_id = ? GROUP BY m.entity_id''',
      variables: [Variable.withInt(projectId)],
      readsFrom: {mentions, chapters},
    ).get();
    return {for (final r in rows) r.read<int>('eid'): r.read<int>('c')};
  }

  // ───────────────────────────── 关系 ─────────────────────────────

  Stream<List<Relation>> watchRelations(int projectId) =>
      (select(relations)..where((t) => t.projectId.equals(projectId))).watch();

  Future<List<Relation>> relationsOf(int projectId) =>
      (select(relations)..where((t) => t.projectId.equals(projectId))).get();

  Future<List<Relation>> relationsTouching(int entityId) => (select(relations)
        ..where((t) => t.fromId.equals(entityId) | t.toId.equals(entityId)))
      .get();

  Future<int> upsertRelation({
    int? id,
    required int projectId,
    required int fromId,
    required int toId,
    String kind = 'other',
    int strength = 3,
    String note = '',
    int validFrom = 1,
    int? validTo,
  }) async {
    if (id == null) {
      return into(relations).insert(
        RelationsCompanion.insert(
          projectId: projectId,
          fromId: fromId,
          toId: toId,
          kind: Value(kind),
          strength: Value(strength),
          note: Value(note),
          validFrom: Value(validFrom),
          validTo: Value(validTo),
        ),
      );
    }
    await (update(relations)..where((t) => t.id.equals(id))).write(
      RelationsCompanion(
        kind: Value(kind),
        strength: Value(strength),
        note: Value(note),
        validFrom: Value(validFrom),
        validTo: Value(validTo),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  Future<void> deleteRelation(int id) =>
      (delete(relations)..where((t) => t.id.equals(id))).go();

  // ───────────────────────────── 提及 ─────────────────────────────

  Stream<List<Mention>> watchMentionsOfChapter(int chapterId) => (select(mentions)
        ..where((t) => t.chapterId.equals(chapterId)))
      .watch();

  Future<List<Mention>> mentionsOfChapter(int chapterId) => (select(mentions)
        ..where((t) => t.chapterId.equals(chapterId)))
      .get();

  Future<List<Mention>> allMentions(int projectId) async {
    final rows = await customSelect(
      '''SELECT m.* FROM mentions m JOIN chapters c ON c.id = m.chapter_id
         WHERE c.project_id = ?''',
      variables: [Variable.withInt(projectId)],
      readsFrom: {mentions, chapters},
    ).get();
    return Future.wait(rows.map((row) => mentions.mapFromRow(row)));
  }

  Stream<List<Mention>> watchAllMentions(int projectId) => customSelect(
        '''SELECT m.* FROM mentions m JOIN chapters c ON c.id = m.chapter_id
           WHERE c.project_id = ?''',
        variables: [Variable.withInt(projectId)],
        readsFrom: {mentions, chapters},
      ).watch().asyncMap(
        (rows) => Future.wait(rows.map((row) => mentions.mapFromRow(row))),
      );

  /// 全文重建某一章的提及（保存时调用）。
  Future<void> replaceMentions(int chapterId, List<MentionSpan> spans) async {
    await transaction(() async {
      await (delete(mentions)..where((t) => t.chapterId.equals(chapterId))).go();
      if (spans.isEmpty) return;
      await batch((b) => b.insertAll(
            mentions,
            spans.map((s) => MentionsCompanion.insert(
                  chapterId: chapterId,
                  entityId: s.entityId,
                  start: s.start,
                  end: s.end,
                  surface: Value(s.surface),
                )),
          ));
    });
  }

  // ───────────────────────────── 段落索引 ─────────────────────────────

  /// 重建某一章的段落索引（保存正文后调用）。
  Future<void> reindexParagraphs({
    required int chapterId,
    required int projectId,
    required String body,
  }) async {
    final drafts = splitParagraphs(body);
    await transaction(() async {
      await (delete(paragraphs)..where((t) => t.chapterId.equals(chapterId))).go();
      if (drafts.isEmpty) return;
      await batch((b) => b.insertAll(
            paragraphs,
            drafts.map((draft) => ParagraphsCompanion.insert(
                  chapterId: chapterId,
                  projectId: projectId,
                  index: draft.index,
                  start: draft.start,
                  end: draft.end,
                  content: draft.text,
                )),
          ));
    });
  }

  /// 老库或同步导入的章节补建索引。
  Future<int> backfillParagraphs() async {
    final rows = await customSelect(
      'SELECT id, project_id, body FROM chapters '
      'WHERE id NOT IN (SELECT DISTINCT chapter_id FROM paragraphs)',
      readsFrom: {chapters, paragraphs},
    ).get();
    for (final row in rows) {
      await reindexParagraphs(
        chapterId: row.read<int>('id'),
        projectId: row.read<int>('project_id'),
        body: row.read<String>('body'),
      );
    }
    return rows.length;
  }

  /// 正文检索。[entityId] 非空时只在该实体出现过的段落里找。
  Future<List<ParagraphHit>> searchParagraphs(
    int projectId,
    String query, {
    int? entityId,
    int limit = 200,
  }) async {
    final keyword = query.trim();
    if (keyword.isEmpty && entityId == null) return const [];

    final variables = <Variable>[Variable.withInt(projectId)];
    var entityJoin = '';
    if (entityId != null) {
      entityJoin = 'JOIN mentions m ON m.chapter_id = p.chapter_id '
          'AND m.entity_id = ? AND m.start >= p.start AND m.end <= p.end';
      variables.add(Variable.withInt(entityId));
    }
    var keywordFilter = '';
    if (keyword.isNotEmpty) {
      keywordFilter = "AND p.content LIKE ? ESCAPE '\\' ";
      variables.add(Variable.withString('%${_escapeLike(keyword)}%'));
    }
    variables.add(Variable.withInt(limit));

    final rows = await customSelect(
      'SELECT DISTINCT p.id AS pid, p.chapter_id AS cid, p.start AS pstart, p.end AS pend, '
      'p.content AS pcontent, c."index" AS cindex, c.title AS ctitle '
      'FROM paragraphs p JOIN chapters c ON c.id = p.chapter_id $entityJoin '
      'WHERE p.project_id = ? $keywordFilter'
      'ORDER BY c."index", p."index" LIMIT ?',
      variables: variables,
      readsFrom: {paragraphs, chapters, mentions},
    ).get();

    return [
      for (final row in rows)
        ParagraphHit(
          paragraphId: row.read<int>('pid'),
          chapterId: row.read<int>('cid'),
          chapterIndex: row.read<int>('cindex'),
          chapterTitle: row.read<String>('ctitle'),
          start: row.read<int>('pstart'),
          end: row.read<int>('pend'),
          content: row.read<String>('pcontent'),
        ),
    ];
  }

  /// 某个实体出现过的所有段落（按章节、段落顺序）。
  Future<List<ParagraphHit>> paragraphsForEntity(int projectId, int entityId, {int limit = 400}) =>
      searchParagraphs(projectId, '', entityId: entityId, limit: limit);

  static String _escapeLike(String raw) => raw
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  // ───────────────────────────── 伏笔 ─────────────────────────────

  Stream<List<Foreshadow>> watchForeshadows(int projectId) => (select(foreshadows)
        ..where((t) => t.projectId.equals(projectId)))
      .watch();

  Future<List<Foreshadow>> foreshadowsOf(int projectId) =>
      (select(foreshadows)..where((t) => t.projectId.equals(projectId))).get();

  Future<int> createForeshadow({
    required int projectId,
    required String hook,
    int plantedChapter = 1,
    int? resolvedChapter,
    String note = '',
  }) =>
      into(foreshadows).insert(
        ForeshadowsCompanion.insert(
          projectId: projectId,
          hook: hook,
          plantedChapter: Value(plantedChapter),
          resolvedChapter: Value(resolvedChapter),
          note: Value(note),
        ),
      );

  Future<void> resolveForeshadow(int id, int chapter) =>
      (update(foreshadows)..where((t) => t.id.equals(id))).write(
        ForeshadowsCompanion(resolvedChapter: Value(chapter)),
      );

  Future<void> deleteForeshadow(int id) =>
      (delete(foreshadows)..where((t) => t.id.equals(id))).go();

  // ───────────────────────────── 图谱 ─────────────────────────────

  /// 以 [entityId] 为中心取 [depth] 跳邻居（递归 CTE）。
  Future<List<Entity>> egoNeighbours(int projectId, int entityId, int depth) async {
    final rows = await customSelect(
        '''WITH RECURSIVE reach(eid, d) AS (
             SELECT ?1, 0
             UNION
             SELECT CASE WHEN r.from_id = reach.eid THEN r.to_id ELSE r.from_id END, reach.d + 1
             FROM relations r JOIN reach
               ON (r.from_id = reach.eid OR r.to_id = reach.eid)
             WHERE r.project_id = ?2 AND reach.d < ?3
           )
           SELECT DISTINCT e.* FROM entities e JOIN reach ON e.id = reach.eid''',
        variables: [
          Variable.withInt(entityId),
          Variable.withInt(projectId),
          Variable.withInt(depth),
        ],
        readsFrom: {relations, entities},
      ).get();
    return Future.wait(rows.map((row) => entities.mapFromRow(row)));
  }

  // ───────────────────────────── 统计 ─────────────────────────────

  Future<ProjectStats> statsOf(int projectId) async {
    final kindRows = await customSelect(
      'SELECT kind, COUNT(*) AS c FROM entities WHERE project_id = ? GROUP BY kind',
      variables: [Variable.withInt(projectId)],
      readsFrom: {entities},
    ).get();
    final kindCounts = <String, int>{
      for (final r in kindRows) r.read<String>('kind'): r.read<int>('c'),
    };

    final relRow = await customSelect(
      'SELECT COUNT(*) AS c FROM relations WHERE project_id = ?',
      variables: [Variable.withInt(projectId)],
      readsFrom: {relations},
    ).getSingle();
    final chRow = await customSelect(
      'SELECT COUNT(*) AS c, COALESCE(SUM(word_count), 0) AS w, COALESCE(MAX("index"), 0) AS mx FROM chapters WHERE project_id = ?',
      variables: [Variable.withInt(projectId)],
      readsFrom: {chapters},
    ).getSingle();
    final fsRow = await customSelect(
      'SELECT COUNT(*) AS c FROM foreshadows WHERE project_id = ? AND resolved_chapter IS NULL',
      variables: [Variable.withInt(projectId)],
      readsFrom: {foreshadows},
    ).getSingle();

    return ProjectStats(
      entityCount: kindCounts.values.fold(0, (a, b) => a + b),
      relationCount: relRow.read<int>('c'),
      chapterCount: chRow.read<int>('c'),
      wordCount: chRow.read<int>('w'),
      openForeshadows: fsRow.read<int>('c'),
      kindCounts: kindCounts,
      lastChapterIndex: chRow.read<int>('mx'),
    );
  }

  // ───────────────────────────── 设置 ─────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) => into(settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: Value(value)),
      );

  Stream<List<AppSetting>> watchAllSettings() =>
      (select(settings)..orderBy([(t) => OrderingTerm(expression: t.key)])).watch();

  Future<void> removeSetting(String key) =>
      (delete(settings)..where((t) => t.key.equals(key))).go();

  static String _jsonList(List<String> values) => jsonEncode(
        values.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList(),
      );
}
