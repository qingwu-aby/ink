import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/data/db/app_database.dart';
import 'package:kedao/domain/search/paragraph_splitter.dart';
import 'package:kedao/domain/text/entity_matcher.dart';

void main() {
  group('段落切分', () {
    test('空行分段，偏移能准确回切原文', () {
      const body = '洛水城的雨下了三日。\n\n沈砚之坐在听雨楼。\n\n苏鸢抱着账册上来。';
      final paragraphs = splitParagraphs(body);
      expect(paragraphs.length, 3);
      expect(paragraphs[0].text, '洛水城的雨下了三日。');
      expect(paragraphs[2].text, '苏鸢抱着账册上来。');
      for (final p in paragraphs) {
        expect(body.substring(p.start, p.end), p.text);
      }
      expect(paragraphs.map((p) => p.index), [0, 1, 2]);
    });

    test('一句一行（不空行）也能切开', () {
      const body = '第一句。\n第二句。\n第三句。';
      final paragraphs = splitParagraphs(body);
      expect(paragraphs.length, 3);
      expect(paragraphs[1].text, '第二句。');
      expect(body.substring(paragraphs[1].start, paragraphs[1].end), '第二句。');
    });

    test('行首行尾空白不影响偏移', () {
      const body = '  缩进的一段  \n\n\t第二段\n';
      final paragraphs = splitParagraphs(body);
      expect(paragraphs.length, 2);
      expect(paragraphs[0].text, '缩进的一段');
      expect(paragraphs[1].text, '第二段');
      expect(body.substring(paragraphs[0].start, paragraphs[0].end), '缩进的一段');
    });

    test('空正文返回空', () {
      expect(splitParagraphs(''), isEmpty);
      expect(splitParagraphs('\n\n\n'), isEmpty);
    });
  });

  group('正文检索', () {
    late AppDatabase db;
    late int projectId;
    late int chapterId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      projectId = await db.createProject(title: '听雨录');
      const body = '洛水城的雨下了三日。\n\n'
          '沈砚之在听雨楼记话，手里捏着半页旧诏。\n\n'
          '苏鸢把账册放下，说了一句：五十两，一分不能少。\n\n'
          '那天有 50% 的把握，他还是去了。';
      chapterId = await db.createChapter(projectId: projectId, title: '第一章', body: body);
      await db.reindexParagraphs(chapterId: chapterId, projectId: projectId, body: body);
    });

    tearDown(() async => db.close());

    test('按关键词命中段落，并带回章节与偏移', () async {
      final hits = await db.searchParagraphs(projectId, '旧诏');
      expect(hits.length, 1);
      expect(hits.first.chapterIndex, 1);
      expect(hits.first.content, contains('半页旧诏'));
      expect(hits.first.start, greaterThan(0));
    });

    test('搜不到就返回空', () async {
      expect(await db.searchParagraphs(projectId, '玄机阁'), isEmpty);
    });

    test('LIKE 特殊字符按字面处理', () async {
      // 只有最后一段含 "50%"
      final percent = await db.searchParagraphs(projectId, '50%');
      expect(percent.length, 1);
      expect(percent.first.content, contains('50%'));

      // 单独一个 % 不应该把全部段落都捞出来
      final wildcard = await db.searchParagraphs(projectId, '%');
      expect(wildcard.length, 1);
      expect(wildcard.first.content, contains('50%'));
    });

    test('只看某个实体出现过的段落', () async {
      final entityId = await db.createEntity(projectId: projectId, name: '苏鸢');
      final entities = await db.entitiesOf(projectId);
      final chapter = await db.getChapter(chapterId);
      await db.replaceMentions(
        chapterId,
        EntityMatcher(entities).scan(chapter!.body),
      );

      final paragraphs = await db.paragraphsForEntity(projectId, entityId);
      expect(paragraphs.length, 1);
      expect(paragraphs.first.content, contains('苏鸢'));

      // 再叠关键词：命中他出现的段落
      final narrowed = await db.searchParagraphs(projectId, '五十两', entityId: entityId);
      expect(narrowed.length, 1);
      // 关键词不在他出现的段落里 → 空
      final miss = await db.searchParagraphs(projectId, '旧诏', entityId: entityId);
      expect(miss, isEmpty);
    });

    test('检索不会串到别的项目', () async {
      final other = await db.createProject(title: '别的书');
      expect(await db.searchParagraphs(other, '旧诏'), isEmpty);
    });

    test('重新索引会替换旧段落，不产生重复', () async {
      const body = '只有一段。';
      await db.reindexParagraphs(chapterId: chapterId, projectId: projectId, body: body);
      final everything = await db.searchParagraphs(projectId, '');
      expect(everything, isEmpty); // 空关键词且不过滤实体 → 不返回
      final hits = await db.searchParagraphs(projectId, '只有一段');
      expect(hits.length, 1);
      final again = await db.searchParagraphs(projectId, '旧诏');
      expect(again, isEmpty);
    });

    test('删掉章节时段落跟着走', () async {
      expect((await db.searchParagraphs(projectId, '旧诏')).length, 1);
      await db.deleteChapter(chapterId);
      expect(await db.searchParagraphs(projectId, '旧诏'), isEmpty);
    });
  });
}
