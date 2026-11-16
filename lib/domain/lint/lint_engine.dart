import '../../data/db/app_database.dart';
import '../taxonomy.dart';

/// 校验严重级别。
enum LintLevel {
  issue('错误', 8),
  warning('警告', 3),
  hint('提示', 1);

  const LintLevel(this.label, this.weight);
  final String label;
  final int weight;
}

class LintFinding {
  const LintFinding({
    required this.rule,
    required this.level,
    required this.title,
    required this.detail,
    this.chapterIndex,
    this.entityId,
  });

  final String rule;
  final LintLevel level;
  final String title;
  final String detail;
  final int? chapterIndex;
  final int? entityId;
}

class LintReport {
  const LintReport(this.findings);

  final List<LintFinding> findings;

  static const empty = LintReport([]);

  int countOf(LintLevel level) => findings.where((f) => f.level == level).length;

  int get score {
    var penalty = 0;
    for (final f in findings) {
      penalty += f.level.weight;
    }
    final value = 100 - penalty;
    return value.clamp(0, 100);
  }

  LintReport sorted() {
    final list = [...findings]..sort((a, b) {
        final byLevel = a.level.index.compareTo(b.level.index);
        if (byLevel != 0) return byLevel;
        return (a.chapterIndex ?? 9999).compareTo(b.chapterIndex ?? 9999);
      });
    return LintReport(list);
  }
}

/// 确定性规则引擎。不做语义理解，只做作者自己也能一眼确认的矛盾检查。
class LintEngine {
  static LintReport analyse({
    required List<Chapter> chapters,
    required List<Entity> entities,
    required List<Relation> relations,
    required List<Mention> mentions,
    required List<Foreshadow> foreshadows,
  }) {
    final findings = <LintFinding>[];
    final chapterIndex = {for (final c in chapters) c.id: c.index};
    final entityById = {for (final e in entities) e.id: e};
    final lastIndex = chapters.isEmpty
        ? 0
        : chapters.map((c) => c.index).reduce((a, b) => a > b ? a : b);

    // entityId → 出现过该实体的章节序号（升序去重）
    final appearIn = <int, ChapterIndexSet>{};
    for (final m in mentions) {
      final idx = chapterIndex[m.chapterId];
      if (idx == null) continue;
      (appearIn[m.entityId] ??= ChapterIndexSet()).add(idx);
    }

    // R1 死亡后出场
    for (final entity in entities) {
      if (entity.status != 'dead') continue;
      final death = entity.deathChapter;
      if (death == null) continue;
      final after = appearIn[entity.id]?.where((i) => i > death).toList() ?? const [];
      if (after.isEmpty) continue;
      findings.add(LintFinding(
        rule: 'R1',
        level: LintLevel.issue,
        title: '${entity.name} 已故仍出场',
        detail: '设定为第 $death 章身故，但在第 ${after.join('、')} 章仍有出现。',
        chapterIndex: after.first,
        entityId: entity.id,
      ));
    }

    // R2 关系区间倒挂
    for (final relation in relations) {
      final to = relation.validTo;
      if (to == null) continue;
      if (relation.validFrom <= to) continue;
      final from = entityById[relation.fromId]?.name ?? '?';
      final target = entityById[relation.toId]?.name ?? '?';
      findings.add(LintFinding(
        rule: 'R2',
        level: LintLevel.issue,
        title: '关系区间前后颠倒',
        detail: '$from → $target 的关系开始于第 ${relation.validFrom} 章，却结束于第 $to 章。',
        chapterIndex: relation.validFrom,
      ));
    }

    // R3 名字 / 别名冲突
    final tokenOwners = <String, Set<int>>{};
    for (final entity in entities) {
      final tokens = <String>{entity.name.trim()};
      tokens.addAll(_aliases(entity.aliases));
      for (final token in tokens) {
        if (token.isEmpty) continue;
        (tokenOwners[token] ??= <int>{}).add(entity.id);
      }
    }
    tokenOwners.forEach((token, owners) {
      if (owners.length < 2) return;
      final names = owners.map((id) => entityById[id]?.name ?? '?').join(' / ');
      findings.add(LintFinding(
        rule: 'R3',
        level: LintLevel.issue,
        title: '称呼「$token」被多个实体共用',
        detail: '$names 都指向「$token」，正文高亮会无法区分。',
      ));
    });

    // R4 关系未建立就先同场
    final pairFirstSeen = <String, int>{};
    for (final relation in relations) {
      final a = appearIn[relation.fromId];
      final b = appearIn[relation.toId];
      if (a == null || b == null || a.isEmpty || b.isEmpty) continue;
      final first = _firstCommon(a.toList(), b.toList());
      if (first == null) continue;
      if (first >= relation.validFrom) continue;
      final from = entityById[relation.fromId]?.name ?? '?';
      final target = entityById[relation.toId]?.name ?? '?';
      findings.add(LintFinding(
        rule: 'R4',
        level: LintLevel.warning,
        title: '$from 与 $target 早于关系建立就同场',
        detail:
            '两人第 $first 章已有同场戏，但「${RelationKind.parse(relation.kind).label}」关系记在第 ${relation.validFrom} 章才成立。',
        chapterIndex: first,
      ));
      pairFirstSeen['${relation.fromId}-${relation.toId}'] = first;
    }

    // R5 伏笔超期未收
    for (final fs in foreshadows) {
      if (fs.resolvedChapter != null) continue;
      if (lastIndex - fs.plantedChapter < 3) continue;
      findings.add(LintFinding(
        rule: 'R5',
        level: LintLevel.warning,
        title: '伏笔久未回收',
        detail: '「${fs.hook}」埋于第 ${fs.plantedChapter} 章，已过 ${lastIndex - fs.plantedChapter} 章仍未回收。',
        chapterIndex: fs.plantedChapter,
      ));
    }

    // R6 / R7 孤立实体
    final touched = <int>{};
    for (final relation in relations) {
      touched
        ..add(relation.fromId)
        ..add(relation.toId);
    }
    for (final entity in entities) {
      final hasRelation = touched.contains(entity.id);
      final appears = appearIn[entity.id]?.isNotEmpty ?? false;
      if (!hasRelation && !appears) {
        findings.add(LintFinding(
          rule: 'R6',
          level: LintLevel.hint,
          title: '${entity.name} 完全孤立',
          detail: '既没有任何关系，也没在正文出现过，可能是建了没用的档案。',
          entityId: entity.id,
        ));
      } else if (!hasRelation) {
        findings.add(LintFinding(
          rule: 'R7',
          level: LintLevel.hint,
          title: '${entity.name} 没有任何关系',
          detail: '在正文出现过，但还没和其他实体连线，图谱上看不出它和故事的关系。',
          entityId: entity.id,
        ));
      }
    }

    return LintReport(findings).sorted();
  }

  static List<String> _aliases(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];
    if (text.startsWith('[')) {
      final inner = text.substring(1, text.length - 1);
      return inner
          .split(',')
          .map((e) => e.replaceAll('"', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return text.split(RegExp(r'[,，、/]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static int? _firstCommon(List<int> a, List<int> b) {
    var i = 0, j = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) return a[i];
      if (a[i] < b[j]) {
        i++;
      } else {
        j++;
      }
    }
    return null;
  }
}

/// 需要「升序 + 去重 + 可迭代」的小集合，SplayTreeSet 足够。
class ChapterIndexSet extends Iterable<int> {
  final _set = <int>{};

  void add(int value) => _set.add(value);

  @override
  Iterator<int> get iterator => (_set.toList()..sort()).iterator;
}
