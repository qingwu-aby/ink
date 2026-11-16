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
  });

  final String provider;
  final String baseUrl;
  final String model;
  final String apiKey;

  bool get isReady => apiKey.trim().isNotEmpty && baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  static const presets = <String, (String, String)>{
    'deepseek': ('DeepSeek', 'https://api.deepseek.com/v1'),
    'openai': ('OpenAI', 'https://api.openai.com/v1'),
    'custom': ('自定义 / 兼容 OpenAI 协议', ''),
  };

  static const defaultModels = <String, String>{
    'deepseek': 'deepseek-chat',
    'openai': 'gpt-4o-mini',
    'custom': '',
  };

  LlmConfig copyWith({String? provider, String? baseUrl, String? model, String? apiKey}) => LlmConfig(
        provider: provider ?? this.provider,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        apiKey: apiKey ?? this.apiKey,
      );

  static const empty = LlmConfig(provider: 'deepseek', baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat', apiKey: '');
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
    final base = config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/chat/completions');
    final body = jsonEncode({
      'model': config.model.trim(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    });

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey.trim()}',
          }, body: body)
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw LlmException('请求超时（90 秒）。检查网络或换一个模型。');
    } catch (e) {
      throw LlmException('网络请求失败：$e');
    }

    if (response.statusCode != 200) {
      final snippet = response.body.length > 300 ? response.body.substring(0, 300) : response.body;
      throw LlmException('${response.statusCode} ${response.reasonPhrase}\n$snippet');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw LlmException('返回内容不是合法 JSON。');
    }
    if (decoded is! Map) throw LlmException('返回结构异常。');

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) throw LlmException('返回里没有 choices。');
    final message = _asMap(_asMap(choices.first)['message']);
    final content = '${message['content'] ?? ''}';

    final parsed = JsonX.objectFrom(content);
    if (parsed == null) {
      throw LlmException('模型没有按要求返回 JSON：\n${_trim(content, 240)}');
    }
    return parsed;
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
