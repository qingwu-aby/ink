import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/data/db/app_database.dart';
import 'package:kedao/domain/sync/sync_settings.dart';
import 'package:kedao/providers.dart';

/// 订阅同步状态并记住最新值（Riverpod 3 默认 autoDispose，必须持续挂监听）。
class _Watcher {
  _Watcher(this._container) {
    _sub = _container.listen(
      syncStatusProvider,
      (_, next) => latest = next.value,
      fireImmediately: true,
    );
  }

  final ProviderContainer _container;
  late final ProviderSubscription<AsyncValue<SyncStatus>> _sub;
  SyncStatus? latest;

  Future<SyncStatus> waitFor(bool Function(SyncStatus) matches) async {
    for (var i = 0; i < 100; i++) {
      final value = latest;
      if (value != null && matches(value)) return value;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    throw StateError('等不到期望的同步状态');
  }

  void close() => _sub.close();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer container;
  late _Watcher watcher;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    watcher = _Watcher(container);
  });

  tearDown(() async {
    watcher.close();
    container.dispose();
    await db.close();
  });

  test('刚装好：没配置、没同步过', () async {
    final status = await watcher.waitFor((_) => true);
    expect(status.configured, isFalse);
    expect(status.lastSyncAt, isNull);
    expect(status.lastOutcome, isNull);
    expect(status.hasError, isFalse);
  });

  test('同步写入后，页面能读到结果与时间', () async {
    final store = SyncSettingsStore(db);
    await store.save(const SyncSettings(repository: 'o/r', branch: 'main', token: 't'));
    final outcome = SyncOutcome(
      created: const ['听雨录'],
      updated: const [],
      removed: const [],
      skipped: const [],
      pushed: true,
      branch: 'main',
      commitSha: 'abc123def',
      at: DateTime.utc(2026, 11, 17, 2, 30),
      notes: const [],
    );
    await store.markSynced(outcome.at, outcome.summary);
    await db.setSetting('sync.lastResult', outcome.encode());

    final status = await watcher.waitFor((s) => s.lastOutcome != null);
    expect(status.configured, isTrue);
    expect(status.lastSyncAt, isNotNull);
    expect(status.lastOutcome!.pushed, isTrue);
    expect(status.lastOutcome!.created, ['听雨录']);
    expect(status.lastOutcome!.commitSha, 'abc123def');
    expect(status.hasError, isFalse);
  });

  test('自动同步失败会留下错误状态', () async {
    final store = SyncSettingsStore(db);
    await store.save(const SyncSettings(repository: 'o/r', branch: 'main', token: 't'));
    await store.markAutoError('连不上 GitHub：SocketException');

    final status = await watcher.waitFor((s) => s.hasError);
    expect(status.configured, isTrue);
    expect(status.lastError, contains('SocketException'));
  });
}
