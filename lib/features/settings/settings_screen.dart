import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  List<String> _models = const [];
  List<LlmModel> _allModels = const [];
  bool _refreshingModels = false;
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
    _models = LlmConfig.presets[state.config.provider]?.models ?? const [];
    _key.text = state.config.apiKey;
  }

  bool get _selectedIsFree {
    final id = _model.text.trim();
    for (final model in _allModels) {
      if (model.id == id) return model.isFree;
    }
    return false;
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
                        label: entry.value.label,
                        selected: _provider == entry.key,
                        onTap: () {
                          setState(() {
                            _provider = entry.key;
                            _baseUrl.text = entry.value.baseUrl;
                            _model.text = entry.value.defaultModel;
                            _models = entry.value.models;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _baseUrl,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    hintText: LlmConfig.presets[_provider]?.baseUrl.isNotEmpty == true
                        ? LlmConfig.presets[_provider]!.baseUrl
                        : 'https://your-gateway/v1',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _model,
                  decoration: InputDecoration(
                    labelText: '模型',
                    hintText: LlmConfig.presets[_provider]?.defaultModel ?? 'model-id',
                  ),
                ),
                if (_models.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final model in _models)
                        _Choice(
                          label: model,
                          selected: _model.text == model,
                          onTap: () => setState(() => _model.text = model),
                        ),
                      if (_provider == 'opencodego') ...[
                        TextButton.icon(
                          onPressed: _refreshingModels ? null : _refreshModels,
                          icon: _refreshingModels
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, size: 16),
                          label: const Text('刷新列表', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton.icon(
                          onPressed: _allModels.isEmpty ? null : _pickModel,
                          icon: const Icon(Icons.list_alt, size: 16),
                          label: Text(
                            _allModels.isEmpty ? '全部模型' : '全部模型（${_allModels.length}）',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (_selectedIsFree) ...[
                  const SizedBox(height: 6),
                  Text(
                    '这是免费模型：网关只允许在 opencode 内部调用，外部客户端会被拒（402/403）。换成付费模型即可。',
                    style: context.texts.labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error, height: 1.5),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _key,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: _provider == 'opencodego'
                        ? '粘贴 OpenCode Console 里的 API Key'
                        : 'sk-…',
                    helperText: _provider == 'opencodego'
                        ? 'opencode.ai/console 订阅 Go 后即可获取；地址与模型已预置'
                        : null,
                  ),
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
            title: '同步',
            subtitle: '用你自己的 GitHub 私有仓库在三端之间搬运数据，不经任何中转服务',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sync_outlined, size: 20),
              title: Text('GitHub 同步', style: context.texts.titleMedium),
              subtitle: Text('仓库地址由你填，Token 只存本机', style: context.texts.labelSmall),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => context.push('/settings/sync'),
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
                    Image.asset(
                      'assets/logo/seal.png',
                      width: 32,
                      height: 32,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(width: 10),
                    Text('可道 1.0.0', style: context.texts.titleMedium),
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

  /// 全部模型选择器：带搜索，右侧标注该模型走的协议族。
  Future<void> _pickModel() async {
    final picked = await showModalBottomSheet<LlmModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ModelPicker(models: _allModels),
    );
    if (picked == null || !mounted) return;
    setState(() => _model.text = picked.id);
  }

  /// 拉一次实时模型列表（四种协议族都支持，全部可选）。
  Future<void> _refreshModels() async {
    final url = LlmConfig.presets[_provider]?.modelsUrl;
    if (url == null) return;
    setState(() => _refreshingModels = true);
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw LlmException('拉取模型列表失败（HTTP ${response.statusCode}）');
      }
      final preset = LlmConfig.presets[_provider]!;
      final catalog = preset.parseCatalog(response.body);
      if (catalog.isEmpty) throw LlmException('这个服务商没有可用的模型');
      final models = preset.parseModels(response.body);
      await ref.read(aiConfigProvider.notifier).saveCatalog(catalog);
      if (!mounted) return;
      setState(() => _allModels = models);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已刷新：${models.length} 个模型可用，点「全部模型」可选')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _refreshingModels = false);
    }
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
      final resolved = await ref.read(aiConfigProvider.notifier).resolve(config);
      await LlmClient(resolved).extract(
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

/// 全部模型列表：带搜索，右侧标注协议族（不同族请求走不同端点）。
class _ModelPicker extends StatefulWidget {
  const _ModelPicker({required this.models});

  final List<LlmModel> models;

  @override
  State<_ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<_ModelPicker> {
  String _query = '';

  static String _label(String api) => switch (api) {
        'responses' => 'Responses',
        'messages' => 'Messages',
        'generate-content' => 'Gemini',
        _ => 'Chat',
      };

  @override
  Widget build(BuildContext context) {
    final keyword = _query.trim().toLowerCase();
    final visible = keyword.isEmpty
        ? widget.models
        : [
            for (final model in widget.models)
              if (model.id.toLowerCase().contains(keyword) ||
                  model.name.toLowerCase().contains(keyword))
                model,
          ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: '搜模型，例如 kimi / gpt / claude',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final model = visible[index];
                return ListTile(
                  dense: true,
                  title: Text(model.id, style: context.texts.bodyMedium),
                  subtitle: Text(
                    model.isFree ? '${model.name} · 免费，仅 opencode 内可用' : model.name,
                    style: context.texts.labelSmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.sunken,
                      borderRadius: BorderRadius.circular(Radii.xs),
                    ),
                    child: Text(_label(model.api), style: const TextStyle(fontSize: 10.5)),
                  ),
                  onTap: () => Navigator.of(context).pop(model),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
