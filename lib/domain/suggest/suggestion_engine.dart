import '../../data/db/app_database.dart';
import '../taxonomy.dart';

/// 一条写作建议的类型。
enum SuggestionKind {
  /// 关系记在档案里，但两个人从没在正文里同场
  unshownRelation('关系没写出来'),

  /// 重要角色很久没露面
  missingCharacter('角色长期缺席'),

  /// 建了档案但从没进过正文
  unusedEntity('档案没派上用场'),

  /// 反复同场却没有连线
  unlinkedPair('同场多次但没连线');

  const SuggestionKind(this.label);
  final String label;
}

/// 一条「接下来可以写」的建议。
class Suggestion {
  const Suggestion({
    required this.kind,
    required this.title,
    required this.detail,
    this.entityIds = const [],
    this.chapterIndex,
    this.weight = 0,
  });

  final SuggestionKind kind;
  final String title;
  final String detail;

  /// 相关实体，点开可以看档案
  final List<int> entityIds;

  /// 相关的章节（如果有）
  final int? chapterIndex;

  /// 越大越靠前
  final int weight;
}

/// 从图谱里找机会。
///
/// 与「校对」不同：校对找的是矛盾（死人出场、区间倒挂），这里找的是**还没被用上的素材**。
/// 同样是确定性的，不猜语义。
class SuggestionEngine {
  static List<Suggestion> analyse({
    required List<Entity> entities,
    required List<Relation> relations,
    required List<Chapter> chapters,
    required List<Mention> mentions,
    int limitPerKind = 5,
  }) {
    if (chapters.isEmpty || entities.isEmpty) return const [];

    final byId = {for (final entity in entities) entity.id: entity};
    final chapterIndexById = {for (final chapter in chapters) chapter.id: chapter.index};
    final lastChapter =
        chapters.map((c) => c.index).reduce((a, b) => a > b ? a : b);

    // 每个实体出现在哪些章；每章出现哪些实体
    final chaptersOf = <int, Set<int>>{};
    final entitiesOfChapter = <int, Set<int>>{};
    for (final mention in mentions) {
      final index = chapterIndexById[mention.chapterId];
      if (index == null) continue;
      (chaptersOf[mention.entityId] ??= <int>{}).add(index);
      (entitiesOfChapter[index] ??= <int>{}).add(mention.entityId);
    }

    // 谁和谁同过场（无向）
    final coAppear = <String, int>{};
    for (final entry in entitiesOfChapter.entries) {
      final ids = entry.value.toList()..sort();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final key = '${ids[i]}-${ids[j]}';
          coAppear[key] = (coAppear[key] ?? 0) + 1;
        }
      }
    }
    String pairKey(int a, int b) => a < b ? '$a-$b' : '$b-$a';

    final suggestions = <Suggestion>[];

    // 1) 有强度不低的关系，却一次都没同场
    final unshown = <Suggestion>[];
    for (final relation in relations) {
      if (relation.validFrom > lastChapter) continue;
      if (relation.strength < 3) continue;
      final from = byId[relation.fromId];
      final to = byId[relation.toId];
      if (from == null || to == null) continue;
      if (!chaptersOf.containsKey(from.id) || !chaptersOf.containsKey(to.id)) continue;
      if (coAppear.containsKey(pairKey(from.id, to.id))) continue;
      unshown.add(Suggestion(
        kind: SuggestionKind.unshownRelation,
        title: '${from.name} 与 ${to.name} 还没同过场',
        detail: '档案里记着「${RelationKind.parse(relation.kind).label}」，'
            '但正文从没让两人同时出现。'
            '他们的第一场对手戏，可能就是下一章。',
        entityIds: [from.id, to.id],
        weight: relation.strength,
      ));
    }
    unshown.sort((a, b) => b.weight.compareTo(a.weight));
    suggestions.addAll(unshown.take(limitPerKind));

    // 2) 重要角色长期缺席（至少露过一次面，隔了 5 章以上）
    final missing = <Suggestion>[];
    for (final entity in entities) {
      if (entity.importance < 4) continue;
      final seen = chaptersOf[entity.id];
      if (seen == null || seen.isEmpty) continue;
      final last = seen.reduce((a, b) => a > b ? a : b);
      final gap = lastChapter - last;
      if (gap < 5) continue;
      if (entity.deathChapter != null && entity.deathChapter! <= last) continue;
      missing.add(Suggestion(
        kind: SuggestionKind.missingCharacter,
        title: '${entity.name} 已经 $gap 章没出现了',
        detail: '上次出场是第 $last 章。重要度高的人消失太久，读者会忘了他为什么重要。',
        entityIds: [entity.id],
        chapterIndex: last,
        weight: gap,
      ));
    }
    missing.sort((a, b) => b.weight.compareTo(a.weight));
    suggestions.addAll(missing.take(limitPerKind));

    // 3) 建了档案但从没进正文
    final unused = <Suggestion>[];
    for (final entity in entities) {
      if (entity.importance < 3) continue;
      if (chaptersOf.containsKey(entity.id)) continue;
      unused.add(Suggestion(
        kind: SuggestionKind.unusedEntity,
        title: '${entity.name} 还没在正文里出现过',
        detail: '档案写好了却没在正文里提过。要么用起来，要么它其实不需要存在。',
        entityIds: [entity.id],
        weight: entity.importance,
      ));
    }
    unused.sort((a, b) => b.weight.compareTo(a.weight));
    suggestions.addAll(unused.take(limitPerKind));

    // 4) 反复同场却没有连线
    final unlinked = <Suggestion>[];
    for (final entry in coAppear.entries) {
      if (entry.value < 2) continue;
      final parts = entry.key.split('-');
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      if (a == null || b == null) continue;
      final first = byId[a];
      final second = byId[b];
      if (first == null || second == null) continue;
      final linked = relations.any(
        (r) => (r.fromId == a && r.toId == b) || (r.fromId == b && r.toId == a),
      );
      if (linked) continue;
      unlinked.add(Suggestion(
        kind: SuggestionKind.unlinkedPair,
        title: '${first.name} 和 ${second.name} 同场 ${entry.value} 次，却没连线',
        detail: '他们反复出现在同一场戏里。要么补一条关系，要么说明他们本来就不熟。',
        entityIds: [a, b],
        weight: entry.value,
      ));
    }
    unlinked.sort((a, b) => b.weight.compareTo(a.weight));
    suggestions.addAll(unlinked.take(limitPerKind));

    return suggestions;
  }
}
