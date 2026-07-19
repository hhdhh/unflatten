import 'package:flutter/material.dart';

abstract final class UnflattenColors {
  static const ink = Color(0xff0c0d0d);
  static const panel = Color(0xff151716);
  static const raised = Color(0xff1d201e);
  static const line = Color(0xff303430);
  static const paper = Color(0xfff3efe4);
  static const muted = Color(0xff9ca199);
  static const acid = Color(0xffdfff66);
  static const coral = Color(0xffff796a);
  static const cyan = Color(0xff72d9df);
  static const lavender = Color(0xffb99cff);
}

ThemeData buildUnflattenTheme() {
  const scheme = ColorScheme.dark(
    primary: UnflattenColors.acid,
    onPrimary: UnflattenColors.ink,
    secondary: UnflattenColors.coral,
    onSecondary: UnflattenColors.ink,
    surface: UnflattenColors.panel,
    onSurface: UnflattenColors.paper,
    error: Color(0xffff6b6b),
    onError: UnflattenColors.ink,
    outline: UnflattenColors.line,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: UnflattenColors.ink,
    splashFactory: InkSparkle.splashFactory,
    fontFamilyFallback: const ['Inter', 'SF Pro Display', 'Segoe UI', 'Roboto'],
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.2,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: UnflattenColors.muted,
        height: 1.45,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: const CardThemeData(
      color: UnflattenColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: UnflattenColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: UnflattenColors.line,
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: UnflattenColors.raised,
      selectedColor: UnflattenColors.acid,
      side: const BorderSide(color: UnflattenColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(color: UnflattenColors.paper),
      secondaryLabelStyle: const TextStyle(
        color: UnflattenColors.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: UnflattenColors.acid,
      inactiveTrackColor: UnflattenColors.line,
      thumbColor: UnflattenColors.paper,
      overlayColor: UnflattenColors.acid.withValues(alpha: 0.12),
      trackHeight: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: UnflattenColors.acid,
        foregroundColor: UnflattenColors.ink,
        minimumSize: const Size(48, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: UnflattenColors.paper,
        side: const BorderSide(color: UnflattenColors.line),
        minimumSize: const Size(48, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: UnflattenColors.paper,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: TextStyle(color: UnflattenColors.ink, fontSize: 12),
    ),
  );
}
