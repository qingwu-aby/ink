import 'package:flutter_test/flutter_test.dart';
import 'package:mopu/data/db/app_database.dart';
import 'package:mopu/domain/snapshot/snapshot_rules.dart';

Entity entity(int id, String name, {int? deathChapter, String status = 'alive'}) => Entity(
      id: id,
      projectId: 1,
      kind: 'character',
      name: name,
      aliases: '[]',
      summary: '',
      importance: 3,
      status: status,
      deathChapter: deathChapter,
      tags: '[]',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Relation relation(int id, int from, int to, {int validFrom = 1, int? validTo}) => Relation(
      id: id,
      projectId: 1,
      fromId: from,
      toId: to,
      kind: 'enemy',
      strength: 3,
      note: '',
      validFrom: validFrom,
      validTo: validTo,
      updatedAt: DateTime(2026),
    );

Mention mention(int entityId, int chapterId) => Mention(
      id: entityId * 100 + chapterId,
      chapterId: chapterId,
      entityId: entityId,
      start: 0,
      end: 1,
      surface: '',
    );

void main() {
  group('首次登场章节', () {
    test('取正文里最早出现的一章', () {
      final firstSeen = computeFirstSeen(
        entities: [entity(1, '甲'), entity(2, '乙')],
        mentions: [mention(1, 10), mention(1, 11), mention(2, 12)],
        chapterIndexById: {10: 1, 11: 2, 12: 3},
      );
      expect(firstSeen[1], 1);
      expect(firstSeen[2], 3);
    });

    test('正文没提过的实体按第 1 章算在场', () {
      final firstSeen = computeFirstSeen(
        entities: [entity(9, '洛水城')],
        mentions: const [],
        chapterIndexById: const {},
      );
      expect(firstSeen[9], 1);
    });
  });

  group('按章节判定生死', () {
    test('退场之前还活着，到了退场章才算故去', () {
      final pei = entity(3, '裴无咎', deathChapter: 3, status: 'dead');
      expect(statusAt(pei, 1), 'alive');
      expect(statusAt(pei, 2), 'alive');
      expect(statusAt(pei, 3), 'dead');
      expect(statusAt(pei, 9), 'dead');
    });

    test('没有退场章的人不受影响', () {
      expect(statusAt(entity(1, '沈砚之'), 5), 'alive');
    });
  });

  group('第 N 章的快照', () {
    final entities = [
      entity(1, '沈砚之'),
      entity(2, '苏鸢'),
      entity(3, '裴无咎', deathChapter: 3, status: 'dead'),
    ];
    final relations = [
      relation(1, 1, 2, validFrom: 3), // 第 3 章才倾心
      relation(2, 2, 3), // 一直敌对
      relation(3, 1, 2, validFrom: 1, validTo: 2), // 同门，第 2 章结束
    ];
    final firstSeen = {1: 1, 2: 1, 3: 3};

    test('第 1 章：只看得到已经登场的人与关系', () {
      final slice = sliceAt(chapter: 1, entities: entities, relations: relations, firstSeen: firstSeen);
      expect(slice.entityIds, {1, 2});
      expect(slice.relations.map((r) => r.id), containsAll([3]));
      expect(slice.relations.map((r) => r.id), isNot(contains(1)));
      // 裴无咎还没登场，与他相关的边也不该出现
      expect(slice.relations.map((r) => r.id), isNot(contains(2)));
    });

    test('第 2 章：区间结束的关系还在（含尾）', () {
      final slice = sliceAt(chapter: 2, entities: entities, relations: relations, firstSeen: firstSeen);
      expect(slice.relations.map((r) => r.id), contains(3));
    });

    test('第 3 章：新关系生效，旧关系失效，新人登场', () {
      final slice = sliceAt(chapter: 3, entities: entities, relations: relations, firstSeen: firstSeen);
      expect(slice.entityIds, {1, 2, 3});
      expect(slice.relations.map((r) => r.id), containsAll([1, 2]));
      expect(slice.relations.map((r) => r.id), isNot(contains(3)));
      expect(slice.newcomers.map((e) => e.name), ['裴无咎']);
      expect(slice.started.map((r) => r.id), [1]);
      // 第 2 章才有关系结束，第 3 章这里是空的
      expect(slice.ended, isEmpty);
      expect(slice.departed.map((e) => e.name), ['裴无咎']);
      expect(slice.hasDelta, isTrue);
    });

    test('第 2 章有「关系结束」，算变化', () {
      final slice = sliceAt(
        chapter: 2,
        entities: entities,
        relations: relations,
        firstSeen: firstSeen,
      );
      expect(slice.ended.map((r) => r.id), [3]);
      expect(slice.hasDelta, isTrue);
    });

    test('什么都没发生的章节 hasDelta 为假', () {
      final slice = sliceAt(
        chapter: 4,
        entities: entities,
        relations: relations,
        firstSeen: firstSeen,
      );
      expect(slice.hasDelta, isFalse);
    });
  });
}
