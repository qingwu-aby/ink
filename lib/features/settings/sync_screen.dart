import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../data/db/app_database.dart';
import '../../domain/sync/github_client.dart';
import '../../domain/sync/sync_service.dart';
import '../../domain/sync/sync_settings.dart';
import '../../providers.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _repo = TextEditingController();
  final _branch = TextEditingController(text: 'main');
  final _token = TextEditingController();

  late final SyncSettingsStore _store = SyncSettingsStore(ref.read(databaseProvider));

  bool _loading = true;
  bool _busy = false;
  bool _hasToken = false;
  String? _status;
  bool _statusIsError = false;
  SyncOutcome? _lastOutcome;
  DateTime? _lastSyncAt;
  RepoInfo? _repoInfo;
  bool _autoDaily = true;
  String? _autoError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    final lastAt = await _store.lastSyncAt();
    final raw = await _store.lastResult();
    final autoDaily = await _store.autoDaily();
    final autoError = await _store.lastAutoError();
    if (!mounted) return;
    setState(() {
      _repo.text = settings.repository;
      _branch.text = settings.branch;
      _hasToken = settings.token.isNotEmpty;
      _cachedToken = settings.token;
      _lastSyncAt = lastAt;
      _lastOutcome = SyncOutcome.decode(raw);
      _autoDaily = autoDaily;
      _autoError = autoError;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _repo.dispose();
    _branch.dispose();
    _token.dispose();
    super.dispose();
  }

  SyncSettings _current() => SyncSettings(
        repository: _repo.text.trim(),
        branch: _branch.text.trim().isEmpty ? 'main' : _branch.text.trim(),
        token: _token.text.trim().isEmpty ? _cachedToken : _token.text.trim(),
      );

  String _cachedToken = '';

  Future<void> _save() async {
    final settings = _current();
    await _store.save(settings);
    _cachedToken = settings.token;
    if (!mounted) return;
    setState(() {
      _hasToken = settings.token.isNotEmpty;
      _cachedToken = settings.token;
      _status = '已保存';
      _statusIsError = false;
    });
  }

  Future<void> _test() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _save();
      final parsed = GitHubClient.parseRepo(_repo.text);
      if (parsed == null) throw GitHubException(0, '仓库地址要写成 owner/repo');
      final client = GitHubClient(
        owner: parsed.$1,
        repo: parsed.$2,
        token: _current().token,
        branch: _current().branch,
      );
      Map<String, String>? headers;
      final info = await client.repoInfo(onHeaders: (value) => headers = value);
      final head = await client.headSha();

      // classic token 会在响应头里带上 scope；fine-grained 没有这个头，跳过检查
      final scopes = (headers?['x-oauth-scopes'] ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final missingWrite = scopes.isNotEmpty && !scopes.contains('repo');

      if (!mounted) return;
      setState(() {
        _repoInfo = info;
        _status = missingWrite
            ? '连上了 ${info.fullName}，但这个 Token 只有「${scopes.join('、')}」权限，'
                '写不进仓库——classic token 需要勾选 repo'
            : head == null
                ? '连上了：${info.fullName}（空仓库，首次同步会创建第一个 commit）'
                : '连上了：${info.fullName} · 分支 ${_current().branch} 已有提交';
        _statusIsError = missingWrite;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = '$error';
        _statusIsError = true;
        _repoInfo = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _save();
      var outcome = await runSync(db: ref.read(databaseProvider), store: _store);

      // 两边都改过：先问清楚，别静默覆盖
      if (outcome.needsDecision) {
        if (!mounted) return;
        setState(() => _busy = false);
        final choices = await _askResolutions(outcome.conflicts);
        if (choices == null) {
          if (!mounted) return;
          setState(() => _status = '已取消，这次没有改动任何数据');
          return;
        }
        if (!mounted) return;
        setState(() => _busy = true);
        outcome = await runSync(
          db: ref.read(databaseProvider),
          store: _store,
          resolutions: choices,
        );
      }

      if (!mounted) return;
      setState(() {
        _lastOutcome = outcome;
        _lastSyncAt = outcome.at;
        _status = outcome.summary;
        _statusIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = '$error';
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, ConflictResolution>?> _askResolutions(List<SyncConflict> conflicts) {
    return showDialog<Map<String, ConflictResolution>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ConflictDialog(conflicts: conflicts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub 同步')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.sunken,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    '数据不进任何中转服务器：同步就是往你自己的私有仓库里写一个 JSON 文件，'
                    '每同步一次留一个 commit，出事了能翻历史找回旧版本。',
                    style: context.texts.bodySmall?.copyWith(height: 1.7),
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: '仓库',
                  subtitle: '填 owner/repo，或者直接粘贴仓库地址',
                  child: Column(
                    children: [
                      TextField(
                        controller: _repo,
                        decoration: const InputDecoration(
                          labelText: '私有仓库',
                          hintText: 'yourname/novel-sync 或 https://github.com/…',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _branch,
                        decoration: const InputDecoration(
                          labelText: '分支',
                          hintText: 'main',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _token,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Personal Access Token',
                          hintText: _hasToken ? '已保存，留空则沿用' : 'ghp_… （需要 repo 权限）',
                        ),
                      ),
                      if (_repoInfo != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Mo.jade),
                            const SizedBox(width: 6),
                            Text(
                              '${_repoInfo!.fullName} · ${_repoInfo!.private ? '私有' : '公开（注意！）'}',
                              style: context.texts.labelSmall,
                            ),
                          ],
                        ),
                      ],
                      if (_status != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _status!,
                          style: context.texts.bodySmall?.copyWith(
                            height: 1.6,
                            color: _statusIsError ? Theme.of(context).colorScheme.error : context.soft,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _busy ? null : _test,
                              child: const Text('测试连接'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy ? null : _sync,
                              child: _busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('立即同步'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: '自动同步',
                  subtitle: '打开 App 或回到前台时检查，满 24 小时才连网',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _autoDaily,
                        onChanged: (value) async {
                          setState(() => _autoDaily = value);
                          await _store.setAutoDaily(value);
                        },
                        title: Text('每天自动同步一次', style: context.texts.titleMedium),
                        subtitle: Text(
                          '不做原生后台任务，只在打开 App 时检查；失败会隔一小时再试。',
                          style: context.texts.labelSmall,
                        ),
                      ),
                      if (_autoError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '上次自动同步失败：$_autoError',
                          style: context.texts.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: '上次同步',
                  subtitle: _lastSyncAt == null
                      ? '还没有同步过'
                      : _formatTime(_lastSyncAt!) + (_lastSyncAt!.isUtc ? ' (UTC)' : ''),
                  child: _OutcomeView(outcome: _lastOutcome),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: '合并规则',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Rule('平时谁新用谁，撞车时你说了算', '只有一边改过就直接合并（较新的胜出）。两边都改过同一本书时不会自动覆盖，'
                          '会停下来让你逐本选择：用我的 / 用远端的 / 两个都留。'),
                      _Rule('正文提及会重新索引', '同步文件只带正文和实体表，提及是从正文重新扫出来的，不会带过去脏位置。'),
                      _Rule('删除会同步（带墓碑）', '删项目时留一条墓碑，别的设备同步时若本地版本更旧就跟着删；若删除之后又改过，则保留并复活。'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _OutcomeView extends StatelessWidget {
  const _OutcomeView({required this.outcome});

  final SyncOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    final data = outcome;
    if (data == null) {
      return Text('同步之后这里会显示拉了什么、推了什么。', style: context.texts.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (data.created.isNotEmpty) TagPill(label: '拉取新项目 ${data.created.length}', color: Mo.jade),
            if (data.updated.isNotEmpty) TagPill(label: '更新 ${data.updated.length}', color: Mo.indigo),
            if (data.removed.isNotEmpty)
              TagPill(label: '已删除 ${data.removed.length}', color: Mo.vermilion),
            if (data.skipped.isNotEmpty) TagPill(label: '本地较新 ${data.skipped.length}', color: Mo.gold),
            TagPill(
              label: data.pushed ? '已推送' : '未推送',
              color: data.pushed ? Theme.of(context).colorScheme.primary : null,
            ),
          ],
        ),
        if (data.created.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('拉取：${data.created.join('、')}', style: context.texts.bodySmall),
        ],
        if (data.updated.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('更新：${data.updated.join('、')}', style: context.texts.bodySmall),
        ],
        if (data.removed.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('删除：${data.removed.join('、')}', style: context.texts.bodySmall),
        ],
        if (data.commitSha != null) ...[
          const SizedBox(height: 10),
          Text(
            '提交 ${data.commitSha!.substring(0, 7)} · 分支 ${data.branch}',
            style: context.texts.labelSmall,
          ),
        ],
        for (final note in data.notes) ...[
          const SizedBox(height: 6),
          Text('· $note', style: context.texts.labelSmall),
        ],
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.texts.titleSmall),
          const SizedBox(height: 2),
          Text(body, style: context.texts.bodySmall?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}


/// 冲突面板：让作者逐本决定，而不是替他选。
class _ConflictDialog extends StatefulWidget {
  const _ConflictDialog({required this.conflicts});

  final List<SyncConflict> conflicts;

  @override
  State<_ConflictDialog> createState() => _ConflictDialogState();
}

class _ConflictDialogState extends State<_ConflictDialog> {
  late final Map<String, ConflictResolution> _choices = {
    for (final conflict in widget.conflicts) conflict.syncId: ConflictResolution.keepBoth,
  };

  String _time(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('这些书两边都改过'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '上次同步之后，本地和远端都动过同一本书。默认「两个都留」最安全。',
              style: context.texts.bodySmall?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.conflicts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.sunken,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conflict.title, style: context.texts.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          '本地 ${_time(conflict.localUpdatedAt)} · 远端 ${_time(conflict.remoteUpdatedAt)}',
                          style: context.texts.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final resolution in ConflictResolution.values)
                              ChoiceChip(
                                label: Text(
                                  resolution.label,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                                selected: _choices[conflict.syncId] == resolution,
                                onSelected: (_) => setState(
                                  () => _choices[conflict.syncId] = resolution,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('先不同步'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_choices),
          child: const Text('按这个来'),
        ),
      ],
    );
  }
}
