import 'package:flutter/material.dart';

/// 色板（前缀 Mo 取自「墨」）。取「宣纸 / 墨 / 朱砂 / 靛青 / 石绿 / 赤金」六色。
/// 命名为 Mo 是为了避开 Flutter 自带的 Ink 组件。
abstract final class Mo {
  // 浅色（宣纸）
  static const paper = Color(0xFFF7F5EF);
  static const paperRaised = Color(0xFFFFFEF9);
  static const paperSunken = Color(0xFFF0ECE2);
  static const ink = Color(0xFF1B1A17);
  static const inkSoft = Color(0xFF4A463F);
  static const inkMuted = Color(0xFF8A8378);
  static const line = Color(0xFFE3DED1);
  static const lineSoft = Color(0xFFEDE9DE);

  // 强调色
  static const vermilion = Color(0xFFB03A2E); // 朱砂
  static const vermilionSoft = Color(0xFFF3E0DC);
  static const indigo = Color(0xFF37596B); // 靛青
  static const jade = Color(0xFF3F7A6E); // 石绿
  static const gold = Color(0xFFA8792B); // 赤金
  static const plum = Color(0xFF7A4E6E); // 藕荷

  // 深色（夜）
  static const night = Color(0xFF100F0D);
  static const nightRaised = Color(0xFF1A1815);
  static const nightSunken = Color(0xFF242119);
  static const nightLine = Color(0xFF2E2A24);
  static const nightInk = Color(0xFFEDE8DE);
  static const nightInkSoft = Color(0xFFBDB6A8);
  static const nightInkMuted = Color(0xFF7E776B);
}

/// 标题/正文用的衬线（宋体系）。
abstract final class Serif {
  static const family = 'Songti SC';
  static const fallback = <String>[
    'STSong',
    'Noto Serif CJK SC',
    'Source Han Serif SC',
    'Noto Serif SC',
    'serif',
  ];
}

abstract final class Radii {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

extension InkContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;

  Color get surface => isDark ? Mo.nightRaised : Mo.paperRaised;
  Color get sunken => isDark ? Mo.nightSunken : Mo.paperSunken;
  Color get border => isDark ? Mo.nightLine : Mo.line;
  Color get muted => isDark ? Mo.nightInkMuted : Mo.inkMuted;
  Color get soft => isDark ? Mo.nightInkSoft : Mo.inkSoft;
}
