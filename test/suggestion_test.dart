import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/data/db/app_database.dart';
import 'package:kedao/domain/suggest/suggestion_engine.dart';

Entity entity(int id, String name, {int importance = 3, int? deathChapter}) => Entity(
      id: id,
      projectId: 1,
      kind: 'character',
      name: name,
      aliases: '[]',
      summary: '',
      importance: importance,
      status: deathChapter == null ? 'alive' : 'dead',
      deathChapter: deathChapter,
      tags: '[]',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Relation relation(int id, int from, int to, {int validFrom = 1, int strength = 3, int? validTo}) =>
    Relation(
      id: id,
      projectId: 1,
      fromId: from,
      toId: to,
      kind: 'enemy',
      strength: strength,
      note: '',
      validFrom: validFrom,
      validTo: validTo,
      updatedAt: DateTime(2026),
    );

Chapter chapter(int id, int index) => Chapter(
      id: id,
      projectId: 1,
      index: index,
      title: '第 $index 章',
      body: '',
      status: 'draft',
      wordCount: 0,
      note: '',
      updatedAt: DateTime(2026),
    );

Mention mention(int entityId, int chapterId) => Mention(
      id: entityId * 1000 + chapterId,
      chapterId: chapterId,
      entityId: entityId,
      start: 0,
      end: 1,
      surface: '',
    );

void main() {
  final chapters = [chapter(1, 1), chapter(2, 2), chapter(3, 3), chapter(4, 4), chapter(5, 5)];

  test('有关系却从没同场 → 建议写第一场对手戏', () {
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '沈砚之'), entity(2, '柳三娘')],
      relations: [relation(1, 1, 2, validFrom: 1, strength: 4)],
      chapters: chapters,
      mentions: [mention(1, 1), mention(1, 2), mention(2, 3)],
    );
    final hit = suggestions.firstWhere((s) => s.kind == SuggestionKind.unshownRelation);
    expect(hit.title, contains('沈砚之'));
    expect(hit.detail, contains('敌对'));
    expect(hit.entityIds, [1, 2]);
  });

  test('同过场的不再提示', () {
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '沈砚之'), entity(2, '柳三娘')],
      relations: [relation(1, 1, 2)],
      chapters: chapters,
      mentions: [mention(1, 1), mention(2, 1)],
    );
    expect(
      suggestions.where((s) => s.kind == SuggestionKind.unshownRelation),
      isEmpty,
    );
  });

  test('弱关系不提示（亲疏 < 3）', () {
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '沈砚之'), entity(2, '柳三娘')],
      relations: [relation(1, 1, 2, strength: 1)],
      chapters: chapters,
      mentions: [mention(1, 1), mention(2, 3)],
    );
    expect(
      suggestions.where((s) => s.kind == SuggestionKind.unshownRelation),
      isEmpty,
    );
  });

  test('重要角色隔了 5 章没出场 → 提示', () {
    final longer = [...chapters, chapter(6, 6)];
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '白芷', importance: 5)],
      relations: const [],
      chapters: longer,
      mentions: [mention(1, 1)],
    );
    final hit = suggestions.firstWhere((s) => s.kind == SuggestionKind.missingCharacter);
    expect(hit.title, '白芷 已经 5 章没出现了');
    expect(hit.weight, 5);
  });

  test('已故的人不会再被提示缺席', () {
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '老周', importance: 5, deathChapter: 2)],
      relations: const [],
      chapters: chapters,
      mentions: [mention(1, 1)],
    );
    expect(
      suggestions.where((s) => s.kind == SuggestionKind.missingCharacter),
      isEmpty,
    );
  });

  test('建了档案没进正文 → 提示用起来', () {
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '青囊书', importance: 3)],
      relations: const [],
      chapters: chapters,
      mentions: const [],
    );
    final hit = suggestions.firstWhere((s) => s.kind == SuggestionKind.unusedEntity);
    expect(hit.title, contains('青囊书'));
  });

  test('同场三次却没连线 → 提示补关系', () {
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '沈砚之'), entity(2, '苏鸢')],
      relations: const [],
      chapters: chapters,
      mentions: [
        mention(1, 1), mention(2, 1),
        mention(1, 2), mention(2, 2),
        mention(1, 3), mention(2, 3),
      ],
    );
    final hit = suggestions.firstWhere((s) => s.kind == SuggestionKind.unlinkedPair);
    expect(hit.detail, contains('补一条关系'));
  });

  test('有连线的同场不再提示', () {
    final suggestions = SuggestionEngine.analyse(
      entities: [entity(1, '沈砚之'), entity(2, '苏鸢')],
      relations: [relation(1, 1, 2)],
      chapters: chapters,
      mentions: [
        mention(1, 1), mention(2, 1),
        mention(1, 2), mention(2, 2),
      ],
    );
    expect(
      suggestions.where((s) => s.kind == SuggestionKind.unlinkedPair),
      isEmpty,
    );
  });

  test('空项目不给建议', () {
    expect(
      SuggestionEngine.analyse(
        entities: const [],
        relations: const [],
        chapters: chapters,
        mentions: const [],
      ),
      isEmpty,
    );
  });
}
