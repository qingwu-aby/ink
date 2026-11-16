import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../../domain/taxonomy.dart';

/// 带标题的卡片容器，统一边框与内边距。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: context.texts.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: context.texts.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
          Padding(
            padding: title == null
                ? padding
                : EdgeInsets.fromLTRB(padding.left, 12, padding.right, padding.bottom),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 实体头像：用名字首字，比通用图标在中文里更好认。
class KindAvatar extends StatelessWidget {
  const KindAvatar({
    super.key,
    required this.kind,
    this.name,
    this.size = 36,
    this.showBadge = false,
  });

  final EntityKind kind;
  final String? name;
  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = kind.color(brightness);
    final initial = (name == null || name!.trim().isEmpty) ? null : name!.trim().substring(0, 1);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kind.tint(brightness),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: initial != null
                ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: size * 0.44,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontFamily: Serif.family,
                      fontFamilyFallback: Serif.fallback,
                    ),
                  )
                : Icon(kind.icon, size: size * 0.5, color: color),
          ),
          if (showBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: BoxDecoration(
                  color: context.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(kind.icon, size: size * 0.24, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

class KindPill extends StatelessWidget {
  const KindPill({super.key, required this.kind, this.dense = false});

  final EntityKind kind;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = kind.color(Theme.of(context).brightness);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 1 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.xs),
      ),
      child: Text(
        kind.label,
        style: TextStyle(fontSize: dense ? 10 : 11, height: 1.3, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final base = color ?? context.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(Radii.xs),
        border: Border.all(color: base.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: base),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(fontSize: 11, height: 1.35, color: base, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.sunken,
                shape: BoxShape.circle,
                border: Border.all(color: context.border),
              ),
              child: Icon(icon, size: 28, color: context.muted),
            ),
            const SizedBox(height: 18),
            Text(title, style: context.texts.titleLarge, textAlign: TextAlign.center),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 健康度环。
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 84, this.label = '图谱健康'});

  final int score;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = score >= 85
        ? (isDark ? const Color(0xFF6FB3A4) : Mo.jade)
        : score >= 65
            ? (isDark ? const Color(0xFFD9A84E) : Mo.gold)
            : (isDark ? const Color(0xFFDD7A69) : Mo.vermilion);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(score: score, color: color, track: context.border),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.30,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: Serif.family,
                  fontFamilyFallback: Serif.fallback,
                ),
              ),
              Text(label, style: TextStyle(fontSize: size * 0.10, color: context.muted, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.score, required this.color, required this.track});

  final int score;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    final sweep = math.pi * 2 * (score.clamp(0, 100) / 100);
    if (sweep <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.score != score || old.color != color;
}

class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.value, required this.label, this.unit});

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 21,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: Serif.family,
                fontFamilyFallback: Serif.fallback,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(unit!, style: context.texts.bodySmall),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: context.texts.labelMedium),
      ],
    );
  }
}

/// 细进度条。
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, this.height = 4, this.color});

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final active = color ?? Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: context.sunken,
        valueColor: AlwaysStoppedAnimation(active),
      ),
    );
  }
}

String formatCount(int value) {
  if (value >= 100000) return '${(value / 10000).toStringAsFixed(1)}万';
  if (value >= 10000) return '${(value / 10000).toStringAsFixed(2)}万';
  return '$value';
}
