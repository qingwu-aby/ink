import '../../data/db/app_database.dart';

/// 正文里的实体识别器。
///
/// 不做中文分词 —— 实体表本身就是词典，按「别名最长优先」做一次正则扫描，
/// 既避免了分词器对自造名字的失效，也保证同一份文本每次结果完全一致。
class EntityMatcher {
  EntityMatcher(List<Entity> entities) {
    final needles = <String, int>{};
    for (final entity in entities) {
      final name = entity.name.trim();
      if (name.isNotEmpty) needles[name] = entity.id;
      for (final alias in _parseAliases(entity.aliases)) {
        // 先到先得：重名时以先建档案的实体为准（冲突本身由校验 R3 报出来）
        needles.putIfAbsent(alias, () => entity.id);
      }
    }
    _needles = needles;

    final sorted = needles.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    // 单字命中率太吵，且容易误伤，只保留两字以上
    final usable = sorted.where((s) => s.length >= 2).toList();
    _pattern = usable.isEmpty
        ? null
        : RegExp(usable.map(RegExp.escape).join('|'), caseSensitive: false);
  }

  late final Map<String, int> _needles;
  RegExp? _pattern;

  bool get isEmpty => _pattern == null;

  /// 返回按位置升序、互不重叠的提及。
  List<MentionSpan> scan(String text) {
    final pattern = _pattern;
    if (pattern == null || text.isEmpty) return const [];
    final spans = <MentionSpan>[];
    for (final match in pattern.allMatches(text)) {
      final surface = match[0]!;
      final entityId = _needles[surface] ?? _needles[surface.toLowerCase()];
      if (entityId == null) continue;
      spans.add(MentionSpan(
        entityId: entityId,
        start: match.start,
        end: match.end,
        surface: surface,
      ));
    }
    return spans;
  }

  /// 本章出现的实体（去重、按出现顺序）。
  List<int> entitiesIn(String text) {
    final seen = <int>{};
    for (final span in scan(text)) {
      seen.add(span.entityId);
    }
    return seen.toList();
  }

  static List<String> _parseAliases(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '[]') return const [];
    if (text.startsWith('[')) {
      final inner = text.substring(1, text.length - 1);
      return inner
          .split(',')
          .map((e) => e.replaceAll('"', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return text.split(RegExp(r'[,，、/]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}
