import 'dart:convert';

/// 中英混排字数：汉字按字计，拉丁单词按词计。
int countWords(String text) {
  if (text.isEmpty) return 0;
  final cjk = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]').allMatches(text).length;
  final latin = RegExp(r"[A-Za-z0-9][A-Za-z0-9'\-]*").allMatches(text).length;
  return cjk + latin;
}

String excerpt(String text, {int max = 60}) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.length <= max) return flat;
  return '${flat.substring(0, max)}…';
}

List<String> parseStringList(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const [];
  if (text.startsWith('[')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      }
    } on FormatException {
      // 落到下面的分隔符解析
    }
  }
  return text
      .split(RegExp(r'[,，、/;；\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();
}

String encodeStringList(Iterable<String> values) =>
    jsonEncode(values.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList());

/// 把编辑框里的一行别名解析出来：支持中英文逗号、顿号、斜杠、空格分隔。
List<String> splitAliases(String raw) => raw
    .split(RegExp(r'[,，、/;；\s]+'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// 中文数字 → 阿拉伯数字（用于章节序号解析，覆盖到 99）。
int? chineseToInt(String raw) {
  const digits = {
    '零': 0, '〇': 0, '一': 1, '二': 2, '两': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
  };
  const units = {'十': 10, '百': 100, '千': 1000};

  var total = 0;
  var current = 0;
  for (final ch in raw.split('')) {
    if (digits.containsKey(ch)) {
      current = digits[ch]!;
    } else if (units.containsKey(ch)) {
      final unit = units[ch]!;
      total += (current == 0 ? 1 : current) * unit;
      current = 0;
    } else {
      return null;
    }
  }
  final value = total + current;
  return value == 0 && !raw.contains('零') ? null : value;
}
