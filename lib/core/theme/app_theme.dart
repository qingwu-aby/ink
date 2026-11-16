import 'package:flutter/material.dart';

import 'palette.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: Mo.vermilion,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFFE08A7C) : Mo.vermilion,
      onPrimary: isDark ? const Color(0xFF2A0F0B) : Colors.white,
      secondary: isDark ? const Color(0xFF8FB7C9) : Mo.indigo,
      onSecondary: isDark ? const Color(0xFF07181F) : Colors.white,
      surface: isDark ? Mo.nightRaised : Mo.paperRaised,
      onSurface: isDark ? Mo.nightInk : Mo.ink,
      surfaceContainerHighest: isDark ? Mo.nightSunken : Mo.paperSunken,
      outline: isDark ? Mo.nightLine : Mo.line,
      outlineVariant: isDark ? const Color(0xFF232019) : Mo.lineSoft,
      error: isDark ? const Color(0xFFE58F86) : const Color(0xFFA2352B),
    );

    final body = isDark ? Mo.nightInk : Mo.ink;
    final soft = isDark ? Mo.nightInkSoft : Mo.inkSoft;
    final muted = isDark ? Mo.nightInkMuted : Mo.inkMuted;

    final serif = TextStyle(
      fontFamily: Serif.family,
      fontFamilyFallback: Serif.fallback,
      color: body,
      letterSpacing: 0.2,
    );

    final textTheme = TextTheme(
      displaySmall: serif.copyWith(fontSize: 34, fontWeight: FontWeight.w600, height: 1.25),
      headlineMedium: serif.copyWith(fontSize: 27, fontWeight: FontWeight.w600, height: 1.3),
      headlineSmall: serif.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.35),
      titleLarge: serif.copyWith(fontSize: 19, fontWeight: FontWeight.w600, height: 1.4),
      titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: body, letterSpacing: 0.1),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: soft, letterSpacing: 0.3),
      bodyLarge: TextStyle(fontSize: 15, height: 1.6, color: body),
      bodyMedium: TextStyle(fontSize: 13.5, height: 1.55, color: soft),
      bodySmall: TextStyle(fontSize: 12, height: 1.45, color: muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: body, letterSpacing: 0.2),
      labelMedium: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.4),
      labelSmall: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? Mo.night : Mo.paper,
      canvasColor: isDark ? Mo.night : Mo.paper,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Mo.night : Mo.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: body,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: serif.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Mo.nightLine : Mo.lineSoft,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: isDark ? Mo.nightRaised : Mo.paperRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: isDark ? Mo.nightLine : Mo.lineSoft),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFFD9705F) : Mo.vermilion,
          foregroundColor: isDark ? const Color(0xFF20100C) : Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFFE08A7C) : Mo.vermilion,
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: body,
          side: BorderSide(color: isDark ? Mo.nightLine : Mo.line),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Mo.nightSunken : Mo.paperSunken.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: muted, fontSize: 14),
        labelStyle: TextStyle(color: soft, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: isDark ? Mo.nightLine : Mo.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: isDark ? Mo.nightLine : Mo.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: isDark ? const Color(0xFFE08A7C) : Mo.vermilion, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Mo.nightSunken : Mo.paperSunken,
        side: BorderSide(color: isDark ? Mo.nightLine : Mo.lineSoft),
        labelStyle: TextStyle(fontSize: 12, color: soft),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xs)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? Mo.nightRaised : Mo.paperRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: isDark ? Mo.nightRaised : Mo.paperRaised,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
        showDragHandle: true,
        dragHandleColor: isDark ? Mo.nightLine : Mo.line,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? Mo.nightRaised : Mo.paperRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? Mo.nightRaised : Mo.paperRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark
            ? const Color(0xFFE08A7C).withValues(alpha: 0.18)
            : Mo.vermilion.withValues(alpha: 0.10),
        height: 62,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? scheme.primary : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? scheme.primary : muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? Mo.nightRaised : Mo.paperRaised,
        indicatorColor: isDark
            ? const Color(0xFFE08A7C).withValues(alpha: 0.18)
            : Mo.vermilion.withValues(alpha: 0.10),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(color: muted, size: 22),
        selectedLabelTextStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: scheme.primary),
        unselectedLabelTextStyle: TextStyle(fontSize: 11.5, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF2A2620) : Mo.ink,
        contentTextStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFF6F2E9)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18),
        ),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(5),
      ),
    );
  }
}
