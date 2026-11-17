import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/db/app_database.dart';
import 'llm_client.dart';

/// AI 配置的持久化：普通字段进 SQLite，API Key 优先进系统钥匙串。
class AiSettingsStore {
  AiSettingsStore(this._db, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final AppDatabase _db;
  final FlutterSecureStorage _storage;

  static const _kEnabled = 'ai.enabled';
  static const _kProvider = 'ai.provider';
  static const _kBaseUrl = 'ai.baseUrl';
  static const _kModel = 'ai.model';
  static const _kKeychainKey = 'mopu_llm_api_key';
  static const _kCatalog = 'ai.catalog';
  static const _kSession = 'ai.sessionId';

  Future<bool> isEnabled() async => (await _db.getSetting(_kEnabled)) == '1';

  Future<LlmConfig> load() async {
    final provider = await _db.getSetting(_kProvider) ?? 'deepseek';
    final baseUrl = await _db.getSetting(_kBaseUrl) ?? LlmConfig.presets[provider]!.baseUrl;
    final model = await _db.getSetting(_kModel) ?? LlmConfig.presets[provider]!.defaultModel;
    final config = LlmConfig(
      provider: provider,
      baseUrl: baseUrl,
      model: model,
      apiKey: await readKey() ?? '',
    );
    return resolve(config);
  }

  /// 补上「这个模型走哪个协议族、打哪个地址」，以及 Go 网关要的路由头。
  Future<LlmConfig> resolve(LlmConfig config) async {
    final session = await _ensureSession();
    final catalog = await loadCatalog();
    final entry = catalog[config.model.trim()];
    if (entry == null) {
      return config.copyWith(sessionId: session);
    }
    return config.copyWith(
      modelApi: LlmApi.parse(entry['api']),
      // 目录里的地址可能属于别的网关，只在同一网关内才采用
      apiBaseUrl: _sameGateway(config.baseUrl, '${entry['baseUrl'] ?? ''}')
          ? '${entry['baseUrl'] ?? ''}'
          : '',
      sessionId: session,
    );
  }

  /// Go 网关要求每次请求带一个稳定的 x-opencode-session；装一次生成一次即可。
  Future<String> _ensureSession() async {
    final existing = await _db.getSetting(_kSession);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final value = 'kedao-$id';
    await _db.setSetting(_kSession, value);
    return value;
  }

  /// 判断目录里的地址和当前配置是不是同一个网关（都指向 opencode.ai 的 Go 或通用入口）。
  static bool _sameGateway(String configured, String fromCatalog) {
    if (fromCatalog.isEmpty) return false;
    bool isGo(String url) => url.contains('/inference/go/');
    return isGo(configured) == isGo(fromCatalog);
  }

  Future<Map<String, Map<String, String>>> loadCatalog() async {
    final raw = await _db.getSetting(_kCatalog);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, Map<String, String>>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          out['$key'] = {
            'api': '${value['api'] ?? ''}',
            'baseUrl': '${value['baseUrl'] ?? ''}',
          };
        }
      });
      return out;
    } on FormatException {
      return const {};
    }
  }

  Future<void> saveCatalog(Map<String, Map<String, String>> catalog) async {
    await _db.setSetting(_kCatalog, jsonEncode(catalog));
  }

  Future<void> save({required bool enabled, required LlmConfig config}) async {
    await _db.setSetting(_kEnabled, enabled ? '1' : '0');
    await _db.setSetting(_kProvider, config.provider);
    await _db.setSetting(_kBaseUrl, config.baseUrl);
    await _db.setSetting(_kModel, config.model);
    await writeKey(config.apiKey);
  }

  /// 钥匙串在部分桌面环境会抛异常，此时退回到本地库里存（仍是单机本地文件）。
  Future<String?> readKey() async {
    try {
      final value = await _storage.read(key: _kKeychainKey);
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // 忽略，走回退
    }
    return _db.getSetting('$_kKeychainKey.fallback');
  }

  Future<void> writeKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      try {
        await _storage.delete(key: _kKeychainKey);
      } catch (_) {}
      await _db.removeSetting('$_kKeychainKey.fallback');
      return;
    }
    try {
      await _storage.write(key: _kKeychainKey, value: trimmed);
      await _db.removeSetting('$_kKeychainKey.fallback');
    } catch (_) {
      await _db.setSetting('$_kKeychainKey.fallback', trimmed);
    }
  }
}
