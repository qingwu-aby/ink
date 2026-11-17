import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/json_x.dart';
import '../taxonomy.dart';

class LlmException implements Exception {
  LlmException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LlmConfig {
  const LlmConfig({
    required this.provider,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    this.modelApi = LlmApi.chat,
    this.apiBaseUrl = '',
    this.sessionId = '',
  });

  final String provider;
  final String baseUrl;
  final String model;
  final String apiKey;

  /// 这个模型走的协议族（由模型目录得出，默认 chat-completions）
  final LlmApi modelApi;

  /// 该协议族的实际地址（目录里带；为空时按网关约定推导）
  final String apiBaseUrl;

  /// OpenCode Go 网关要求的路由头值（稳定复用上下文缓存）
  final String sessionId;

  /// Go 专属网关必须带 x-opencode-session，通用入口不需要
  bool get needsSessionHeader =>
      provider == 'opencodego' || resolvedBaseUrl.contains('/inference/go/');

  /// 真正要打的地方：目录给了就用目录的，否则按 opencode 网关的路径约定推导
  String get resolvedBaseUrl {
    final fromCatalog = apiBaseUrl.trim();
    if (fromCatalog.isNotEmpty) return fromCatalog.replaceAll(RegExp(r'/+$'), '');
    final root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return switch (modelApi) {
      LlmApi.messages => root.replaceFirst('/openai/v1', '/anthropic/v1'),
      LlmApi.generateContent => root.replaceFirst('/openai/v1', '/google/v1beta'),
      _ => root,
    };
  }

  bool get isReady => apiKey.trim().isNotEmpty && baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  static const presets = <String, LlmPreset>{
    'deepseek': LlmPreset(
      label: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
      models: ['deepseek-chat', 'deepseek-reasoner'],
    ),
    'openai': LlmPreset(
      label: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o-mini',
      models: ['gpt-4o-mini', 'gpt-4o'],
    ),
    // Go 订阅走专属网关（/inference/go/...），和按量付费是两个入口
    'opencodego': LlmPreset(
      label: 'OpenCode Go',
      baseUrl: 'https://opencode.ai/inference/go/openai/v1',
      defaultModel: 'glm-5.3',
      modelsUrl: 'https://opencode.ai/inference/go/v1/models',
      models: [
        'glm-5.3',
        'kimi-k3',
        'minimax-m3',
        'deepseek-v4.1-flash',
        'glm-5.3-flash',
        'qwen3.8-max',
        'deepseek-v4-pro',
      ],
    ),
    // 按量付费（OpenCode Models credits）：与 Go 订阅互不覆盖
    'opencode': LlmPreset(
      label: 'OpenCode 按量付费',
      baseUrl: 'https://opencode.ai/inference/openai/v1',
      defaultModel: 'glm-5.3',
      modelsUrl: 'https://opencode.ai/inference/v1/models',
      models: ['glm-5.3', 'kimi-k3', 'minimax-m3'],
    ),
    'custom': LlmPreset(label: '自定义 / 兼容 OpenAI 协议', baseUrl: ''),
  };

  static String defaultModelOf(String provider) => presets[provider]?.defaultModel ?? '';

  LlmConfig copyWith({
    String? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
    LlmApi? modelApi,
    String? apiBaseUrl,
    String? sessionId,
  }) =>
      LlmConfig(
        provider: provider ?? this.provider,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        apiKey: apiKey ?? this.apiKey,
        modelApi: modelApi ?? this.modelApi,
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
        sessionId: sessionId ?? this.sessionId,
      );

  static const empty = LlmConfig(provider: 'deepseek', baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat', apiKey: '');
}

/// 网关的四种协议族。每个模型只支持其中一种。
enum LlmApi {
  chat('chat-completions'),
  responses('responses'),
  messages('messages'),
  generateContent('generate-content');

  const LlmApi(this.key);
  final String key;

  static LlmApi parse(String? value) {
    final needle = (value ?? '').trim();
    for (final api in LlmApi.values) {
      if (api.key == needle) return api;
    }
    return LlmApi.chat;
  }

  bool get isJsonMode => this == LlmApi.chat;
}

/// 按协议族拼请求、取正文。抽成纯函数，方便单测覆盖四种协议。
class LlmWire {
  const LlmWire._();

  static Uri uri(LlmConfig config) {
    final base = config.resolvedBaseUrl;
    return switch (config.modelApi) {
      LlmApi.chat => Uri.parse('$base/chat/completions'),
      LlmApi.responses => Uri.parse('$base/responses'),
      LlmApi.messages => Uri.parse('$base/messages'),
      LlmApi.generateContent =>
        Uri.parse('$base/models/${Uri.encodeComponent(config.model.trim())}:generateContent'),
    };
  }

  static Map<String, String> headers(LlmConfig config) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey.trim()}',
        if (config.modelApi == LlmApi.messages) 'anthropic-version': '2023-06-01',
        // Go 网关缺这个头会直接 400 MissingSessionID
        if (config.needsSessionHeader) 'x-opencode-session': config.sessionId,
      };

