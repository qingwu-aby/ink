import 'dart:convert';

/// 容错 JSON 工具：LLM 返回的 JSON 经常带 markdown 围栏、尾逗号、单引号。
abstract final class JsonX {
  /// 从任意文本里抠出第一个完整 JSON 对象/数组并解析。
  static Map<String, dynamic>? objectFrom(String raw) {
    final value = decodeLoose(raw);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  static Object? decodeLoose(String raw) {
    var text = raw.trim();
    // 去 markdown 围栏
    final fence = RegExp(r'^```(?:json)?\s*|\s*```$', multiLine: true);
    text = text.replaceAll(fence, '').trim();
    for (final candidate in [text, _sliceFrom(text, '{', '}'), _sliceFrom(text, '[', ']')]) {
      if (candidate == null || candidate.isEmpty) continue;
      try {
        return jsonDecode(_repair(candidate));
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  static String? _sliceFrom(String text, String open, String close) {
    final start = text.indexOf(open);
    final end = text.lastIndexOf(close);
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  /// 去掉尾逗号、把中文引号当普通字符留给 json 失败后重试。
  static String _repair(String text) {
    var out = text
        .replaceAllMapped(RegExp(r',\s*([}\]])'), (m) => m.group(1)!)
        .replaceAll('\u201c', '"')
        .replaceAll('\u201d', '"');
    return out;
  }

  static List<String> stringList(Object? value) {
    if (value is List) {
      return value
          .map((e) => e is String ? e : (e is Map ? '${e['name'] ?? e['text'] ?? ''}' : '$e'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[,，、/]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
