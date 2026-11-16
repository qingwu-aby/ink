import '../../core/utils/ids.dart';
import '../../data/db/app_database.dart';
import 'github_client.dart';
import 'library_codec.dart';
import 'library_io.dart';
import 'sync_settings.dart';

/// 编排一次同步：读远端 → 检测冲突 → 并入本地 → 再推回去。
///
/// 合并在项目粒度做。平时是"谁新用谁"（LWW），但两边都在上次同步后改过同一本书时，
/// 静默 LWW 会吃掉一份——这时不写数据，先把冲突报上去，等作者自己选。
Future<SyncOutcome> runSync({
  required AppDatabase db,
  required SyncSettingsStore store,
  GitHubClient Function(SyncSettings settings)? clientFactory,
  DateTime? now,
  Map<String, ConflictResolution>? resolutions,
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
  final remote = remoteText == null ? null : LibraryBundle.decode(remoteText);

  // 先看有没有"两边都改过"：有就先停下来问，别静默覆盖
  if (remote != null) {
    var localNow = await exportLibrary(db, deviceId: deviceId, now: now);
    final marks = await db.allSyncMarks();
    final conflicts = _detectConflicts(localNow, remote, marks);

    if (conflicts.isNotEmpty && resolutions == null) {
      final at = now ?? DateTime.now();
      return SyncOutcome(
        created: const [],
        updated: const [],
        removed: const [],
        skipped: const [],
        pushed: false,
        branch: settings.branch,
        commitSha: null,
        at: at,
        notes: const ['两边都改过同一本书，等你决定'],
        conflicts: conflicts,
      );
    }

    if (conflicts.isNotEmpty) {
      await _applyResolutions(db, localNow, remote, conflicts, resolutions!);
      notes.add('已按你的选择处理 ${conflicts.length} 处冲突');
      localNow = await exportLibrary(db, deviceId: deviceId, now: now);
    }
  }

  if (remote != null) {
    final outcome = await importLibrary(db, remote);
    created = outcome.created;
    updated = outcome.updated;
    removed = outcome.removed;
    skipped = outcome.skipped;
    notes.addAll(outcome.notes);
  }

  // 合并之后再导出：此时本地就是"两边并起来"的结果
  var local = await exportLibrary(db, deviceId: deviceId, now: now);
  final remoteHash = remote?.contentHash;

  if (remoteHash != null && remoteHash == local.contentHash) {
    final at = now ?? DateTime.now();
    await _saveMarks(db, local);
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
    await _saveMarks(db, local);
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

  await _saveMarks(db, local);
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

/// 两边都在上次同步后动过、且内容不同 → 冲突。
List<SyncConflict> _detectConflicts(
  LibraryBundle local,
  LibraryBundle remote,
  Map<String, SyncMark> marks,
) {
  final remoteById = {for (final project in remote.projects) project.syncId: project};
  final conflicts = <SyncConflict>[];
  for (final project in local.projects) {
    final other = remoteById[project.syncId];
    if (other == null) continue;
    if (project.updatedAt.isAtSameMomentAs(other.updatedAt)) continue;

    final mark = marks[project.syncId];
    // 没有水位（首次同步/老版本升级上来）就退回 LWW，不制造惊喜
    if (mark == null) continue;

    final localMoved = !project.updatedAt.isAtSameMomentAs(mark.localUpdatedAt);
    final remoteMoved = !other.updatedAt.isAtSameMomentAs(mark.remoteUpdatedAt);
    if (!localMoved || !remoteMoved) continue;

    conflicts.add(SyncConflict(
      syncId: project.syncId,
      title: project.title,
      localUpdatedAt: project.updatedAt,
      remoteUpdatedAt: other.updatedAt,
    ));
  }
  return conflicts;
}

/// 按作者的选择把冲突摊平，让后面的常规合并能自然地走完。
Future<void> _applyResolutions(
  AppDatabase db,
  LibraryBundle local,
  LibraryBundle remote,
  List<SyncConflict> conflicts,
  Map<String, ConflictResolution> resolutions,
) async {
  final remoteById = {for (final project in remote.projects) project.syncId: project};
  final localById = {for (final project in local.projects) project.syncId: project};

  for (final conflict in conflicts) {
    final choice = resolutions[conflict.syncId] ?? ConflictResolution.keepBoth;
    final remoteProject = remoteById[conflict.syncId];
    final localProject = localById[conflict.syncId];
    final localRow = await db.projectBySyncId(conflict.syncId);

    switch (choice) {
      case ConflictResolution.keepRemote:
        if (remoteProject != null) await forcePullProject(db, remoteProject);
      case ConflictResolution.keepLocal:
        // 抬一下时间戳，让本地在合并里胜出
        if (localRow != null) await db.touchProject(localRow.id);
      case ConflictResolution.keepBoth:
        if (remoteProject != null) {
          await importProjectCopy(
            db,
            remoteProject,
            syncId: newSyncId(),
            title: '${remoteProject.title}（远端副本）',
          );
        }
        if (localRow != null) await db.touchProject(localRow.id);
    }
  }
}

/// 同步成功后记录水位：此时本地与远端一致。
Future<void> _saveMarks(AppDatabase db, LibraryBundle local) async {
  await db.replaceSyncMarks({
    for (final project in local.projects) project.syncId: project.updatedAt,
  });
}

String _stamp(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
}
