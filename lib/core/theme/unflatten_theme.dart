// Unflatten Studio 主题 / Design Tokens
//
// 设计语言:modern-minimal (Linear/Vercel) 底 + tech-utility (Datadog/GitHub)
// 暗房精密仪器调。所有 widget 应从 tokens 取色,不再 inline hex。
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const _sansFallback = <String>[
  'Inter',
  'SF Pro Display',
  'SF Pro Text',
  'Segoe UI',
  'Roboto',
  'system-ui',
];

const _monoFallback = <String>[
  'JetBrains Mono',
  'IBM Plex Mono',
  'ui-monospace',
  'Menlo',
  'SFMono-Regular',
];

abstract final class UnflattenTokens {
  UnflattenTokens._();
  static const canvas = Color(0xff0a0a0c);
  static const surface = Color(0xff101013);
  static const panel = Color(0xff131316);
  static const raised = Color(0xff1c1c21);
  static const overlay = Color(0xff26262c);
  static const inset = Color(0xff08080a);
  static const fg = Color(0xfff5f5f7);
  static const fgMuted = Color(0xffa8a8ad);
  static const fgSubtle = Color(0xff6e6e74);
  static const fgDisabled = Color(0xff3d3d42);
  static const onAccent = Color(0xff0a0a0c);
  static const hairline = Color(0xff1f1f24);
  static const line = Color(0xff26262c);
  static const lineStrong = Color(0xff3d3d42);
  static const acid = Color(0xffdfff66);
  static const coral = Color(0xffff796a);
  static const cyan = Color(0xff72d9df);
  static const lavender = Color(0xffb99cff);
  static const amber = Color(0xffffb84d);
  static const magenta = Color(0xffff4d8a);
  static const success = Color(0xff4cd97c);
  static const warn = Color(0xffffb84d);
  static const danger = Color(0xffff5e62);
  static const info = Color(0xff72d9df);
  static const scrim = Color(0x99000000);
  static const shimmer = Color(0x14ffffff);
  // v2 增补：用于 Editor sheet、Recipe 卡片、hover 等层次
  static const surfaceElevated = Color(0xff18181c);
  static const accentSoft = Color(0xfff0ffd0);
  static const scrimBlur = Color(0x66000000);
  static const recipeShadow = Color(0x33000000);
  static const recipeShadowSelected = Color(0x66dfff66);
  // 语义化间距
  static const pageHorizontal = 24.0;
  static const pageVertical = 22.0;
  static const railWidth = 280.0;
  static const inspectorWidth = 360.0;
  static const headerHeight = 72.0;
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp5 = 20.0;
  static const sp6 = 24.0;
  static const sp7 = 32.0;
  static const sp8 = 48.0;
  static const sp9 = 64.0;
  static const r1 = 4.0;
  static const r2 = 8.0;
  static const r3 = 12.0;
  static const r4 = 14.0;
  static const r5 = 16.0;
  static const r6 = 20.0;
  static const rFull = 999.0;
}

abstract final class UnflattenColors {
  UnflattenColors._();
  static const ink = UnflattenTokens.canvas;
  static const panel = UnflattenTokens.panel;
  static const raised = UnflattenTokens.raised;
  static const line = UnflattenTokens.line;
  static const paper = UnflattenTokens.fg;
  static const muted = UnflattenTokens.fgMuted;
  static const acid = UnflattenTokens.acid;
  static const coral = UnflattenTokens.coral;
  static const cyan = UnflattenTokens.cyan;
  static const lavender = UnflattenTokens.lavender;
  static const fg = UnflattenTokens.fg;
  static const fgMuted = UnflattenTokens.fgMuted;
  static const fgSubtle = UnflattenTokens.fgSubtle;
  static const fgDisabled = UnflattenTokens.fgDisabled;
  static const onAccent = UnflattenTokens.onAccent;
  static const hairline = UnflattenTokens.hairline;
  static const lineStrong = UnflattenTokens.lineStrong;
  static const surface = UnflattenTokens.surface;
  static const canvas = UnflattenTokens.canvas;
  static const inset = UnflattenTokens.inset;
  static const overlay = UnflattenTokens.overlay;
  static const amber = UnflattenTokens.amber;
  static const magenta = UnflattenTokens.magenta;
  static const success = UnflattenTokens.success;
  static const warn = UnflattenTokens.warn;
  static const danger = UnflattenTokens.danger;
  static const info = UnflattenTokens.info;
  static const surfaceElevated = UnflattenTokens.surfaceElevated;
  static const accentSoft = UnflattenTokens.accentSoft;
  static const scrimBlur = UnflattenTokens.scrimBlur;
  static const recipeShadow = UnflattenTokens.recipeShadow;
  static const recipeShadowSelected = UnflattenTokens.recipeShadowSelected;
}

