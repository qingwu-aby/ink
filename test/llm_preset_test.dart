import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/domain/llm/llm_client.dart';

void main() {
  test('OpenCode Go 预置：地址、默认模型、可点模型都在', () {
    final preset = LlmConfig.presets['opencodego']!;
    expect(preset.label, 'OpenCode Go');
    expect(preset.baseUrl, 'https://opencode.ai/inference/openai/v1');
    expect(preset.defaultModel, isNotEmpty);
    expect(preset.models, contains(preset.defaultModel));
    expect(preset.models, containsAll(['glm-5.3', 'kimi-k3', 'minimax-m3']));
    expect(preset.modelsUrl, 'https://opencode.ai/inference/v1/models');
  });

  test('每个预置的默认模型都在自己的清单里（或清单为空）', () {
    for (final entry in LlmConfig.presets.entries) {
      final preset = entry.value;
      if (preset.models.isEmpty) continue;
      expect(preset.models, contains(preset.defaultModel),
          reason: '${entry.key} 的默认模型不在可选清单里');
    }
  });

  test('模型列表只保留 chat-completions 家族', () {
    final preset = LlmConfig.presets['opencodego']!;
    final body = jsonEncode({
      'data': [
        {'id': 'a-chat', 'name': 'A', 'api': {'chat-completions': {}}},
        {'id': 'b-responses', 'name': 'B', 'api': {'responses': {}}},
        {'id': '', 'name': '空 id 要跳过'},
        {'id': 'c-chat', 'name': 'C', 'api': {'chat-completions': {}}},
      ],
    });
    final models = preset.parseModels(body);
    expect(models.map((m) => m.id).toList(), ['a-chat', 'c-chat']);
  });

  test('请求地址是 baseUrl + /chat/completions', () {
    final preset = LlmConfig.presets['opencodego']!;
    final uri = Uri.parse('${preset.baseUrl}/chat/completions');
    expect(uri.toString(), 'https://opencode.ai/inference/openai/v1/chat/completions');
  });
}
