/// 一段待导入的章节草稿。
class DraftChapter {
  const DraftChapter({required this.title, required this.body});

  final String title;
  final String body;

  int get wordCount => body.replaceAll(RegExp(r'\s'), '').length;
}

/// 把一整份 txt / md 稿件切成章节。只认「明显是标题」的行，宁可少切不可误切。
abstract final class ChapterSplitter {
  static final _headingPatterns = <RegExp>[
    // 第一章 / 第 12 节 / 第三回 / 卷二 ...
    RegExp(r'^[ \t]*第[ \t]*[0-9零〇一二两三四五六七八九十百千]{1,6}[ \t]*[章节回卷部篇幕][ \t]*[^\n]{0,50}$', multiLine: true),
    // 序章 / 楔子 / 尾声 ...
    RegExp(r'^[ \t]*(?:序章|序言|序|楔子|引子|终章|尾声|后记|番外)[ \t]*[^\n]{0,50}$', multiLine: true),
    // Chapter 3 / Ch. 3
    RegExp(r'^[ \t]*(?:Chapter|CHAPTER|Ch\.)[ \t]*[0-9IVXivx]{1,4}[ \t]*[^\n]{0,60}$', multiLine: true),
    // Markdown 标题
    RegExp(r'^#{1,4}[ \t]+[^\n]{1,60}$', multiLine: true),
  ];

  static List<DraftChapter> split(String raw) {
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.trim().isEmpty) return const [];

    final marks = <_Mark>[];
    for (final pattern in _headingPatterns) {
      for (final match in pattern.allMatches(text)) {
        marks.add(_Mark(match.start, match.end));
      }
    }
    if (marks.isEmpty) {
      return [DraftChapter(title: '第1章', body: text.trim())];
    }

    // 去重 + 按位置排序（不同规则可能命中同一行）
    marks.sort((a, b) => a.start.compareTo(b.start));
    final unique = <_Mark>[];
    for (final mark in marks) {
      if (unique.isNotEmpty && mark.start <= unique.last.end) continue;
      unique.add(mark);
    }

    final drafts = <DraftChapter>[];

    // 第一个标题之前的正文，够长才算「开篇」
    final head = text.substring(0, unique.first.start).trim();
    if (head.length > 30) {
      drafts.add(DraftChapter(title: '开篇', body: head));
    }

    for (var i = 0; i < unique.length; i++) {
      final mark = unique[i];
      final end = i + 1 < unique.length ? unique[i + 1].start : text.length;
      final title = _cleanTitle(text.substring(mark.start, mark.end));
      final body = text.substring(mark.end, end).trim();
      drafts.add(DraftChapter(
        title: title.isEmpty ? '第${drafts.length + 1}章' : title,
        body: body,
      ));
    }

    // 过滤掉空章节（只有标题没有正文），但保留至少一条
    final nonEmpty = drafts.where((d) => d.body.isNotEmpty || d.title.isNotEmpty).toList();
    return nonEmpty.isEmpty ? drafts : nonEmpty;
  }

  static String _cleanTitle(String raw) => raw
      .replaceAll(RegExp(r'^#+\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _Mark {
  const _Mark(this.start, this.end);
  final int start;
  final int end;
}
