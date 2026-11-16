/// 正文里的一个段落。
class DraftParagraph {
  const DraftParagraph({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  final int index;

  /// 在章节正文中的起始 / 结束偏移（end 不含）
  final int start;
  final int end;
  final String text;
}

/// 把正文切成段落。
///
/// 中文稿常见的两种排版都吃得下：空行分段、以及一句一行（不空行）。
/// 规则很简单——按换行切，去掉首尾空白，丢掉空段。
/// 不做「智能合并软换行」：宁可切碎一点，也不要让一条检索结果跨两段。
List<DraftParagraph> splitParagraphs(String body) {
  if (body.isEmpty) return const [];

  final paragraphs = <DraftParagraph>[];
  var index = 0;
  var cursor = 0;

  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      final start = cursor + (line.length - line.trimLeft().length);
      paragraphs.add(DraftParagraph(
        index: index++,
        start: start,
        end: start + trimmed.length,
        text: trimmed,
      ));
    }
    cursor += line.length + 1; // +1 跳过换行符
  }

  return paragraphs;
}