  static String body({
    required LlmConfig config,
    required String system,
    required String user,
    int maxTokens = 2600,
    double temperature = 0.2,
  }) {
    final model = config.model.trim();
    final payload = switch (config.modelApi) {
      LlmApi.chat => {
          'model': model,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
        },
      LlmApi.responses => {
          'model': model,
          'instructions': system,
          'max_output_tokens': maxTokens,
          'input': [
            {
              'role': 'user',
              'content': [
                {'type': 'input_text', 'text': user},
              ],
            },
          ],
        },
      LlmApi.messages => {
          'model': model,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'system': system,
          'messages': [
            {'role': 'user', 'content': user},
          ],
        },
      LlmApi.generateContent => {
          'systemInstruction': {
            'parts': [
              {'text': system},
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': user},
              ],
            },
          ],
          'generationConfig': {'temperature': temperature, 'maxOutputTokens': maxTokens},
        },
    };
    return jsonEncode(payload);
  }

  /// 从四种返回结构里抠出正文。
  static String text(LlmConfig config, Map<String, dynamic> decoded) {
    switch (config.modelApi) {
      case LlmApi.chat:
        final choices = decoded['choices'];
        if (choices is! List || choices.isEmpty) return '';
        final message = choices.first is Map ? (choices.first as Map)['message'] : null;
        return message is Map ? "${message['content'] ?? ''}" : '';
      case LlmApi.responses:
        final out = decoded['output'];
        if (out is! List) return '';
        final buffer = StringBuffer();
        for (final item in out) {
          if (item is! Map) continue;
          final content = item['content'];
          if (content is! List) continue;
          for (final part in content) {
            if (part is! Map) continue;
            final text = part['text'];
            if (text is String && text.isNotEmpty) buffer.write(text);
          }
        }
        return buffer.toString();
      case LlmApi.messages:
        final content = decoded['content'];
        if (content is! List) return '';
        final buffer = StringBuffer();
        for (final part in content) {
          if (part is! Map || part['type'] != 'text') continue;
          final text = part['text'];
          if (text is String) buffer.write(text);
        }
        return buffer.toString();
      case LlmApi.generateContent:
        final candidates = decoded['candidates'];
        if (candidates is! List || candidates.isEmpty) return '';
        final first = candidates.first;
        if (first is! Map) return '';
        final content = first['content'];
        if (content is! Map) return '';
        final parts = content['parts'];
        if (parts is! List) return '';
        final buffer = StringBuffer();
        for (final part in parts) {
          if (part is! Map) continue;
          final text = part['text'];
          if (text is String) buffer.write(text);
        }
        return buffer.toString();
    }
  }
}

/// 一个服务商的预置：地址、默认模型、可选模型。
class LlmPreset {
  const LlmPreset({
    required this.label,
    required this.baseUrl,
    this.defaultModel = '',
    this.models = const [],
    this.modelsUrl,
  });

  final String label;
  final String baseUrl;
  final String defaultModel;

  /// 可点的模型清单（离线兜底；OpenCode Go 还能在线刷新）
  final List<String> models;

  /// 能拉到实时模型列表的地址
  final String? modelsUrl;

  /// 解析网关的模型目录：保留每个模型支持的协议族与该族地址。
  Map<String, Map<String, String>> parseCatalog(String body) {
    final decoded = jsonDecode(body);
    final data = decoded is Map ? decoded['data'] : null;
    if (data is! List) return const {};
    final out = <String, Map<String, String>>{};
    for (final raw in data) {
      if (raw is! Map) continue;
      final id = raw['id'];
      if (id is! String || id.isEmpty) continue;
      final api = raw['api'];
      if (api is! Map || api.isEmpty) continue;
      final family = api.keys.first;
      final config = api[family];
      final baseUrl = config is Map ? '${config['base_url'] ?? ''}' : '';
      out[id] = {'api': '$family', 'baseUrl': baseUrl};
    }
    return out;
  }

