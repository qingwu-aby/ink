import '../../data/db/app_database.dart';

/// 一条检索结果背后的「线索」：这一段里出现了谁、他们当时是什么关系。
class ParagraphClue {
  const ParagraphClue({required this.entityIds, required this.links});

  /// 段落区间内出现的实体，按重要度降序
  final List<int> entityIds;

  /// 与该段人物相关、且在该章仍然生效的关系
  final List<Relation> links;

  bool get isEmpty => entityIds.isEmpty;

  static const empty = ParagraphClue(entityIds: [], links: []);
}

/// 一次算完整批结果，别在每帧 build 里重算。
Map<int, ParagraphClue> buildParagraphClues({
  required List<ParagraphHit> hits,
  required List<Mention> mentions,
  required List<Relation> relations,
  required Map<int, Entity> entityById,
}) {
  final byChapter = <int, List<Mention>>{};
  for (final mention in mentions) {
    byChapter.putIfAbsent(mention.chapterId, () => []).add(mention);
  }

  final clues = <int, ParagraphClue>{};
  for (final hit in hits) {
    final inParagraph = <int>{};
    for (final mention in byChapter[hit.chapterId] ?? const <Mention>[]) {
      if (mention.start >= hit.start && mention.end <= hit.end) {
        inParagraph.add(mention.entityId);
      }
    }

    final people = [
      for (final id in inParagraph)
        if (entityById[id] != null) entityById[id]!,
    ]..sort((a, b) => b.importance.compareTo(a.importance));

    final links = <Relation>[];
    for (final relation in relations) {
      if (relation.validFrom > hit.chapterIndex) continue;
      final end = relation.validTo;
      if (end != null && end < hit.chapterIndex) continue;
      final touches =
          inParagraph.contains(relation.fromId) || inParagraph.contains(relation.toId);
      if (!touches) continue;
      links.add(relation);
    }

    clues[hit.paragraphId] = ParagraphClue(
      entityIds: [for (final person in people) person.id],
      links: links,
    );
  }
  return clues;
}
