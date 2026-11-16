import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mopu/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('删除先进回收站：书架看不到，回收站看得到', () async {
    final id = await db.createProject(title: '听雨录');
    final before = await db.watchProjects().first;
    expect(before.length, 1);

    await db.deleteProject(id);

    expect(await db.watchProjects().first, isEmpty);
    final trash = await db.trashedProjects();
    expect(trash.length, 1);
    expect(trash.first.title, '听雨录');
    // 数据还在
    expect((await db.chaptersOf(id)).length, 0);
  });

  test('恢复之后回到书架', () async {
    final id = await db.createProject(title: '听雨录');
    await db.createChapter(projectId: id, title: '第一章', body: '雨。');
    await db.deleteProject(id);
    expect(await db.watchProjects().first, isEmpty);

    await db.restoreProject(id);
    final shelf = await db.watchProjects().first;
    expect(shelf.length, 1);
    expect((await db.chaptersOf(shelf.first.id)).length, 1);
  });

  test('软删除会抬 updatedAt，这样同步时删得掉', () async {
    final id = await db.createProject(title: '听雨录');
    final before = (await db.getProject(id))!;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await db.deleteProject(id);
    final after = (await db.getProject(id))!;
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
    expect(after.deletedAt, isNotNull);
  });

  test('超过 30 天自动彻底删除，并留下墓碑', () async {
    final id = await db.createProject(title: '很久以前的书');
    // 手动把删除时间改到 31 天前
    await (db.update(db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        deletedAt: Value(DateTime.now().subtract(const Duration(days: 31))),
      ),
    );

    final removed = await db.purgeExpiredTrash(deviceId: 'dev-a');
    expect(removed, 1);
    expect(await db.getProject(id), isNull);
    expect((await db.trashedProjects()), isEmpty);

    final tombstones = await db.allTombstones();
    expect(tombstones.length, 1);
    expect(tombstones.first.title, '很久以前的书');
    expect(tombstones.first.deviceId, 'dev-a');
  });

  test('没到期的不会被清理', () async {
    final id = await db.createProject(title: '刚删的书');
    await db.deleteProject(id);
    final removed = await db.purgeExpiredTrash(deviceId: 'dev-a');
    expect(removed, 0);
    expect((await db.trashedProjects()).length, 1);
  });
}