  /// 列出目录里的模型（四种协议族都支持了，所以这里不再过滤）。
  List<LlmModel> parseModels(String body) {
    final decoded = jsonDecode(body);
    final data = decoded is Map ? decoded['data'] : null;
    if (data is! List) return const [];
    final out = <LlmModel>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      final id = raw['id'];
      if (id is! String || id.isEmpty) continue;
      final api = raw['api'];
      if (api is! Map || api.isEmpty) continue;
      final name = raw['name'] is String ? raw['name'] as String : id;
      out.add(LlmModel(
        id: id,
        name: name,
        api: '${api.keys.first}',
        isFree: _isFree(raw['cost']),
      ));
    }
    // 付费的排前面：免费模型在 App 里调不通，不该抢眼
    out.sort((a, b) {
      if (a.isFree != b.isFree) return a.isFree ? 1 : -1;
      return a.id.compareTo(b.id);
    });
    return out;
  }

  static bool _isFree(Object? cost) {
    if (cost is! Map) return false;
    final text = cost['text'];
    if (text is! Map) return false;
    final input = text['input'];
    final output = text['output'];
    double price(Object? part) {
      if (part is! Map) return -1;
      final value = part['price'];
      return value is num ? value.toDouble() : -1;
    }

    return price(input) == 0 && price(output) == 0;
  }
}

class LlmModel {
  const LlmModel({
    required this.id,
    required this.name,
    this.api = 'chat-completions',
    this.isFree = false,
  });

  final String id;
  final String name;

  /// 这个模型走的协议族（chat-completions / responses / messages / generate-content）
  final String api;

  /// 标价 0 的免费模型：网关只允许在 opencode 内部调用，外部客户端会被拒
  final bool isFree;
}

class AiEntityDraft {
  const AiEntityDraft({required this.name, required this.kind, required this.aliases, required this.summary});

  final String name;
  final EntityKind kind;
  final List<String> aliases;
  final String summary;
}

class AiRelationDraft {
  const AiRelationDraft({required this.from, required this.to, required this.kind, required this.note});

  final String from;
  final String to;
  final String kind;
  final String note;
}

class AiExtraction {
  const AiExtraction({required this.entities, required this.relations});

  final List<AiEntityDraft> entities;
  final List<AiRelationDraft> relations;

  bool get isEmpty => entities.isEmpty && relations.isEmpty;
}

class AiIssue {
  const AiIssue({required this.title, required this.detail});
  final String title;
  final String detail;
}

/// 走 OpenAI 兼容的 /chat/completions 协议。DeepSeek / OpenAI / 本地网关都能用。
class LlmClient {
  LlmClient(this.config, {http.Client? client}) : _client = client ?? http.Client();

  final LlmConfig config;
  final http.Client _client;

  Future<AiExtraction> extract({
    required String text,
    required List<String> knownNames,
    String projectTitle = '',
  }) async {
    final known = knownNames.isEmpty ? '（无）' : knownNames.take(80).join('、');
    final payload = await _chatJson(
      system: '''你是小说结构编辑。从给定章节正文中抽取「实体」与「实体之间的关系」，输出严格 JSON。

实体类型 kind 只能取：character（人物）、location（地点）、item（物品）、faction（势力/组织）、event（关键事件）、concept（设定/功法/规则）。
关系类型 kind 只能取：parent sibling clan spouse mentor friend liege ally enemy rival crush knows other。

规则：
1. 只抽取正文里真实出现、且对故事有意义的对象，不要臆造。
2. 人物的 aliases 放正文中的别称、字号、绰号。
3. summary 一句话（40 字以内），写清身份与当前处境。
4. relations 的 from/to 必须用 entities 里出现过的 name。
5. 已在知识库中的名字：$known。若正文中出现别称能对应到已有名字，请把已有名字写进 aliases 并在 name 用已有名字。

输出 JSON：{"entities":[{"name":"","kind":"character","aliases":[],"summary":""}],"relations":[{"from":"","to":"","kind":"enemy","note":""}]}''',
      user: '书名：${projectTitle.isEmpty ? '未命名' : projectTitle}\n\n正文：\n${_trim(text, 6000)}',
    );

    final entities = <AiEntityDraft>[];
    for (final raw in _asList(payload['entities'])) {
      final map = _asMap(raw);
      final name = '${map['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      entities.add(AiEntityDraft(
        name: name,
        kind: EntityKind.parse('${map['kind'] ?? 'character'}'.toLowerCase()),
        aliases: JsonX.stringList(map['aliases']),
        summary: '${map['summary'] ?? ''}'.trim(),
      ));
    }

    final relations = <AiRelationDraft>[];
    for (final raw in _asList(payload['relations'])) {
      final map = _asMap(raw);
      final from = '${map['from'] ?? ''}'.trim();
      final to = '${map['to'] ?? ''}'.trim();
      if (from.isEmpty || to.isEmpty || from == to) continue;
      relations.add(AiRelationDraft(
        from: from,
        to: to,
        kind: '${map['kind'] ?? 'other'}'.trim(),
        note: '${map['note'] ?? ''}'.trim(),
      ));
    }

    return AiExtraction(entities: entities, relations: relations);
  }

