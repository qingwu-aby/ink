import '../../data/db/app_database.dart';
import 'github_client.dart';
import 'library_codec.dart';
import 'library_io.dart';
import 'sync_settings.dart';

/// 编排一次同步：读远端 → 并入本地 → 再推回去。
///
/// 合并在项目粒度做：同名项目谁的 `updatedAt` 更新就用谁。这样规则一句话能说清，
/// 也不会出现"半本书本地、半本书远端"。
Future<SyncOutcome> runSync({
  required AppDatabase db,
  required SyncSettingsStore store,
  GitHubClient Function(SyncSettings settings)? clientFactory,
  DateTime? now,
}) async {
  final settings = await store.load();
  if (!settings.isReady) {
    throw GitHubException(0, '还没有填写仓库地址或 Token');
  }
  final parsed = GitHubClient.parseRepo(settings.repository);
  if (parsed == null) {
    throw GitHubException(0, '仓库地址要写成 owner/repo 或 https://github.com/owner/repo');
  }

  final client = (clientFactory ??
      (SyncSettings s) => GitHubClient(
            owner: parsed.$1,
            repo: parsed.$2,
            token: s.token,
            branch: s.branch,
          ))(settings);

  final deviceId = await store.deviceId();
  final notes = <String>[];
  var created = <String>[];
  var updated = <String>[];
  var removed = <String>[];
  var skipped = <String>[];

  var remoteText = await client.readText(kSyncPath);
  if (remoteText != null) {
    final remote = LibraryBundle.decode(remoteText);
    final outcome = await importLibrary(db, remote);
    created = outcome.created;
    updated = outcome.updated;
    removed = outcome.removed;
    skipped = outcome.skipped;
    notes.addAll(outcome.notes);
  }

  // 合并之后再导出：此时本地就是"两边并起来"的结果
  var local = await exportLibrary(db, deviceId: deviceId, now: now);
  final remoteHash = remoteText == null ? null : LibraryBundle.decode(remoteText).contentHash;

  if (remoteHash != null && remoteHash == local.contentHash) {
    final at = now ?? DateTime.now();
    await store.markSynced(at, '已是最新');
    return SyncOutcome(
      created: created,
      updated: updated,
      removed: removed,
      skipped: skipped,
      pushed: false,
      branch: settings.branch,
      commitSha: null,
      at: at,
      notes: notes,
    );
  }

  if (local.projects.isEmpty && local.tombstones.isEmpty && remoteText != null) {
    // 本地既没有书也没有墓碑、远端有 → 上面已经拉下来了，不需要再推
    final at = now ?? DateTime.now();
    await store.markSynced(at, '已拉取');
    return SyncOutcome(
      created: created,
      updated: updated,
      removed: removed,
      skipped: skipped,
      pushed: false,
      branch: settings.branch,
      commitSha: null,
      at: at,
      notes: notes,
    );
  }

  final stamp = _stamp(now ?? DateTime.now());
  final message = '墨谱同步 $stamp · ${local.projects.length} 个项目 · $deviceId';

  WriteOutcome written;
  try {
    written = await client.writeText(
      path: kSyncPath,
      content: local.encode(),
      message: message,
    );
  } on SyncConflictException {
    // 别的设备刚推过：重新拉一次、再合一次，然后重试一遍
    notes.add('远端刚被改过，已重新合并后重试');
    final retryRemote = await client.readText(kSyncPath);
    if (retryRemote != null) {
      await importLibrary(db, LibraryBundle.decode(retryRemote));
    }
    local = await exportLibrary(db, deviceId: deviceId, now: now);
    written = await client.writeText(
      path: kSyncPath,
      content: local.encode(),
      message: message,
    );
  }

  final at = now ?? DateTime.now();
  final summary = [
    if (created.isNotEmpty) '拉取 ${created.length}',
    if (updated.isNotEmpty) '更新 ${updated.length}',
    if (removed.isNotEmpty) '删除 ${removed.length}',
    if (skipped.isNotEmpty) '本地较新 ${skipped.length}',
    '推送 1',
  ].join(' · ');
  await store.markSynced(at, summary);

  return SyncOutcome(
    created: created,
    updated: updated,
    removed: removed,
    skipped: skipped,
    pushed: true,
    branch: written.branch,
    commitSha: written.commitSha,
    at: at,
    notes: notes,
  );
}

String _stamp(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
}
