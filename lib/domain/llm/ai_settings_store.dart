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

  Future<bool> isEnabled() async => (await _db.getSetting(_kEnabled)) == '1';

  Future<LlmConfig> load() async {
    final provider = await _db.getSetting(_kProvider) ?? 'deepseek';
    final baseUrl = await _db.getSetting(_kBaseUrl) ?? LlmConfig.presets[provider]!.baseUrl;
    final model = await _db.getSetting(_kModel) ?? LlmConfig.presets[provider]!.defaultModel;
    return LlmConfig(
      provider: provider,
      baseUrl: baseUrl,
      model: model,
      apiKey: await readKey() ?? '',
    );
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
