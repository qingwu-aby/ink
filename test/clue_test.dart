import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/data/db/app_database.dart';
import 'package:kedao/domain/search/paragraph_clue.dart';

Entity entity(int id, String name, {int importance = 3}) => Entity(
      id: id,
      projectId: 1,
      kind: 'character',
      name: name,
      aliases: '[]',
      summary: '',
      importance: importance,
      status: 'alive',
      deathChapter: null,
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

Mention mention(int entityId, {required int start, required int end, int chapterId = 1}) => Mention(
      id: entityId * 1000 + start,
      chapterId: chapterId,
      entityId: entityId,
      start: start,
      end: end,
      surface: '',
    );

ParagraphHit hit({required int id, required int start, required int end, int chapter = 1}) => ParagraphHit(
      paragraphId: id,
      chapterId: 1,
      chapterIndex: chapter,
      chapterTitle: '第一章',
      start: start,
      end: end,
      content: '',
    );

void main() {
  final byId = {
    1: entity(1, '沈砚之', importance: 5),
    2: entity(2, '苏鸢', importance: 4),
    3: entity(3, '老周', importance: 1),
  };

  test('只收落在段落区间里的提及', () {
    final clues = buildParagraphClues(
      hits: [hit(id: 1, start: 10, end: 40)],
      mentions: [
        mention(1, start: 12, end: 15),
        mention(2, start: 20, end: 22),
        mention(3, start: 41, end: 43), // 段落外
      ],
      relations: const [],
      entityById: byId,
    );
    expect(clues[1]!.entityIds, [1, 2]); // 按重要度降序
    expect(clues[1]!.links, isEmpty);
  });

  test('关系要同时满足「该章生效」与「沾到本段人物」', () {
    final clues = buildParagraphClues(
      hits: [hit(id: 7, start: 0, end: 30, chapter: 3)],
      mentions: [mention(1, start: 2, end: 5)],
      relations: [
        relation(1, 1, 2, validFrom: 3), // 刚好第 3 章起，生效
        relation(2, 1, 2, validFrom: 1, validTo: 2), // 第 2 章就结束，不生效
        relation(3, 2, 3, validFrom: 1), // 不沾沈砚之，不出现
      ],
      entityById: byId,
    );
    expect(clues[7]!.links.map((r) => r.id), [1]);
  });

  test('段落里没有建档实体时线索为空', () {
    final clues = buildParagraphClues(
      hits: [hit(id: 9, start: 0, end: 10)],
      mentions: const [],
      relations: [relation(1, 1, 2)],
      entityById: byId,
    );
    expect(clues[9]!.isEmpty, isTrue);
    expect(clues[9]!.links, isEmpty);
  });

  test('一段里同一个人出现两次只算一次', () {
    final clues = buildParagraphClues(
      hits: [hit(id: 2, start: 0, end: 50)],
      mentions: [
        mention(1, start: 1, end: 4),
        mention(1, start: 30, end: 33),
      ],
      relations: const [],
      entityById: byId,
    );
    expect(clues[2]!.entityIds, [1]);
  });
}