abstract final class UnflattenMotion {
  UnflattenMotion._();
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const pageTransition = Duration(milliseconds: 280);
}

abstract final class UnflattenEffects {
  UnflattenEffects._();
  static const recipeShadow = <BoxShadow>[
    BoxShadow(
      color: UnflattenTokens.recipeShadow,
      blurRadius: 24,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];
  static const recipeShadowSelected = <BoxShadow>[
    BoxShadow(
      color: UnflattenTokens.recipeShadowSelected,
      blurRadius: 26,
      spreadRadius: -4,
      offset: Offset(0, 10),
    ),
  ];
}

abstract final class UnflattenTypography {
  UnflattenTypography._();
  static const _baseTextStyle = TextStyle(
    fontFamilyFallback: _sansFallback,
    fontFeatures: [FontFeature.tabularFigures()],
    decoration: TextDecoration.none,
    height: 1.32,
  );
  static TextTheme buildTextTheme(ColorScheme scheme) {
    final fg = scheme.onSurface;
    final muted = scheme.onSurface.withValues(alpha: 0.62);
    final subtle = scheme.onSurface.withValues(alpha: 0.42);
    TextStyle s(
      double size, {
      FontWeight weight = FontWeight.w500,
      double? letterSpacing,
      Color? color,
      double height = 1.32,
    }) =>
        _baseTextStyle.copyWith(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          color: color ?? fg,
          height: height,
        );
    return TextTheme(
      displayLarge: s(48, weight: FontWeight.w700, letterSpacing: -1.4),
      displayMedium: s(36, weight: FontWeight.w700, letterSpacing: -0.9),
      headlineLarge: s(28, weight: FontWeight.w700, letterSpacing: -0.7),
      headlineMedium: s(22, weight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: s(18, weight: FontWeight.w600, letterSpacing: -0.3),
      titleLarge: s(16, weight: FontWeight.w600, letterSpacing: -0.2),
      titleMedium: s(14, weight: FontWeight.w600, letterSpacing: -0.1),
      titleSmall: s(12, weight: FontWeight.w700, letterSpacing: 0.2, color: subtle),
      bodyLarge: s(14, weight: FontWeight.w500, height: 1.45, color: fg),
      bodyMedium: s(13, weight: FontWeight.w500, height: 1.45, color: muted),
      bodySmall: s(12, weight: FontWeight.w500, height: 1.4, color: muted),
      labelLarge: s(13, weight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: s(11.5, weight: FontWeight.w600, letterSpacing: 0.4),
      labelSmall: s(10.5, weight: FontWeight.w700, letterSpacing: 0.8, height: 1.1),
    );
  }
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamilyFallback: _monoFallback,
        fontFeatures: const [FontFeature.tabularFigures(), FontFeature.enable('ss01')],
        decoration: TextDecoration.none,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.3,
      );
}

ThemeData buildUnflattenTheme() {
  final scheme = const ColorScheme.dark(
    brightness: Brightness.dark,
    primary: UnflattenTokens.acid,
    onPrimary: UnflattenTokens.onAccent,
    secondary: UnflattenTokens.coral,
    onSecondary: UnflattenTokens.onAccent,
    tertiary: UnflattenTokens.cyan,
    onTertiary: UnflattenTokens.onAccent,
    surface: UnflattenTokens.surface,
    onSurface: UnflattenTokens.fg,
    surfaceContainerHighest: UnflattenTokens.raised,
    surfaceContainerHigh: UnflattenTokens.raised,
    surfaceContainer: UnflattenTokens.panel,
    surfaceContainerLow: UnflattenTokens.surface,
    surfaceContainerLowest: UnflattenTokens.canvas,
    surfaceTint: UnflattenTokens.acid,
    error: UnflattenTokens.danger,
    onError: UnflattenTokens.onAccent,
    outline: UnflattenTokens.line,
    outlineVariant: UnflattenTokens.hairline,
    scrim: UnflattenTokens.scrim,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: UnflattenTokens.canvas,
    canvasColor: UnflattenTokens.canvas,
    splashColor: UnflattenTokens.acid.withValues(alpha: 0.10),
    highlightColor: UnflattenTokens.fg.withValues(alpha: 0.06),
    splashFactory: InkSparkle.splashFactory,
    fontFamily: 'Inter',
    fontFamilyFallback: _sansFallback,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
  );

  final txt = UnflattenTypography.buildTextTheme(scheme);

  return base.copyWith(
    textTheme: txt,
    primaryTextTheme: txt,
    iconTheme: const IconThemeData(color: UnflattenTokens.fgMuted, size: 18),
    primaryIconTheme: const IconThemeData(color: UnflattenTokens.onAccent, size: 18),
    cardTheme: CardThemeData(
      color: UnflattenTokens.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UnflattenTokens.r5),
        side: const BorderSide(color: UnflattenTokens.line),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: UnflattenTokens.hairline,
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: UnflattenTokens.raised,
      selectedColor: UnflattenTokens.acid,
      disabledColor: UnflattenTokens.surface,
      side: const BorderSide(color: UnflattenTokens.line),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UnflattenTokens.r2),
      ),
      labelStyle: txt.labelMedium?.copyWith(color: UnflattenTokens.fg),
      secondaryLabelStyle: txt.labelMedium?.copyWith(
        color: UnflattenTokens.onAccent,
        fontWeight: FontWeight.w700,
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: UnflattenTokens.acid,
      inactiveTrackColor: UnflattenTokens.line,
      thumbColor: UnflattenTokens.fg,
      overlayColor: UnflattenTokens.acid.withValues(alpha: 0.12),
      trackHeight: 2.5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: UnflattenTokens.acid,
        foregroundColor: UnflattenTokens.onAccent,
        disabledBackgroundColor: UnflattenTokens.raised,
        disabledForegroundColor: UnflattenTokens.fgDisabled,
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UnflattenTokens.r3),
        ),
        textStyle: txt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: UnflattenTokens.fg,
        side: const BorderSide(color: UnflattenTokens.line),
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UnflattenTokens.r3),
        ),
        textStyle: txt.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: UnflattenTokens.acid,
        minimumSize: const Size(40, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: txt.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: UnflattenTokens.fgMuted,
        minimumSize: const Size(38, 38),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UnflattenTokens.r2),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: UnflattenTokens.fg,
        borderRadius: BorderRadius.circular(UnflattenTokens.r2),
      ),
      textStyle: txt.bodySmall?.copyWith(
        color: UnflattenTokens.canvas,
        fontWeight: FontWeight.w600,
      ),
      waitDuration: const Duration(milliseconds: 400),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: UnflattenTokens.raised,
      contentTextStyle: txt.bodyMedium?.copyWith(color: UnflattenTokens.fg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UnflattenTokens.r3),
        side: const BorderSide(color: UnflattenTokens.line),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: UnflattenTokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UnflattenTokens.r6),
        side: const BorderSide(color: UnflattenTokens.line),
      ),
      titleTextStyle: txt.headlineSmall,
      contentTextStyle: txt.bodyMedium,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: UnflattenTokens.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UnflattenTokens.r3),
        side: const BorderSide(color: UnflattenTokens.line),
      ),
      textStyle: txt.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: UnflattenTokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: UnflattenTokens.line),
      ),
    ),
  );
}

BoxDecoration unflattenPill({Color? accent, double opacity = 0.14}) {
  return BoxDecoration(
    color: (accent ?? UnflattenTokens.acid).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(UnflattenTokens.rFull),
    border: Border.all(
      color: (accent ?? UnflattenTokens.acid).withValues(alpha: opacity * 1.6),
    ),
  );
}
