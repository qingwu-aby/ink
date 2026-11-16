import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../data/db/app_database.dart';
import '../../domain/graph/force_layout.dart';
import '../../domain/taxonomy.dart';

/// 图谱的绘制层。所有几何量都在「世界坐标」里，屏幕变换由 canvas 承担；
/// 文字单独在屏幕坐标里画，保证任何缩放下都清晰、且字号恒定。
class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.layout,
    required this.entityById,
    required this.relationLabel,
    required this.scale,
    required this.offset,
    required this.dark,
    required this.selectedId,
    required this.focusId,
    required this.mentionCounts,
    required this.highlightKinds,
    required this.labelCache,
    this.forceLabels = false,
    this.selection = const {},
  });

  final ForceLayout layout;
  final Map<int, Entity> entityById;
  final String Function(int nodeIndex) relationLabel;
  final double scale;
  final Offset offset;
  final bool dark;
  final int? selectedId;
  final int? focusId;
  final Map<int, int> mentionCounts;
  final Set<String> highlightKinds;
  final LabelCache labelCache;

  /// 导出图片时缩放可能很小，这时仍然要画名字
  final bool forceLabels;

  /// 多选模式下被选中的实体
  final Set<int> selection;

  Color get _ink => dark ? Mo.nightInk : Mo.ink;
  Color get _muted => dark ? Mo.nightInkMuted : Mo.inkMuted;
  Color get _surface => dark ? Mo.nightRaised : Mo.paperRaised;
  Color get _paper => dark ? Mo.night : Mo.paper;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);

    final neighbours = _neighbourSet();

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    _paintEdges(canvas, neighbours);
    _paintNodes(canvas, neighbours);

    canvas.restore();

    _paintLabels(canvas, size, neighbours);
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final paint = Paint()..color = _paper;
    canvas.drawRect(Offset.zero & size, paint);

    // 极淡的点阵，给空白一点纸的质感
    const step = 26.0;
    final dot = Paint()..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.035);
    final startX = offset.dx % step;
    final startY = offset.dy % step;
    for (var x = startX; x < size.width; x += step) {
      for (var y = startY; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dot);
      }
    }
  }

  Set<int> _neighbourSet() {
    final focus = focusId ?? selectedId;
    if (focus == null) return const {};
    final set = <int>{focus};
    for (final edge in layout.edges) {
      final a = layout.nodes[edge.a].id;
      final b = layout.nodes[edge.b].id;
      if (a == focus) set.add(b);
      if (b == focus) set.add(a);
    }
    return set;
  }

  void _paintEdges(Canvas canvas, Set<int> neighbours) {
    for (var i = 0; i < layout.edges.length; i++) {
      final edge = layout.edges[i];
      final a = layout.nodes[edge.a];
      final b = layout.nodes[edge.b];
      final kindKey = relationLabel(i);
      final dimmed = neighbours.isNotEmpty &&
          !(neighbours.contains(a.id) && neighbours.contains(b.id));

      final kind = RelationKind.parse(kindKey);
      final base = dark ? Mo.nightInkSoft : Mo.inkSoft;
      final color = base.withValues(alpha: dimmed ? 0.06 : (0.16 + edge.strength * 0.07));
      final paint = Paint()
        ..color = color
        ..strokeWidth = (0.7 + edge.strength * 0.32) / math.max(scale, 0.4)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), paint);

      // 箭头：只在缩放够大时画，否则糊成一团
      if (!kind.symmetric && scale > 0.42) {
        _paintArrow(canvas, a, b, color, paint.strokeWidth);
      }
    }
  }

  void _paintArrow(Canvas canvas, ForceNode from, ForceNode to, Color color, double width) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;
    final ux = dx / dist;
    final uy = dy / dist;
    final tip = Offset(to.x - ux * (to.radius + 2), to.y - uy * (to.radius + 2));
    const length = 9.0;
    const spread = 4.2;
    final left = Offset(tip.dx - ux * length - uy * spread, tip.dy - uy * length + ux * spread);
    final right = Offset(tip.dx - ux * length + uy * spread, tip.dy - uy * length - ux * spread);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _paintNodes(Canvas canvas, Set<int> neighbours) {
    for (final node in layout.nodes) {
      final entity = entityById[node.id];
      if (entity == null) continue;
      final kind = EntityKind.parse(entity.kind);
      final dimmed = neighbours.isNotEmpty && !neighbours.contains(node.id);
      final faded = highlightKinds.isNotEmpty && !highlightKinds.contains(entity.kind);
      final alpha = dimmed ? 0.25 : (faded ? 0.22 : 1.0);

      final color = kind.color(dark ? Brightness.dark : Brightness.light);
      final fill = Paint()..color = color.withValues(alpha: alpha);
      final ring = Paint()
        ..color = _surface.withValues(alpha: alpha)
        ..strokeWidth = 2.4 / math.max(scale, 0.35)
        ..style = PaintingStyle.stroke;

      final center = Offset(node.x, node.y);
      if (selectedId == node.id) {
        canvas.drawCircle(center, node.radius + 9 / scale, Paint()..color = color.withValues(alpha: 0.16));
      }
      if (selection.contains(node.id)) {
        canvas.drawCircle(
          center,
          node.radius + 4.5 / scale,
          Paint()
            ..color = _ink.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 / scale,
        );
      }
      canvas.drawCircle(center, node.radius, fill);
      canvas.drawCircle(center, node.radius, ring);

      // 已故：一道斜杠
      if (entity.status == 'dead') {
        final slash = Paint()
          ..color = (dark ? Mo.nightRaised : Colors.white).withValues(alpha: alpha)
          ..strokeWidth = 2.0 / math.max(scale, 0.35)
          ..strokeCap = StrokeCap.round;
        final d = node.radius * 0.52;
        canvas.drawLine(center + Offset(-d, d), center + Offset(d, -d), slash);
      }

      // 钉住的节点标一个小点
      if (node.pinned) {
        canvas.drawCircle(
          center + Offset(node.radius * 0.7, -node.radius * 0.7),
          2.6 / math.max(scale, 0.35),
          Paint()..color = _ink.withValues(alpha: 0.5),
        );
      }
    }
  }

  void _paintLabels(Canvas canvas, Size size, Set<int> neighbours) {
    final showAll = forceLabels || scale > 0.48;
    for (final node in layout.nodes) {
      final entity = entityById[node.id];
      if (entity == null) continue;
      final focused = selectedId == node.id || focusId == node.id;
      final near = neighbours.isNotEmpty && neighbours.contains(node.id);
      if (!showAll && !focused) continue;
      if (neighbours.isNotEmpty && !near && !focused) continue;

      final screen = Offset(node.x * scale + offset.dx, node.y * scale + offset.dy);
      if (screen.dx < -120 || screen.dy < -60 || screen.dx > size.width + 120 || screen.dy > size.height + 60) {
        continue;
      }

      final kind = EntityKind.parse(entity.kind);
      final color = focused
          ? Color.alphaBlend(kind.color(dark ? Brightness.dark : Brightness.light).withValues(alpha: 0.35), _ink)
          : _ink.withValues(alpha: near ? 0.92 : 0.66);

      final painter = labelCache.get(
        'name-${entity.id}',
        entity.name,
        TextStyle(
          fontSize: focused ? 12.5 : 11.5,
          fontWeight: focused ? FontWeight.w600 : FontWeight.w500,
          color: color,
          height: 1.2,
        ),
      );

      final radius = node.radius * scale;
      final top = screen.dy + radius + 3;
      final left = screen.dx - painter.width / 2;

      // 标签底衬：压在连线或别的节点上时仍然可读
      final halo = RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 4, top - 1.5, painter.width + 8, painter.height + 3),
        const Radius.circular(4),
      );
      canvas.drawRRect(halo, Paint()..color = _paper.withValues(alpha: 0.78));
      painter.paint(canvas, Offset(left, top));

      // 出现次数：图谱上最有信息量的第二个数字
      final count = mentionCounts[entity.id] ?? 0;
      if (focused && count > 0) {
        final sub = labelCache.get(
          'count-${entity.id}',
          '正文出现 $count 次',
          TextStyle(fontSize: 9.5, color: _muted, height: 1.2),
        );
        sub.paint(canvas, Offset(screen.dx - sub.width / 2, top + painter.height + 2));
      }
    }
  }

  @override
  bool shouldRepaint(GraphPainter old) => true;
}

/// TextPainter 缓存：布局一次，逐帧复用。
class LabelCache {
  final _painters = <String, TextPainter>{};

  TextPainter get(String key, String text, TextStyle style) {
    final cached = _painters[key];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 110);
    _painters[key] = painter;
    return painter;
  }

  void clear() => _painters.clear();
}
