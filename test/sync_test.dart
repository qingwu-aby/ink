import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/data/db/app_database.dart';
import 'package:kedao/domain/sync/library_codec.dart';
import 'package:kedao/domain/sync/library_io.dart';
import 'package:kedao/domain/sync/github_client.dart';
import 'package:kedao/domain/sync/sync_service.dart';
import 'package:kedao/domain/sync/sync_settings.dart';

/// 一个只实现 Git Data API 的假 GitHub，够验证真实的调用序列。
class FakeGitHub {
  FakeGitHub._(this._server);

  final HttpServer _server;
  final _blobs = <String, String>{}; // sha → 原文
  final _trees = <String, Map<String, String>>{}; // sha → path → blobSha
  final _commits = <String, Map<String, dynamic>>{}; // sha → {tree, parents}
  final _refs = <String, String>{}; // branch → commitSha
  var _counter = 0;
  var patchCalls = 0;
  var failNextPatch = false;

  Uri get base => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<FakeGitHub> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeGitHub._(server);
    server.listen(fake._handle);
    return fake;
  }

  Future<void> stop() => _server.close(force: true);

  String _sha(String prefix) {
    _counter++;
    return '$prefix${_counter.toString().padLeft(4, '0')}';
  }

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;
    Object? body;
    Map<String, dynamic> json = const {};
    if (method != 'GET') {
      final text = await utf8.decoder.bind(request).join();
      if (text.isNotEmpty) {
        final decoded = jsonDecode(text);
        if (decoded is Map) json = decoded.cast<String, dynamic>();
        body = decoded;
      }
    }

    void send(int status, Object data) {
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(data));
      request.response.close();
    }

    // GET /repos/o/r
    if (method == 'GET' && RegExp(r'^/repos/[^/]+/[^/]+$').hasMatch(path)) {
      return send(200, {'full_name': 'o/r', 'default_branch': 'main', 'private': true});
    }

    final refMatch = RegExp(r'^/repos/[^/]+/[^/]+/git/ref/heads/(.+)$').firstMatch(path);
    if (method == 'GET' && refMatch != null) {
      final branch = refMatch.group(1)!;
      final sha = _refs[branch];
      if (sha == null) return send(404, {'message': 'Not Found'});
      return send(200, {
        'object': {'sha': sha, 'type': 'commit'},
      });
    }

    final commitMatch = RegExp(r'^/repos/[^/]+/[^/]+/git/commits/([^/]+)$').firstMatch(path);
    if (method == 'GET' && commitMatch != null) {
      final data = _commits[commitMatch.group(1)!];
      if (data == null) return send(404, {'message': 'Not Found'});
      return send(200, {
        'sha': commitMatch.group(1),
        'tree': {'sha': data['tree']},
        'parents': data['parents'],
      });
    }

    if (method == 'POST' && path.endsWith('/git/commits')) {
      final sha = _sha('commit');
      _commits[sha] = {
        'tree': json['tree'],
        'parents': json['parents'] ?? const [],
        'message': json['message'],
      };
      return send(201, {'sha': sha, 'message': json['message']});
    }

    final treeMatch = RegExp(r'^/repos/[^/]+/[^/]+/git/trees/([^/]+)$').firstMatch(path);
    if (method == 'GET' && treeMatch != null) {
      final entries = _trees[treeMatch.group(1)!];
      if (entries == null) return send(404, {'message': 'Not Found'});
      return send(200, {
        'sha': treeMatch.group(1),
        'tree': [
          for (final entry in entries.entries)
            {'path': entry.key, 'mode': '100644', 'type': 'blob', 'sha': entry.value},
        ],
      });
    }

    if (method == 'POST' && path.endsWith('/git/trees')) {
      final baseTree = json['base_tree'] as String?;
      final entries = <String, String>{
        if (baseTree != null) ...?_trees[baseTree],
      };
      for (final item in (json['tree'] as List? ?? const [])) {
        if (item is Map) entries['${item['path']}'] = '${item['sha']}';
      }
      final sha = _sha('tree');
      _trees[sha] = entries;
      return send(201, {'sha': sha});
    }

    if (method == 'POST' && path.endsWith('/git/blobs')) {
      final content = json['content'];
      if (content is! String) return send(400, {'message': 'missing content'});
      final sha = _sha('blob');
      _blobs[sha] = utf8.decode(base64.decode(content));
      return send(201, {'sha': sha});
    }

    final blobMatch = RegExp(r'^/repos/[^/]+/[^/]+/git/blobs/([^/]+)$').firstMatch(path);
    if (method == 'GET' && blobMatch != null) {
      final text = _blobs[blobMatch.group(1)!];
      if (text == null) return send(404, {'message': 'Not Found'});
      return send(200, {
        'content': base64.encode(utf8.encode(text)).replaceAllMapped(
              RegExp(r'.{60}'),
              (m) => '${m[0]}\n',
            ),
        'encoding': 'base64',
      });
    }

    if (method == 'POST' && path.endsWith('/git/refs')) {
      final ref = '${json['ref']}'; // refs/heads/main
      _refs[ref.split('/').last] = '${json['sha']}';
      return send(201, {'ref': ref, 'object': {'sha': json['sha']}});
    }

    final patchMatch = RegExp(r'^/repos/[^/]+/[^/]+/git/refs/heads/(.+)$').firstMatch(path);
    if (method == 'PATCH' && patchMatch != null) {
      patchCalls++;
      if (failNextPatch) {
        failNextPatch = false;
        return send(422, {'message': 'Update is not a fast forward'});
      }
      _refs[patchMatch.group(1)!] = '${json['sha']}';
      return send(200, {'object': {'sha': json['sha']}});
    }

    send(404, {'message': 'no route: $method $path'});
  }

  /// 直接从「仓库」里读出同步文件，用于断言。
  String? currentFile(String path) {
    final head = _refs['main'];
    if (head == null) return null;
    final tree = _commits[head]?['tree'];
    final entries = _trees[tree];
    final blob = entries?[path];
    return blob == null ? null : _blobs[blob];
  }

  int get commitCount => _commits.length;
}

