import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/data/db/app_database.dart';
import 'package:kedao/domain/llm/ai_settings_store.dart';
import 'package:kedao/domain/llm/llm_client.dart';

LlmConfig cfg(LlmApi api, {String model = 'x'}) => LlmConfig(
      provider: 'opencodego',
      baseUrl: 'https://opencode.ai/inference/openai/v1',
      model: model,
      apiKey: 'k',
      modelApi: api,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('端点按协议族走', () {
    test('chat → /chat/completions', () {
      expect(LlmWire.uri(cfg(LlmApi.chat)).toString(),
          'https://opencode.ai/inference/openai/v1/chat/completions');
    });

    test('responses → /responses', () {
      expect(LlmWire.uri(cfg(LlmApi.responses)).toString(),
          'https://opencode.ai/inference/openai/v1/responses');
    });

    test('messages → 自动换成 anthropic 路径', () {
      final uri = LlmWire.uri(cfg(LlmApi.messages));
      expect(uri.toString(), 'https://opencode.ai/inference/anthropic/v1/messages');
      expect(LlmWire.headers(cfg(LlmApi.messages))['anthropic-version'], isNotNull);
    });

    test('generate-content → google 路径，模型名进 URI', () {
      final uri = LlmWire.uri(cfg(LlmApi.generateContent, model: 'gemini-4-argon'));
      expect(uri.toString(),
          'https://opencode.ai/inference/google/v1beta/models/gemini-4-argon:generateContent');
    });

    test('目录给了地址就优先用目录的', () {
      final config = cfg(LlmApi.messages).copyWith(
        apiBaseUrl: 'https://proxy.example/anthropic/v1',
      );
      expect(LlmWire.uri(config).toString(), 'https://proxy.example/anthropic/v1/messages');
    });
  });

  group('请求体', () {
    test('chat 带 response_format', () {
      final body = jsonDecode(LlmWire.body(config: cfg(LlmApi.chat), system: 'S', user: 'U'));
      expect(body['messages'][0]['role'], 'system');
      expect(body['response_format']['type'], 'json_object');
    });

    test('responses 用 instructions + input', () {
      final body = jsonDecode(LlmWire.body(config: cfg(LlmApi.responses), system: 'S', user: 'U'));
      expect(body['instructions'], 'S');
      expect(body['input'][0]['content'][0]['type'], 'input_text');
      expect(body.containsKey('messages'), isFalse);
    });

    test('messages 用 system + max_tokens（必填）', () {
      final body = jsonDecode(LlmWire.body(config: cfg(LlmApi.messages), system: 'S', user: 'U'));
      expect(body['system'], 'S');
      expect(body['max_tokens'], greaterThan(0));
      expect(body['messages'][0]['content'], 'U');
    });

    test('generate-content 用 contents + systemInstruction', () {
      final body =
          jsonDecode(LlmWire.body(config: cfg(LlmApi.generateContent), system: 'S', user: 'U'));
      expect(body['systemInstruction']['parts'][0]['text'], 'S');
      expect(body['contents'][0]['parts'][0]['text'], 'U');
      expect(body['generationConfig']['maxOutputTokens'], greaterThan(0));
    });
  });

  group('取正文', () {
    test('chat', () {
      final text = LlmWire.text(cfg(LlmApi.chat), {
        'choices': [
          {'message': {'content': '{"a":1}'}}
        ]
      });
      expect(text, '{"a":1}');
    });

    test('responses：跳过 reasoning，只取 output_text', () {
      final text = LlmWire.text(cfg(LlmApi.responses), {
        'output': [
          {'type': 'reasoning', 'summary': []},
          {
            'type': 'message',
            'content': [
              {'type': 'output_text', 'text': '{"a":'},
              {'type': 'output_text', 'text': '1}'},
            ],
          },
        ],
      });
      expect(text, '{"a":1}');
    });

    test('messages：只取 type=text 的段', () {
      final text = LlmWire.text(cfg(LlmApi.messages), {
        'content': [
          {'type': 'thinking', 'thinking': '...'},
          {'type': 'text', 'text': '{"a":1}'},
        ],
      });
      expect(text, '{"a":1}');
    });

    test('generate-content', () {
      final text = LlmWire.text(cfg(LlmApi.generateContent), {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '{"a":1}'}
              ]
            }
          }
        ]
      });
      expect(text, '{"a":1}');
    });
  });

  group('错误说明', () {
    test('免费模型能认出来（价格 0）', () {
      const body = '''
{"data":[
 {"id":"paid-model","name":"Paid","cost":{"text":{"input":{"price":1},"output":{"price":2}}},"api":{"chat-completions":{}}},
 {"id":"free-model","name":"Free","cost":{"text":{"input":{"price":0},"output":{"price":0}}},"api":{"chat-completions":{}}}
]}''';
      final models = LlmConfig.presets['opencodego']!.parseModels(body);
      expect(models.firstWhere((m) => m.id == 'free-model').isFree, isTrue);
      expect(models.firstWhere((m) => m.id == 'paid-model').isFree, isFalse);
      // 付费的排在前面
      expect(models.first.id, 'paid-model');
    });
  });

  group('模型目录', () {
    const body = '''
{"data":[
 {"id":"m-chat","name":"M Chat","api":{"chat-completions":{"base_url":"B1"}}},
 {"id":"m-resp","name":"M Resp","api":{"responses":{"base_url":"B2"}}},
 {"id":"m-msg","name":"M Msg","api":{"messages":{"base_url":"B3"}}},
 {"id":"m-gem","name":"M Gem","api":{"generate-content":{"base_url":"B4"}}},
 {"id":"no-api","name":"No API"}
]}''';

    test('四种族都收下，并记住各自地址', () {
      final preset = LlmConfig.presets['opencodego']!;
      final catalog = preset.parseCatalog(body);
      expect(catalog.length, 4);
      expect(catalog['m-resp']!['api'], 'responses');
      expect(catalog['m-msg']!['baseUrl'], 'B3');
      expect(catalog.containsKey('no-api'), isFalse);

      final models = preset.parseModels(body);
      expect(models.map((m) => m.api), containsAll(['responses', 'messages', 'generate-content']));
    });

    test('存了目录后，手填的模型也能认出协议族', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final store = AiSettingsStore(db);
      final preset = LlmConfig.presets['opencodego']!;
      await store.saveCatalog(preset.parseCatalog(body));

      final resolved = await store.resolve(LlmConfig(
        provider: 'opencodego',
        baseUrl: preset.baseUrl,
        model: 'm-msg',
        apiKey: 'k',
      ));
      expect(resolved.modelApi, LlmApi.messages);
      expect(resolved.apiBaseUrl, 'B3');

      // 目录里没有的模型：退回 chat，不炸
      final unknown = await store.resolve(LlmConfig(
        provider: 'opencodego',
        baseUrl: preset.baseUrl,
        model: 'something-new',
        apiKey: 'k',
      ));
      expect(unknown.modelApi, LlmApi.chat);
      expect(unknown.apiBaseUrl, isEmpty);

      await db.close();
    });
  });
}
