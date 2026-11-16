import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kedao/data/db/app_database.dart';
import 'package:kedao/domain/export/export_service.dart';

Project project() => Project(
      id: 1,
      title: '听雨录',
      genre: '武侠',
      synopsis: '前朝史官之子流落洛水城。',
      wordGoal: 120000,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Chapter chapter(int index, String title, String body) => Chapter(
      id: index,
      projectId: 1,
      index: index,
      title: title,
      body: body,
      status: 'draft',
      wordCount: body.length,
      note: '',
      updatedAt: DateTime(2026),
    );

Entity entity(int id, String name, {String aliases = '[]', String summary = '', int importance = 3}) => Entity(
      id: id,
      projectId: 1,
      kind: 'character',
      name: name,
      aliases: aliases,
      summary: summary,
      importance: importance,
      status: 'alive',
      deathChapter: null,
      tags: '[]',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Relation relation(int id, int from, int to, String kind, {int validFrom = 1, int? validTo, String note = ''}) =>
    Relation(
      id: id,
      projectId: 1,
      fromId: from,
      toId: to,
      kind: kind,
      strength: 3,
      note: note,
      validFrom: validFrom,
      validTo: validTo,
      updatedAt: DateTime(2026),
    );

String textOf(ExportFile file) {
  final bytes = file.bytes;
  // CSV 带 BOM，正文不带
  final offset = bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF ? 3 : 0;
  return utf8.decode(bytes.sublist(offset));
}

void main() {
  final chapters = [
    chapter(1, '洛水夜雨', '洛水城的雨下了三日。'),
    chapter(2, '城南药铺', '白芷在等他。'),
  ];

  group('正文导出', () {
    test('TXT 按章节顺序，带标题', () {
      final file = ExportService.bookText(project(), chapters);
      final text = textOf(file);
      expect(file.fileName, '听雨录_全文.txt');
      expect(text, contains('第 1 章　洛水夜雨'));
      expect(text, contains('第 2 章　城南药铺'));
      expect(text.indexOf('洛水夜雨'), lessThan(text.indexOf('城南药铺')));
      // 正文不带 BOM，避免某些编辑器显示出怪字符
      expect(file.bytes[0], isNot(0xEF));
    });

    test('标题已带「第X章」时不再重复编号', () {
      final text = textOf(ExportService.bookText(project(), [
        chapter(1, '第一章 洛水夜雨', '雨。'),
        chapter(2, '楔子', '很久以前。'),
        chapter(3, '', '无题。'),
      ]));
      expect(text, contains('第一章 洛水夜雨'));
      expect(text, isNot(contains('第 1 章　第一章')));
      expect(text, contains('楔子'));
      expect(text, contains('第 3 章'));
    });

    test('Markdown 带书名、简介与层级标题', () {
      final text = textOf(ExportService.bookMarkdown(project(), chapters));
      expect(text, startsWith('# 听雨录'));
      expect(text, contains('> 前朝史官之子流落洛水城。'));
      expect(text, contains('## 第 1 章　洛水夜雨'));
    });
  });

  group('表格导出', () {
    test('实体表有表头与统计列', () {
      final text = textOf(ExportService.entitiesCsv(
        project(),
        [
          entity(1, '沈砚之', aliases: '["砚之"]', summary: '记话为生'),
          entity(2, '苏鸢'),
        ],
        [relation(1, 1, 2, 'crush')],
        {1: 6, 2: 3},
      ));
      final lines = text.split('\r\n');
      expect(lines.first, contains('"类型","名称","别称"'));
      expect(lines[1], contains('"沈砚之"'));
      expect(lines[1], contains('"砚之"'));
      expect(lines[1], contains('"6"')); // 出现次数
      expect(lines[1], contains('"1"')); // 关系数
    });

    test('关系表把类型翻成中文，并保留区间', () {
      final text = textOf(ExportService.relationsCsv(
        project(),
        [entity(1, '沈砚之'), entity(2, '苏鸢')],
        [relation(1, 1, 2, 'enemy', validFrom: 3)],
      ));
      expect(text, contains('"敌对"'));
      expect(text, contains('"沈砚之","敌对","苏鸢"'));
      expect(text, contains('"3"'));
    });

    test('CSV 转义引号与逗号', () {
      final text = textOf(ExportService.relationsCsv(
        project(),
        [entity(1, '甲'), entity(2, '乙')],
        [relation(1, 1, 2, 'other', note: '他说"别走",然后走了')],
      ));
      expect(text, contains('"他说""别走"",然后走了"'));
    });

    test('伏笔表标出回收状态', () {
      final text = textOf(ExportService.foreshadowsCsv(project(), [
        Foreshadow(
          id: 1,
          projectId: 1,
          hook: '半页旧诏',
          plantedChapter: 1,
          resolvedChapter: null,
          note: '',
        ),
      ]));
      expect(text, contains('"未回收"'));
    });
  });

  group('文件名', () {
    test('去掉非法字符', () {
      expect(ExportService.safeName('听雨录/卷:一'), '听雨录_卷_一');
      expect(ExportService.safeName('   '), '未命名');
    });
  });
}
