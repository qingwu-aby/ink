import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../data/db/app_database.dart';
import '../../features/graph/graph_painter.dart';
import 'graph_builder.dart';

/// 把一张图谱渲染成 PNG。用独立的布局实例，不干扰屏幕上那张图的状态。
Future<Uint8List> renderGraphPng({
  required List<Entity> entities,
  required List<Relation> relations,
  required Map<int, int> mentionCounts,
  required String title,
  Size size = const Size(1400, 1000),
  double pixelRatio = 2,
  bool dark = false,
}) async {
  final scene = buildGraphScene(entities, relations);
  final layout = scene.layout;
  layout.seed(spacing: 110);

  // 静默跑到收敛：导出不需要动画，只要一张稳定的图
  var guard = 0;
  while (!layout.isSettled && guard < 1500) {
    layout.step();
    guard++;
  }

  final bounds = layout.bounds();
  const outer = 64.0;
  const header = 76.0;
  final scale = math.min(
        (size.width - outer * 2) / math.max(bounds.width, 1),
        (size.height - outer * 2 - header) / math.max(bounds.height, 1),
      ).clamp(0.08, 3.0);
  final offset = Offset(size.width / 2, header + (size.height - header) / 2) - bounds.center * scale;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixelRatio);

  GraphPainter(
    layout: layout,
    entityById: scene.entityById,
    relationLabel: (index) => index < scene.edgeKinds.length ? scene.edgeKinds[index] : 'other',
    scale: scale,
    offset: offset,
    dark: dark,
    selectedId: null,
    focusId: null,
    mentionCounts: mentionCounts,
    highlightKinds: const {},
    labelCache: LabelCache(),
    forceLabels: true,
  ).paint(canvas, size);

  _paintHeader(canvas, title: title, entities: entities.length, relations: relations.length, dark: dark);

  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size.width * pixelRatio).round(),
    (size.height * pixelRatio).round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void _paintHeader(
  Canvas canvas, {
  required String title,
  required int entities,
  required int relations,
  required bool dark,
}) {
  final ink = dark ? Mo.nightInk : Mo.ink;
  final muted = dark ? Mo.nightInkMuted : Mo.inkMuted;

  final titlePainter = TextPainter(
    text: TextSpan(
      text: title,
      style: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: ink,
        fontFamily: Serif.family,
        fontFamilyFallback: Serif.fallback,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 900);
  titlePainter.paint(canvas, const Offset(44, 30));

  final subPainter = TextPainter(
    text: TextSpan(
      text: '$entities 个实体 · $relations 条关系 · 可道导出',
      style: TextStyle(fontSize: 14, color: muted, height: 1.4),
    ),
    textDirection: ui.TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: 900);
  subPainter.paint(canvas, Offset(45, 30 + titlePainter.height + 4));

  final line = Paint()
    ..color = (dark ? Mo.nightLine : Mo.line)
    ..strokeWidth = 1;
  canvas.drawLine(const Offset(44, 66), Offset(44 + 260, 66), line);
}
