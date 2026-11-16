import 'package:flutter_test/flutter_test.dart';
import 'package:mopu/core/utils/text_utils.dart';
import 'package:mopu/data/db/app_database.dart';
import 'package:mopu/domain/graph/force_layout.dart';
import 'package:mopu/domain/import/chapter_splitter.dart';
import 'package:mopu/domain/text/entity_matcher.dart';

Entity entity(int id, String name, {String? aliases}) => Entity(
      id: id,
      projectId: 1,
      kind: 'character',
      name: name,
      aliases: aliases ?? '[]',
      summary: '',
      importance: 3,
      status: 'alive',
      deathChapter: null,
      tags: '[]',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('章节切分', () {
    test('识别中文章节标题', () {
      const raw = '第一章 洛水夜雨\n\n雨下了三日。\n\n第二章 城南药铺\n\n白芷在等他。';
      final drafts = ChapterSplitter.split(raw);
      expect(drafts.length, 2);
      expect(drafts[0].title, '第一章 洛水夜雨');
      expect(drafts[1].title, '第二章 城南药铺');
      expect(drafts[0].body, contains('雨下了三日'));
    });

    test('识别 markdown 标题与楔子', () {
      const raw = '楔子\n\n很久以前。\n\n## 第一节 火\n\n那夜有火。';
      final drafts = ChapterSplitter.split(raw);
      expect(drafts.length, 2);
      expect(drafts[0].title, '楔子');
      expect(drafts[1].title, '第一节 火');
    });

    test('没有任何标题时作为单章处理', () {
      final drafts = ChapterSplitter.split('只有一段正文，没有章节标题。');
      expect(drafts.length, 1);
      expect(drafts.first.title, '第1章');
    });

    test('标题前的长正文成为开篇', () {
      final head = 'A' * 40;
      final drafts = ChapterSplitter.split('$head\n\n第一章 起\n\n正文。');
      expect(drafts.first.title, '开篇');
      expect(drafts.length, 2);
    });
  });

  group('实体识别', () {
    final matcher = EntityMatcher([
      entity(1, '沈砚之', aliases: '["砚之"]'),
      entity(2, '苏鸢'),
      entity(3, '听雨楼'),
    ]);

    test('命中名字与别名', () {
      final spans = matcher.scan('沈砚之走进听雨楼，苏鸢抬头。砚之笑了。');
      expect(spans.map((s) => s.entityId), containsAll([1, 2, 3]));
      expect(spans.length, 4);
    });

    test('别名最长优先，不切碎名字', () {
      final spans = matcher.scan('砚之在听雨楼');
      final surfaces = spans.map((s) => s.surface).toList();
      expect(surfaces, contains('砚之'));
      expect(surfaces, contains('听雨楼'));
    });

    test('单字不会误伤', () {
      final short = EntityMatcher([entity(9, '甲')]);
      expect(short.scan('甲乙丙').isEmpty, isTrue);
    });

    test('空实体表直接返回空', () {
      expect(EntityMatcher(const []).scan('随便什么文字').isEmpty, isTrue);
    });
  });

  group('力导向布局', () {
    test('会收敛并保持有限坐标', () {
      final nodes = [
        for (var i = 0; i < 12; i++) ForceNode(id: i),
        ForceNode(id: 99, pinned: true),
      ];
      final edges = [
        for (var i = 0; i < 11; i++) ForceEdge(a: i, b: i + 1),
        ForceEdge(a: 0, b: 11),
      ];
      final layout = ForceLayout(nodes: nodes, edges: edges)..seed();

      var steps = 0;
      while (!layout.isSettled && steps < 600) {
        layout.step();
        steps++;
      }

      expect(steps, lessThan(600));
      for (final node in nodes) {
        expect(node.x.isFinite, isTrue);
        expect(node.y.isFinite, isTrue);
        expect(node.x.abs(), lessThan(8000));
      }
      // 钉住的节点不会被移动
      expect(nodes.last.x, 0);
      expect(nodes.last.y, 0);
    });

    test('重合的节点会被斥力推开', () {
      final nodes = [ForceNode(id: 1), ForceNode(id: 2)];
      final layout = ForceLayout(nodes: nodes, edges: const []);
      for (var i = 0; i < 120; i++) {
        layout.step();
      }
      final distance = (nodes[0].position - nodes[1].position).distance;
      expect(distance, greaterThan(1));
    });
  });

  group('字数统计', () {
    test('中文按字、英文按词', () {
      expect(countWords('沈砚之'), 3);
      expect(countWords('hello world'), 2);
      expect(countWords('沈砚之 says hi'), 5);
      expect(countWords(''), 0);
    });
  });
}
