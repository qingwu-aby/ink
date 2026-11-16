import '../../data/db/app_database.dart';

/// 第 N 章那一刻的世界：哪些实体已经登场、哪些关系正好生效。
class SnapshotSlice {
  const SnapshotSlice({
    required this.chapter,
    required this.entityIds,
    required this.relations,
    required this.newcomers,
    required this.started,
    required this.ended,
    required this.departed,
  });

  final int chapter;

  /// 已经登场的实体
  final Set<int> entityIds;

  /// 在这一章生效的关系（两端都还得在场）
  final List<Relation> relations;

  /// 本章首次登场
  final List<Entity> newcomers;

  /// 本章开始的关系
  final List<Relation> started;

  /// 本章结束的关系
  final List<Relation> ended;

  /// 本章退场（身故）
  final List<Entity> departed;

  bool get hasDelta =>
      newcomers.isNotEmpty || started.isNotEmpty || ended.isNotEmpty || departed.isNotEmpty;
}

/// 实体第一次出现在哪一章。正文没提过的（地点、设定之类）按第 1 章起就在。
Map<int, int> computeFirstSeen({
  required List<Entity> entities,
  required List<Mention> mentions,
  required Map<int, int> chapterIndexById,
}) {
  final firstSeen = <int, int>{};
  for (final mention in mentions) {
    final index = chapterIndexById[mention.chapterId];
    if (index == null) continue;
    final current = firstSeen[mention.entityId];
    if (current == null || index < current) firstSeen[mention.entityId] = index;
  }
  for (final entity in entities) {
    firstSeen.putIfAbsent(entity.id, () => 1);
  }
  return firstSeen;
}

/// 第 [chapter] 章时这个人还在不在。
///
/// 实体上存的是"现在"的状态，但快照要的是"那一刻"的状态：
/// 第 12 章身故的人，在第 5 章的快照里应该还活着。
String statusAt(Entity entity, int chapter) {
  final death = entity.deathChapter;
  if (death == null) return entity.status;
  return death <= chapter ? 'dead' : 'alive';
}

/// 算出第 [chapter] 章的可见子图与本章变化。
SnapshotSlice sliceAt({
  required int chapter,
  required List<Entity> entities,
  required List<Relation> relations,
  required Map<int, int> firstSeen,
}) {
  final visible = <int>{
    for (final entity in entities)
      if ((firstSeen[entity.id] ?? 1) <= chapter) entity.id,
  };

  final active = <Relation>[];
  for (final relation in relations) {
    final fromVisible = visible.contains(relation.fromId);
    final toVisible = visible.contains(relation.toId);
    if (!fromVisible || !toVisible) continue;
    if (relation.validFrom > chapter) continue;
    final end = relation.validTo;
    if (end != null && end < chapter) continue;
    active.add(relation);
  }

  return SnapshotSlice(
    chapter: chapter,
    entityIds: visible,
    relations: active,
    newcomers: [
      for (final entity in entities)
        if ((firstSeen[entity.id] ?? 1) == chapter) entity,
    ],
    started: [
      for (final relation in relations)
        if (relation.validFrom == chapter) relation,
    ],
    ended: [
      for (final relation in relations)
        if (relation.validTo == chapter) relation,
    ],
    departed: [
      for (final entity in entities)
        if (entity.deathChapter == chapter) entity,
    ],
  );
}
