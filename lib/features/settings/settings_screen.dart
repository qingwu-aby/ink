import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/common.dart';
import '../../domain/llm/llm_client.dart';
import '../../domain/seed/demo_seed.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();
  final _key = TextEditingController();

  bool _enabled = false;
  String _provider = 'deepseek';
  bool _initialised = false;
  bool _testing = false;
  String? _testResult;

  void _init(AiConfigState state) {
    if (_initialised) return;
    _initialised = true;
    _enabled = state.enabled;
    _provider = state.config.provider;
    _baseUrl.text = state.config.baseUrl;
    _model.text = state.config.model;
    _key.text = state.config.apiKey;
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiAsync = ref.watch(aiConfigProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    final ai = aiAsync.value;
    if (ai != null) _init(ai);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SectionCard(
            title: '外观',
            child: Row(
              children: [
                for (final mode in const [
                  (ThemeMode.system, '跟随系统'),
                  (ThemeMode.light, '宣纸（浅）'),
                  (ThemeMode.dark, '夜（深）'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Choice(
                      label: mode.$2,
                      selected: themeMode == mode.$1,
                      onTap: () => ref.read(themeModeProvider.notifier).set(mode.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'AI 助手（实验）',
            subtitle: '不开启也完全可用。开启后可以读旧稿抽实体、审校本章一致性。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                  title: Text('启用 AI 助手', style: context.texts.titleMedium),
                  subtitle: Text('API Key 只存在本机钥匙串里', style: context.texts.labelSmall),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in LlmConfig.presets.entries)
                      _Choice(
                        label: entry.value.$1,
                        selected: _provider == entry.key,
                        onTap: () {
                          setState(() {
                            _provider = entry.key;
                            _baseUrl.text = entry.value.$2;
                            _model.text = LlmConfig.defaultModels[entry.key] ?? '';
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _baseUrl,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.deepseek.com/v1',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _model,
                  decoration: const InputDecoration(labelText: '模型', hintText: 'deepseek-chat'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _key,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'API Key', hintText: 'sk-…'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _testing ? null : _test,
                        child: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('测试连接'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 10),
                  Text(_testResult!, style: context.texts.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: '数据',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, size: 20),
                  title: Text('回收站', style: context.texts.titleMedium),
                  subtitle: Text('删掉的作品留 30 天，误删能捞回来', style: context.texts.labelSmall),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => context.push('/settings/trash'),
                ),
                Divider(color: context.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('重建示例项目《${DemoSeed.projectTitle}》', style: context.texts.titleMedium),
                  subtitle: Text('删掉旧的示例，重新铺一份带图谱和正文的演示数据', style: context.texts.labelSmall),
                  trailing: const Icon(Icons.refresh, size: 18),
                  onTap: _reseed,
                ),
                Divider(color: context.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '清空所有作品',
                    style: context.texts.titleMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                  subtitle: Text('本机数据全部删除，不可恢复', style: context.texts.labelSmall),
                  trailing: const Icon(Icons.delete_forever_outlined, size: 18),
                  onTap: _wipe,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: '关于',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '墨',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontFamily: Serif.family,
                          fontFamilyFallback: Serif.fallback,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('墨谱 0.1.0', style: context.texts.titleMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '本地优先的小说写作知识图谱。正文与图谱双向绑定，'
                  '所有数据只存在这台设备上，不联网也能写。',
                  style: context.texts.bodySmall?.copyWith(height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final config = LlmConfig(
      provider: _provider,
      baseUrl: _baseUrl.text.trim(),
      model: _model.text.trim(),
      apiKey: _key.text.trim(),
    );
    await ref.read(aiConfigProvider.notifier).save(AiConfigState(enabled: _enabled, config: config));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final config = LlmConfig(
      provider: _provider,
      baseUrl: _baseUrl.text.trim(),
      model: _model.text.trim(),
      apiKey: _key.text.trim(),
    );
    try {
      await LlmClient(config).extract(
        text: '沈砚之推开听雨楼的门，苏鸢正在算账。',
        knownNames: const [],
      );
      if (!mounted) return;
      setState(() => _testResult = '连接正常，模型能按格式返回 JSON。');
    } catch (error) {
      if (!mounted) return;
      setState(() => _testResult = '失败：$error');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _reseed() async {
    final db = ref.read(databaseProvider);
    await db.removeSetting('demo.seeded');
    final projects = await db.watchProjects().first;
    final deviceId = await db.getSetting('sync.deviceId') ?? '';
    for (final project in projects) {
      if (project.title == DemoSeed.projectTitle) {
        // 重建示例 = 真的不要了，直接彻底删除
        await db.purgeProject(project.id, deviceId: deviceId);
      }
    }
    await DemoSeed.ensure(db);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('示例项目已重建')));
    context.go('/');
  }

  Future<void> _wipe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有作品？'),
        content: const Text('作品、章节、实体、关系全部删除，且无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('全部删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(databaseProvider);
    final deviceId = await db.getSetting('sync.deviceId') ?? '';
    final projects = await db.allProjects();
    for (final project in projects) {
      await db.purgeProject(project.id, deviceId: deviceId);
    }
    await db.setSetting('demo.seeded', '1');
    if (!mounted) return;
    context.go('/');
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? base.withValues(alpha: 0.13) : context.sunken,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? base.withValues(alpha: 0.42) : context.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? base : context.soft,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