  Future<List<AiIssue>> review({
    required String bible,
    required String chapterText,
  }) async {
    final payload = await _chatJson(
      system: '''你是小说的一致性审校。依据「设定档」检查「本章正文」，只报告确实存在的矛盾，输出严格 JSON。

重点检查：人物身份/称谓错乱、已死人物出场、与设定档冲突的细节、时间线倒挂、关系与描写不符。
不要报告文笔问题，不要编造问题。没有问题时返回空数组。

输出 JSON：{"issues":[{"title":"20字以内","detail":"指出在正文哪一句、与设定档哪条冲突"}]}''',
      user: '设定档：\n${_trim(bible, 4000)}\n\n本章正文：\n${_trim(chapterText, 5000)}',
      maxTokens: 1500,
      temperature: 0.1,
    );
    final issues = <AiIssue>[];
    for (final raw in _asList(payload['issues'])) {
      final map = _asMap(raw);
      final title = '${map['title'] ?? ''}'.trim();
      final detail = '${map['detail'] ?? ''}'.trim();
      if (title.isEmpty && detail.isEmpty) continue;
      issues.add(AiIssue(title: title.isEmpty ? '未命名问题' : title, detail: detail));
    }
    return issues;
  }

  Future<Map<String, dynamic>> _chatJson({
    required String system,
    required String user,
    int maxTokens = 2600,
    double temperature = 0.2,
  }) async {
    if (!config.isReady) {
      throw LlmException('还没有配置 API Key / 模型，先去「设置 → AI 助手」填一下。');
    }
    // 按模型声明的协议族选端点：chat / responses / messages / generate-content
    final uri = LlmWire.uri(config);
    final body = LlmWire.body(
      config: config,
      system: system,
      user: user,
      maxTokens: maxTokens,
      temperature: temperature,
    );

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: LlmWire.headers(config), body: body)
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw LlmException('请求超时（90 秒）。检查网络或换一个模型。');
    } catch (e) {
      throw LlmException('网络请求失败：$e');
    }

    if (response.statusCode != 200) {
      throw LlmException(_describeError(response.statusCode, response.body));
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw LlmException('返回内容不是合法 JSON。');
    }
    if (decoded is! Map) throw LlmException('返回结构异常。');

    final content = LlmWire.text(config, _asMap(decoded));
    if (content.trim().isEmpty) {
      throw LlmException('模型没有返回内容（协议族 ${config.modelApi.key}）。'
          '如果模型 ID 是手填的，点「刷新列表」选一次，让它认对协议。');
    }

    final parsed = JsonX.objectFrom(content);
    if (parsed == null) {
      throw LlmException('模型没有按要求返回 JSON：\n${_trim(content, 240)}');
    }
    return parsed;
  }

  /// 把 HTTP 错误翻成「该去哪儿改什么」，而不是把 402 原样抛给用户。
  String _describeError(int status, String body) {
    final detail = _errorMessage(body);
    final where = '网关返回 $status';
    return switch (status) {
      401 => 'API Key 无效或已过期，重新复制一次。（$where）',
      402 => '额度不足：这个 Key 所在的 workspace 没有可用的 OpenCode Go 订阅或余额。'
          '去 opencode.ai/console 确认三件事：① 已订阅 Go / Go Plus；'
          '② 这个 Key 属于同一个 workspace；③ 本月额度还没用完。'
          '另外，带 -free 的模型只能在 opencode 内部用，外部客户端调不通，换一个付费模型试试。'
          '（$where${detail.isEmpty ? '' : '：$detail'}）',
      403 => '这个模型不允许外部调用：免费模型只能在 opencode 内部使用，'
          '或者这个 Key 没有该模型的权限。换一个付费模型。（$where${detail.isEmpty ? '' : '：$detail'}）',
      404 => '模型不存在，或者 API 地址写错了：检查模型 ID 和 Base URL 末尾是不是 /v1。'
          '（$where${detail.isEmpty ? '' : '：$detail'}）',
      429 => '请求太频繁，被限流了，等一会儿再试。（$where）',
      >= 500 => '网关出错（$status），稍后再试。${detail.isEmpty ? '' : '：$detail'}',
      _ => '$where ${body.length > 240 ? '${body.substring(0, 240)}…' : body}',
    };
  }

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) return '${error['message']}';
        if (decoded['message'] is String) return '${decoded['message']}';
      }
    } on FormatException {
      // 不是 JSON 就算了
    }
    return body.length > 160 ? '${body.substring(0, 160)}…' : body.trim();
  }

  static String _trim(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}\n……（已截断）';

  static List<Object?> _asList(Object? value) => value is List ? value : const [];

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return const {};
  }
}
