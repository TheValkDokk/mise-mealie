import 'package:flutter/material.dart';

/// Mise's palette: charcoal, warm paper, one ember accent, sage for the
/// secondary. Photographs do the decorating; the chrome stays out of the way.
class MiseColors extends ThemeExtension<MiseColors> {
  const MiseColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.line,
    required this.ember,
    required this.emberInk,
    required this.sage,
    required this.danger,
    required this.scrim,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color line;
  final Color ember;
  final Color emberInk;
  final Color sage;
  final Color danger;
  final Color scrim;

  static const light = MiseColors(
    bg: Color(0xFFFBF6EE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF3EADD),
    ink: Color(0xFF191512),
    muted: Color(0xFF6E655C),
    faint: Color(0xFF9C9287),
    line: Color(0xFFE7DED1),
    ember: Color(0xFFBC3F1B),
    emberInk: Color(0xFFFFF8F3),
    sage: Color(0xFF5E7355),
    danger: Color(0xFFA63127),
    scrim: Color(0xFF120E0B),
  );

  static const dark = MiseColors(
    bg: Color(0xFF12100E),
    surface: Color(0xFF1B1815),
    surfaceAlt: Color(0xFF241F1A),
    ink: Color(0xFFF5EDE2),
    muted: Color(0xFFA99E90),
    faint: Color(0xFF7C7268),
    line: Color(0xFF2C2620),
    ember: Color(0xFFE0663C),
    emberInk: Color(0xFF1A0E08),
    sage: Color(0xFF8FA383),
    danger: Color(0xFFE0756A),
    scrim: Color(0xFF000000),
  );

  @override
  MiseColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? muted,
    Color? faint,
    Color? line,
    Color? ember,
    Color? emberInk,
    Color? sage,
    Color? danger,
    Color? scrim,
  }) {
    return MiseColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      line: line ?? this.line,
      ember: ember ?? this.ember,
      emberInk: emberInk ?? this.emberInk,
      sage: sage ?? this.sage,
      danger: danger ?? this.danger,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  MiseColors lerp(ThemeExtension<MiseColors>? other, double t) {
    if (other is! MiseColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return MiseColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      line: c(line, other.line),
      ember: c(ember, other.ember),
      emberInk: c(emberInk, other.emberInk),
      sage: c(sage, other.sage),
      danger: c(danger, other.danger),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension MiseContext on BuildContext {
  MiseColors get c => Theme.of(this).extension<MiseColors>() ?? MiseColors.light;

  TextStyle get display => TextStyle(
        fontSize: 34,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        color: c.ink,
      );

  TextStyle get headline => TextStyle(
        fontSize: 22,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: c.ink,
      );

  TextStyle get title => TextStyle(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: c.ink,
      );

  TextStyle get body => TextStyle(
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: c.ink,
      );

  TextStyle get small => TextStyle(
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: c.muted,
      );

  TextStyle get label => TextStyle(
        fontSize: 10.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: c.faint,
      );

  TextStyle get mono => TextStyle(
        fontFamily: 'SF Mono',
        fontFamilyFallback: const ['Menlo', 'Roboto Mono', 'monospace'],
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: c.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

ThemeData miseTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? MiseColors.dark : MiseColors.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.ember,
      brightness: brightness,
      surface: c.bg,
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    ),
    dividerColor: c.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.bg, fontSize: 13.5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
