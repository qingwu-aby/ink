import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:kedao/data/db/app_database.dart';

/// 回归测试：v1 → v2 的迁移。
///
/// SQLite 不允许 `ALTER TABLE ADD COLUMN ... UNIQUE`，第一次写这段迁移就是这么挂的，
/// 所以这里用一个真实的旧库文件把升级路径跑一遍。
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mopu_migration_');
    dbFile = File('${tempDir.path}/mopu.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('老库升级后保留数据，并补上 syncId', () async {
    // 造一个 v1 的库：只有 projects 表，没有 sync_id
    final raw = sqlite3.open(dbFile.path);
    raw.execute('''
      CREATE TABLE projects (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        genre TEXT NOT NULL DEFAULT '',
        synopsis TEXT NOT NULL DEFAULT '',
        word_goal INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT (unixepoch()),
        updated_at INTEGER NOT NULL DEFAULT (unixepoch())
      )
    ''');
    raw.execute(
      "INSERT INTO projects (title, genre, synopsis, word_goal, created_at, updated_at) "
      "VALUES ('旧书', '武侠', '', 10000, 0, 0)",
    );
    raw.execute('PRAGMA user_version = 1');
    raw.dispose();

    // 用当前版本打开同一个文件，触发 onUpgrade
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final projects = await db.allProjects();

    expect(projects.length, 1);
    expect(projects.first.title, '旧书');
    expect(projects.first.syncId, isNotNull);
    expect(projects.first.syncId, isNotEmpty);

    // 再写一次，确认唯一索引没有挡住正常插入
    final second = await db.createProject(title: '新书');
    expect(second, greaterThan(0));
    expect((await db.allProjects()).length, 2);

    // 两次迁移的结果都应该有唯一索引
    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='index' AND name='idx_projects_sync_id'")
        .get();
    expect(indexes.length, 1);

    await db.close();
  });
}