/// 用假仓库跑一次同步。
Future<SyncOutcome> syncWith(
  AppDatabase db,
  SyncSettingsStore store,
  FakeGitHub fake, {
  Map<String, ConflictResolution>? resolutions,
}) =>
    runSync(
      db: db,
      store: store,
      resolutions: resolutions,
      clientFactory: (s) => GitHubClient(
        owner: 'o',
        repo: 'r',
        token: s.token,
        branch: s.branch,
        apiBase: fake.base,
      ),
    );

Future<AppDatabase> emptyDb() async => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> seedBook(AppDatabase db, String title) async {
  final projectId = await db.createProject(title: title, genre: '武侠', wordGoal: 10000);
  final shen = await db.createEntity(projectId: projectId, name: '沈砚之', summary: '记话为生');
  final su = await db.createEntity(projectId: projectId, name: '苏鸢');
  await db.upsertRelation(
    projectId: projectId,
    fromId: shen,
    toId: su,
    kind: 'crush',
    validFrom: 2,
  );
  final chapterId = await db.createChapter(
    projectId: projectId,
    title: '第一章 洛水夜雨',
    body: '沈砚之走进听雨楼，苏鸢在算账。',
  );
  await db.replaceMentions(chapterId, const []);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  group('同步文件的编码', () {
    test('能原样往返', () {
      final bundle = LibraryBundle(
        deviceId: 'dev-test',
        exportedAt: DateTime.utc(2026, 11, 16, 3),
        projects: [
          ProjectBundle(
            syncId: 'p-1',
            title: '听雨录',
            genre: '武侠',
            synopsis: '雨。',
            wordGoal: 120000,
            updatedAt: DateTime.utc(2026, 11, 16, 2),
            chapters: const [
              ChapterBundle(index: 1, title: '洛水夜雨', body: '雨下了三日。', status: 'draft', note: ''),
            ],
            entities: const [
              EntityBundle(
                name: '沈砚之',
                kind: 'character',
                aliases: ['砚之'],
                summary: '记话为生',
                importance: 5,
                status: 'dead',
                deathChapter: 2,
              ),
            ],
            relations: const [
              RelationBundle(
                from: '沈砚之',
                to: '苏鸢',
                kind: 'crush',
                strength: 4,
                note: '',
                validFrom: 3,
                validTo: null,
              ),
            ],
            foreshadows: const [
              ForeshadowBundle(hook: '半页旧诏', plantedChapter: 1, resolvedChapter: null, note: ''),
            ],
          ),
        ],
      );

      final decoded = LibraryBundle.decode(bundle.encode());
      expect(decoded.projects.length, 1);
      final project = decoded.projects.first;
      expect(project.title, '听雨录');
      expect(project.entities.first.aliases, ['砚之']);
      expect(project.entities.first.deathChapter, 2);
      expect(project.relations.first.from, '沈砚之');
      expect(project.relations.first.validTo, isNull);
      expect(project.chapters.first.body, '雨下了三日。');
      expect(decoded.contentHash, bundle.contentHash);
    });

    test('拒绝别的格式与更高版本', () {
      expect(() => LibraryBundle.decode('{"format":"other"}'), throwsFormatException);
      expect(
        () => LibraryBundle.decode('{"format":"mopu.library","version":99,"projects":[]}'),
        throwsFormatException,
      );
    });
  });

  group('导出与导入', () {
    test('同一份数据导出再导入，内容不丢', () async {
      final source = await emptyDb();
      await seedBook(source, '听雨录');
      final bundle = await exportLibrary(source, deviceId: 'dev-a');

      final target = await emptyDb();
      final outcome = await importLibrary(target, bundle);

      expect(outcome.created, ['听雨录']);
      final projects = await target.allProjects();
      expect(projects.length, 1);
      final projectId = projects.first.id;
      expect((await target.entitiesOf(projectId)).length, 2);
      expect((await target.relationsOf(projectId)).length, 1);
      final chapters = await target.chaptersOf(projectId);
      expect(chapters.first.title, '第一章 洛水夜雨');
      // 正文提及重新索引，不依赖同步过来的位置
      final mentions = await target.mentionsOfChapter(chapters.first.id);
      expect(mentions.length, 2);

      await source.close();
      await target.close();
    });

    test('远端更新才覆盖，本地较新就保留', () async {
      final db = await emptyDb();
      await seedBook(db, '听雨录');
      final local = await exportLibrary(db, deviceId: 'dev-a');

      // 远端更旧 → 跳过
      final olderBundle = await exportLibrary(db, deviceId: 'dev-b');
      final older = LibraryBundle(
        deviceId: 'dev-b',
        exportedAt: DateTime.now(),
        projects: [
          for (final p in olderBundle.projects)
            ProjectBundle(
              syncId: p.syncId,
              title: '旧标题',
              genre: p.genre,
              synopsis: p.synopsis,
              wordGoal: p.wordGoal,
              updatedAt: p.updatedAt.subtract(const Duration(days: 1)),
              chapters: p.chapters,
              entities: p.entities,
              relations: p.relations,
              foreshadows: p.foreshadows,
            ),
        ],
      );
      final skipped = await importLibrary(db, older);
      // 记录的是远端那份的名字（它因为太旧被跳过）
      expect(skipped.skipped, ['旧标题']);
      expect((await db.allProjects()).first.title, '听雨录');

      // 远端更新 → 覆盖
      final newer = LibraryBundle(
        deviceId: 'dev-b',
        exportedAt: DateTime.now(),
        projects: [
          for (final p in local.projects)
            ProjectBundle(
              syncId: p.syncId,
              title: '新标题',
              genre: p.genre,
              synopsis: p.synopsis,
              wordGoal: p.wordGoal,
              updatedAt: p.updatedAt.add(const Duration(minutes: 5)),
              chapters: p.chapters,
              entities: p.entities,
              relations: p.relations,
              foreshadows: p.foreshadows,
            ),
        ],
      );
      final applied = await importLibrary(db, newer);
      expect(applied.updated, ['新标题']);
      expect((await db.allProjects()).first.title, '新标题');

      await db.close();
    });
  });

  group('删除的墓碑', () {
    test('删除后导出会带上墓碑', () async {
      final db = await emptyDb();
      await seedBook(db, '要删掉的书');
      final projects = await db.allProjects();
      await db.purgeProject(projects.first.id, deviceId: 'dev-a');

      final bundle = await exportLibrary(db, deviceId: 'dev-a');
      expect(bundle.projects, isEmpty);
      expect(bundle.tombstones.length, 1);
      expect(bundle.tombstones.first.title, '要删掉的书');
      await db.close();
    });

    test('远端墓碑比本地版本新 → 本地跟着删', () async {
      final db = await emptyDb();
      await seedBook(db, '听雨录');
      final local = await exportLibrary(db, deviceId: 'dev-a');
      final project = local.projects.first;

      final remote = LibraryBundle(
        deviceId: 'dev-b',
        exportedAt: DateTime.now(),
        projects: const [],
        tombstones: [
          TombstoneBundle(
            syncId: project.syncId,
            title: project.title,
            deletedAt: project.updatedAt.add(const Duration(hours: 1)),
          ),
        ],
      );

      final outcome = await importLibrary(db, remote);
      expect(outcome.removed, ['听雨录']);
      expect(await db.allProjects(), isEmpty);
      await db.close();
    });

    test('删除之后本地又改过 → 保留并复活', () async {
      final db = await emptyDb();
      await seedBook(db, '听雨录');
      final local = await exportLibrary(db, deviceId: 'dev-a');
      final project = local.projects.first;

      final remote = LibraryBundle(
        deviceId: 'dev-b',
        exportedAt: DateTime.now(),
        projects: const [],
        tombstones: [
          TombstoneBundle(
            syncId: project.syncId,
            title: project.title,
            deletedAt: project.updatedAt.subtract(const Duration(hours: 1)),
          ),
        ],
      );

      final outcome = await importLibrary(db, remote);
      expect(outcome.removed, isEmpty);
      expect((await db.allProjects()).length, 1);
      // 复活之后墓碑应当被清掉，否则每次同步都要再判断一次
      expect(await db.tombstoneOf(project.syncId), isNull);
      await db.close();
    });

    test('比墓碑旧的远端项目不会被复活', () async {
      final db = await emptyDb();
      await seedBook(db, '听雨录');
      final local = await exportLibrary(db, deviceId: 'dev-a');
      final project = local.projects.first;
      await db.purgeProject((await db.allProjects()).first.id, deviceId: 'dev-a');

      final stale = LibraryBundle(
        deviceId: 'dev-b',
        exportedAt: DateTime.now(),
        projects: [
          ProjectBundle(
            syncId: project.syncId,
            title: project.title,
            genre: project.genre,
            synopsis: project.synopsis,
            wordGoal: project.wordGoal,
            updatedAt: project.updatedAt,
            chapters: project.chapters,
            entities: project.entities,
            relations: project.relations,
            foreshadows: project.foreshadows,
          ),
        ],
      );

      final outcome = await importLibrary(db, stale);
      expect(outcome.created, isEmpty);
      expect(outcome.skipped, ['听雨录']);
      expect(await db.allProjects(), isEmpty);
      await db.close();
    });
  });

  group('两边都改过', () {
    Future<({AppDatabase a, AppDatabase b, SyncSettingsStore sa, SyncSettingsStore sb, FakeGitHub fake})>
        pair() async {
      final fake = await FakeGitHub.start();
      final a = await emptyDb();
      await seedBook(a, '听雨录');
      final sa = SyncSettingsStore(a);
      await sa.save(const SyncSettings(repository: 'o/r', branch: 'main', token: 't'));
      await syncWith(a, sa, fake); // A 先推

      final b = await emptyDb();
      final sb = SyncSettingsStore(b);
      await sb.save(const SyncSettings(repository: 'o/r', branch: 'main', token: 't'));
      await syncWith(b, sb, fake); // B 拉，建立水位
      // drift 存时间到秒，测试里连着改会撞在同一秒，这里错开一下
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      return (a: a, b: b, sa: sa, sb: sb, fake: fake);
    }

    test('检测到两边都改过时先停下来，不动数据', () async {
      final env = await pair();

      // 两边各改一次，时间错开一秒（存储精度是秒）
      await env.b.updateProject((await env.b.allProjects()).first.copyWith(title: 'B 版'));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await env.a.updateProject((await env.a.allProjects()).first.copyWith(title: 'A 版'));
      await syncWith(env.a, env.sa, env.fake); // A 推，远端变成 A 版

      final outcome = await syncWith(env.b, env.sb, env.fake);

      expect(outcome.needsDecision, isTrue);
      expect(outcome.conflicts.length, 1);
      // 标题取本地那份（书架上是它）
      expect(outcome.conflicts.first.title, 'B 版');
      expect(outcome.pushed, isFalse);
      // 冲突时什么都不能改
      expect((await env.b.allProjects()).first.title, 'B 版');

      await env.a.close();
      await env.b.close();
      await env.fake.stop();
    });

    test('选「两个都留」：本地留着，远端那份存成一本新书', () async {
      final env = await pair();
      await env.b.updateProject((await env.b.allProjects()).first.copyWith(title: 'B 版'));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await env.a.updateProject((await env.a.allProjects()).first.copyWith(title: 'A 版'));
      await syncWith(env.a, env.sa, env.fake);

      final pending = await syncWith(env.b, env.sb, env.fake);
      final outcome = await syncWith(
        env.b,
        env.sb,
        env.fake,
        resolutions: {
          for (final conflict in pending.conflicts)
            conflict.syncId: ConflictResolution.keepBoth,
        },
      );

      expect(outcome.pushed, isTrue);
      final titles = (await env.b.allProjects()).map((p) => p.title).toList()..sort();
      expect(titles, ['A 版（远端副本）', 'B 版']);

      await env.a.close();
      await env.b.close();
      await env.fake.stop();
    });

    test('选「用远端的」：本地被覆盖', () async {
      final env = await pair();
      await env.b.updateProject((await env.b.allProjects()).first.copyWith(title: 'B 版'));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await env.a.updateProject((await env.a.allProjects()).first.copyWith(title: 'A 版'));
      await syncWith(env.a, env.sa, env.fake);

      final pending = await syncWith(env.b, env.sb, env.fake);
      await syncWith(
        env.b,
        env.sb,
        env.fake,
        resolutions: {
          for (final conflict in pending.conflicts)
            conflict.syncId: ConflictResolution.keepRemote,
        },
      );

      expect((await env.b.allProjects()).first.title, 'A 版');

      await env.a.close();
      await env.b.close();
      await env.fake.stop();
    });

    test('选「用我的」：本地推上去覆盖远端', () async {
      final env = await pair();
      await env.b.updateProject((await env.b.allProjects()).first.copyWith(title: 'B 版'));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await env.a.updateProject((await env.a.allProjects()).first.copyWith(title: 'A 版'));
      await syncWith(env.a, env.sa, env.fake);

      final pending = await syncWith(env.b, env.sb, env.fake);
      await syncWith(
        env.b,
        env.sb,
        env.fake,
        resolutions: {
          for (final conflict in pending.conflicts)
            conflict.syncId: ConflictResolution.keepLocal,
        },
      );

      expect((await env.b.allProjects()).first.title, 'B 版');
      // 远端现在是 B 版：换一台干净设备拉一次就知道了
      final c = await emptyDb();
      final sc = SyncSettingsStore(c);
      await sc.save(const SyncSettings(repository: 'o/r', branch: 'main', token: 't'));
      await syncWith(c, sc, env.fake);
      expect((await c.allProjects()).first.title, 'B 版');

      await env.a.close();
      await env.b.close();
      await c.close();
      await env.fake.stop();
    });

    test('只有一方改过时不报冲突，直接 LWW', () async {
      final env = await pair();
      await env.b.updateProject((await env.b.allProjects()).first.copyWith(title: 'B 版'));

      final outcome = await syncWith(env.b, env.sb, env.fake);
      expect(outcome.needsDecision, isFalse);
      expect(outcome.pushed, isTrue);

      // A 下次拉下来就是 B 版
      await syncWith(env.a, env.sa, env.fake);
      expect((await env.a.allProjects()).first.title, 'B 版');

      await env.a.close();
      await env.b.close();
      await env.fake.stop();
    });
  });

  group('GitHub 客户端', () {
    late FakeGitHub fake;
    setUp(() async => fake = await FakeGitHub.start());
    tearDown(() async => fake.stop());

    GitHubClient client() => GitHubClient(
          owner: 'o',
          repo: 'r',
          token: 't',
          branch: 'main',
          apiBase: fake.base,
        );

    test('空仓库能引导出第一个 commit，并读回内容', () async {
      final gh = client();
      expect(await gh.readText('mopu/library.json'), isNull);
      expect(await gh.headSha(), isNull);

      final written = await gh.writeText(
        path: 'mopu/library.json',
        content: '{"hello":"世界"}',
        message: 'first',
      );
      expect(written.commitSha, isNotEmpty);
      expect(await gh.readText('mopu/library.json'), '{"hello":"世界"}');
      expect(await gh.headSha(), written.commitSha);
    });

    test('第二次写入走 PATCH ref，内容被替换', () async {
      final gh = client();
      await gh.writeText(path: 'mopu/library.json', content: 'v1', message: 'one');
      await gh.writeText(path: 'mopu/library.json', content: 'v2', message: 'two');
      expect(await gh.readText('mopu/library.json'), 'v2');
      expect(fake.patchCalls, 1);
      expect(fake.commitCount, 2);
    });

    test('并发冲突会抛 SyncConflictException', () async {
      final gh = client();
      await gh.writeText(path: 'mopu/library.json', content: 'v1', message: 'one');
      fake.failNextPatch = true;
      await expectLater(
        gh.writeText(path: 'mopu/library.json', content: 'v2', message: 'two'),
        throwsA(isA<SyncConflictException>()),
      );
    });

    test('repo 地址的各种写法都能解析', () {
      expect(GitHubClient.parseRepo('o/r'), ('o', 'r'));
      expect(GitHubClient.parseRepo('https://github.com/o/r.git'), ('o', 'r'));
      expect(GitHubClient.parseRepo('https://github.com/o/r/'), ('o', 'r'));
      expect(GitHubClient.parseRepo('github.com/o/r'), ('o', 'r'));
      expect(GitHubClient.parseRepo('nonsense'), isNull);
    });
  });

  group('两台设备通过同一个仓库同步', () {
    test('A 写进仓库，B 拉下来并还原成完整的书', () async {
      final fake = await FakeGitHub.start();

      final dbA = await emptyDb();
      await seedBook(dbA, '听雨录');
      final storeA = SyncSettingsStore(dbA);
      await storeA.save(const SyncSettings(repository: 'o/r', branch: 'main', token: 't'));

      final outcomeA = await runSync(
        db: dbA,
        store: storeA,
        clientFactory: (s) => GitHubClient(
          owner: 'o',
          repo: 'r',
          token: s.token,
          branch: s.branch,
          apiBase: fake.base,
        ),
      );
      expect(outcomeA.pushed, isTrue);
      expect(fake.currentFile(kSyncPath), isNotNull);

      // 设备 B：空库，同一个仓库
      final dbB = await emptyDb();
      final storeB = SyncSettingsStore(dbB);
      await storeB.save(const SyncSettings(repository: 'o/r', branch: 'main', token: 't'));

      final outcomeB = await runSync(
        db: dbB,
        store: storeB,
        clientFactory: (s) => GitHubClient(
          owner: 'o',
          repo: 'r',
          token: s.token,
          branch: s.branch,
          apiBase: fake.base,
        ),
      );
      expect(outcomeB.created, ['听雨录']);

      final projects = await dbB.allProjects();
      expect(projects.length, 1);
      final projectId = projects.first.id;
      expect((await dbB.entitiesOf(projectId)).length, 2);
      expect((await dbB.relationsOf(projectId)).length, 1);
      final chapters = await dbB.chaptersOf(projectId);
      expect(chapters.length, 1);
      expect((await dbB.mentionsOfChapter(chapters.first.id)).length, 2);

      // A 删掉这本书并同步，B 再同步时应该跟着删
      await dbA.purgeProject((await dbA.allProjects()).first.id, deviceId: 'dev-a');
      final outcomeA2 = await runSync(
        db: dbA,
        store: storeA,
        clientFactory: (s) => GitHubClient(
          owner: 'o',
          repo: 'r',
          token: s.token,
          branch: s.branch,
          apiBase: fake.base,
        ),
      );
      expect(outcomeA2.pushed, isTrue);

      final outcomeB3 = await runSync(
        db: dbB,
        store: storeB,
        clientFactory: (s) => GitHubClient(
          owner: 'o',
          repo: 'r',
          token: s.token,
          branch: s.branch,
          apiBase: fake.base,
        ),
      );
      expect(outcomeB3.removed, ['听雨录']);
      expect(await dbB.allProjects(), isEmpty);

      // B 再同步一次：没有变化就不该再产生 commit
      final commitsBefore = fake.commitCount;
      final outcomeB2 = await runSync(
        db: dbB,
        store: storeB,
        clientFactory: (s) => GitHubClient(
          owner: 'o',
          repo: 'r',
          token: s.token,
          branch: s.branch,
          apiBase: fake.base,
        ),
      );
      expect(outcomeB2.pushed, isFalse);
      expect(fake.commitCount, commitsBefore);

      await dbA.close();
      await dbB.close();
      await fake.stop();
    });
  });
}
