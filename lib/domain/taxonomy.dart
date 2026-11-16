import 'package:flutter/material.dart';

import '../core/theme/palette.dart';

/// 实体类型。每种类型有固定色与图标，图谱与正文高亮共用同一套色。
enum EntityKind {
  character('character', '人物', Icons.face_outlined, Color(0xFFB03A2E), Color(0xFFDD7A69)),
  location('location', '地点', Icons.place_outlined, Color(0xFF3F7A6E), Color(0xFF6FB3A4)),
  item('item', '物品', Icons.diamond_outlined, Color(0xFFA8792B), Color(0xFFD9A84E)),
  faction('faction', '势力', Icons.flag_outlined, Color(0xFF37596B), Color(0xFF6D93AC)),
  event('event', '事件', Icons.bolt_outlined, Color(0xFF7A4E6E), Color(0xFFB08AA4)),
  concept('concept', '设定', Icons.auto_awesome_outlined, Color(0xFF6B665C), Color(0xFFA39C90));

  const EntityKind(this.key, this.label, this.icon, this.light, this.dark);

  final String key;
  final String label;
  final IconData icon;
  final Color light;
  final Color dark;

  Color color(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  Color tint(Brightness brightness) {
    final base = color(brightness);
    return brightness == Brightness.dark
        ? Color.alphaBlend(base.withValues(alpha: 0.22), Mo.nightRaised)
        : Color.alphaBlend(base.withValues(alpha: 0.10), Mo.paperRaised);
  }

  static EntityKind parse(String? raw) => values.firstWhere(
        (k) => k.key == raw,
        orElse: () => EntityKind.character,
      );
}

/// 实体状态。
enum EntityStatus {
  alive('alive', '在世'),
  dead('dead', '已故'),
  unknown('unknown', '不详');

  const EntityStatus(this.key, this.label);
  final String key;
  final String label;

  static EntityStatus parse(String? raw) => values.firstWhere(
        (s) => s.key == raw,
        orElse: () => EntityStatus.alive,
      );
}

enum ChapterStatus {
  draft('draft', '草稿'),
  revising('revising', '修改中'),
  done('done', '定稿');

  const ChapterStatus(this.key, this.label);
  final String key;
  final String label;

  static ChapterStatus parse(String? raw) => values.firstWhere(
        (s) => s.key == raw,
        orElse: () => ChapterStatus.draft,
      );
}

/// 关系类型。[symmetric] 为真时不画箭头（父子/夫妻这类对等或双向表达）。
class RelationKind {
  const RelationKind(this.key, this.label, {this.symmetric = false});

  final String key;
  final String label;
  final bool symmetric;

  static const all = <RelationKind>[
    RelationKind('parent', '亲子'),
    RelationKind('sibling', '同胞', symmetric: true),
    RelationKind('clan', '宗亲', symmetric: true),
    RelationKind('spouse', '夫妻', symmetric: true),
    RelationKind('mentor', '师徒'),
    RelationKind('peer', '同门', symmetric: true),
    RelationKind('friend', '挚友', symmetric: true),
    RelationKind('liege', '效忠'),
    RelationKind('ally', '同盟', symmetric: true),
    RelationKind('enemy', '敌对', symmetric: true),
    RelationKind('rival', '竞争', symmetric: true),
    RelationKind('crush', '倾心'),
    RelationKind('knows', '相识', symmetric: true),
    RelationKind('other', '其他', symmetric: true),
  ];

  static RelationKind parse(String? raw) => all.firstWhere(
        (k) => k.key == raw,
        orElse: () => all.first,
      );

  String labelOf(String key) => parse(key).label;
}

/// 关系的「强度」只有 5 档，用线的粗细表达，不引入无意义的连续值。
const relationStrengthLabels = <int, String>{
  1: '淡',
  2: '浅',
  3: '常',
  4: '近',
  5: '密',
};

abstract final class Taxonomy {
  /// 人物名字生成器用：姓 / 名 词库（只做点缀，不追求考据）。
  static const surnames = [
    '沈', '苏', '裴', '顾', '柳', '谢', '陆', '萧', '温', '江',
    '虞', '宋', '许', '闻', '周', '崔', '贺', '傅', '晏', '秦',
  ];
  static const givenMarks = [
    '砚之', '鸢', '无咎', '长风', '听雪', '停云', '望舒', '岁寒', '扶疏', '照野',
    '栖迟', '既白', '南枝', '知微', '折竹', '漱石', '青崖', '敛秋', '衔月', '晏如',
  ];
  static const placeSuffix = ['城', '楼', '阁', '谷', '渡', '关', '寺', '川', '台', '巷'];

  static String randomName(int seed) {
    final s = surnames[seed % surnames.length];
    final g = givenMarks[(seed ~/ 3) % givenMarks.length];
    return '$s$g';
  }
}
