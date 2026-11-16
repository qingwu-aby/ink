import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../domain/sync/sync_service.dart';
import '../../domain/sync/sync_settings.dart';
import '../../providers.dart';

/// 每天自动同步。
///
/// 不引入原生后台任务（WorkManager / BGTaskScheduler）：那种方案在三端各要一套配置，
/// 而且系统随时可能不给你跑。这里改成「打开 App 或回到前台时检查一次」——
/// 满 24 小时才会真的连网，失败还会节流一小时，不会反复打 GitHub。
class SyncWatcher extends ConsumerStatefulWidget {
  const SyncWatcher({super.key, required this.child, required this.messengerKey});

  final Widget child;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  @override
  ConsumerState<SyncWatcher> createState() => _SyncWatcherState();
}

class _SyncWatcherState extends ConsumerState<SyncWatcher> with WidgetsBindingObserver {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeSync();
  }

  Future<void> _maybeSync() async {
    if (_running) return;
    _running = true;
    try {
      final db = ref.read(databaseProvider);
      final store = SyncSettingsStore(db);

      if (!await store.autoDaily()) return;
      final settings = await store.load();
      if (!settings.isReady) return;

      final now = DateTime.now();
      final lastAttempt = await store.lastAttemptAt();
      if (lastAttempt != null && now.difference(lastAttempt) < const Duration(hours: 1)) {
        return;
      }
      final lastSync = await store.lastSyncAt();
      if (lastSync != null && now.difference(lastSync) < const Duration(hours: 24)) {
        return;
      }

      await store.markAttempt(now);
      final outcome = await runSync(db: db, store: store);
      await store.markAutoError(null);

      if (outcome.created.isNotEmpty || outcome.updated.isNotEmpty) {
        widget.messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('已自动同步：${outcome.summary}')),
        );
      }
    } catch (error) {
      // 自动同步失败不打扰写作，只把原因记下来，用户去同步页能看到
      try {
        final db = ref.read(databaseProvider);
        await SyncSettingsStore(db).markAutoError('$error');
      } catch (_) {
        // 连失败都记不下来就算了
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
