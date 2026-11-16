import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../data/db/app_database.dart';
import '../../domain/taxonomy.dart';
import '../../domain/text/entity_matcher.dart';

/// 正文高亮控制器：把实体别名染成类型色，同时支持中文输入法组字区间。
class EntityHighlightController extends TextEditingController {
  EntityHighlightController({
    required this.matcher,
    required this.entityById,
    required bool dark,
  }) : _dark = dark;

  EntityMatcher matcher;
  Map<int, Entity> entityById;
  bool _dark;

  String? _cacheText;
  List<MentionSpan> _cacheSpans = const [];

  void update({EntityMatcher? matcher, Map<int, Entity>? entityById, bool? dark}) {
    if (matcher != null) this.matcher = matcher;
    if (entityById != null) this.entityById = entityById;
    if (dark != null) _dark = dark;
    _cacheText = null;
    notifyListeners();
  }

  List<MentionSpan> get spans {
    if (_cacheText == text) return _cacheSpans;
    _cacheText = text;
    _cacheSpans = matcher.scan(text);
    return _cacheSpans;
  }

  /// 某个光标偏移落在一个实体提及里时，返回对应的实体。
  Entity? entityAt(int offset) {
    for (final span in spans) {
      if (offset >= span.start && offset <= span.end) {
        return entityById[span.entityId];
      }
    }
    return null;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final raw = text;
    if (raw.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final mentionSpans = spans;
    final composing = (withComposing && value.composing.isValid && !value.composing.isCollapsed)
        ? value.composing
        : null;

    final cuts = <int>{0, raw.length};
    for (final span in mentionSpans) {
      cuts.add(span.start);
      cuts.add(span.end);
    }
    if (composing != null) {
      cuts.add(composing.start.clamp(0, raw.length));
      cuts.add(composing.end.clamp(0, raw.length));
    }
    final points = cuts.toList()..sort();

    final children = <TextSpan>[];
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      if (end <= start) continue;

      Entity? entity;
      for (final span in mentionSpans) {
        if (span.start <= start && span.end >= end) {
          entity = entityById[span.entityId];
          break;
        }
      }

      TextStyle? segmentStyle;
      if (entity != null) {
        final kind = EntityKind.parse(entity.kind);
        final color = kind.color(_dark ? Brightness.dark : Brightness.light);
        segmentStyle = TextStyle(
          color: color,
          backgroundColor: color.withValues(alpha: _dark ? 0.18 : 0.09),
          fontWeight: FontWeight.w500,
        );
      }

      final inComposing = composing != null && start >= composing.start && end <= composing.end;
      if (inComposing) {
        segmentStyle = (segmentStyle ?? const TextStyle())
            .copyWith(decoration: TextDecoration.underline, decorationColor: null);
      }

      children.add(TextSpan(text: raw.substring(start, end), style: segmentStyle));
    }

    return TextSpan(style: style, children: children);
  }
}
