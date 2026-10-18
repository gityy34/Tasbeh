import 'package:flutter/material.dart';

import '../models/app_models.dart';

class CounterColors {
  const CounterColors({
    required this.top,
    required this.bottom,
    required this.accent,
    required this.accentSoft,
    required this.foreground,
  });

  final Color top;
  final Color bottom;
  final Color accent;
  final Color accentSoft;
  final Color foreground;
}

CounterColors counterColorsFor(
  CounterPalette palette,
  TextTone tone,
) {
  final foreground = switch (tone) {
    TextTone.white => Colors.white,
    TextTone.navy => const Color(0xFF102A43),
    TextTone.cream => const Color(0xFFFFF3D6),
  };
  return switch (palette) {
    CounterPalette.water => CounterColors(
        top: const Color(0xFF6DD5FA),
        bottom: const Color(0xFF0878D1),
        accent: const Color(0xFF37B9FF),
        accentSoft: const Color(0xFFB9EEFF),
        foreground: foreground,
      ),
    CounterPalette.realisticWater => CounterColors(
        top: const Color(0xFF9CEBFF),
        bottom: const Color(0xFF0878D1),
        accent: const Color(0xFF28B8F2),
        accentSoft: const Color(0xFFD9F8FF),
        foreground: foreground,
      ),
    CounterPalette.nature => CounterColors(
        top: const Color(0xFF8FD694),
        bottom: const Color(0xFF237A57),
        accent: const Color(0xFFB8F2B0),
        accentSoft: const Color(0xFFD9F8D1),
        foreground: foreground,
      ),
    CounterPalette.sunrise => CounterColors(
        top: const Color(0xFFFFD89B),
        bottom: const Color(0xFFCE7A35),
        accent: const Color(0xFFFFE3A9),
        accentSoft: const Color(0xFFFFF0CB),
        foreground: tone == TextTone.white ? Colors.white : foreground,
      ),
    CounterPalette.midnight => CounterColors(
        top: const Color(0xFF304E75),
        bottom: const Color(0xFF071C3A),
        accent: const Color(0xFFFFD779),
        accentSoft: const Color(0xFFB6D8FF),
        foreground: tone == TextTone.navy ? Colors.white : foreground,
      ),
  };
}

const autoDayStartHour = 6;
const autoNightStartHour = 17;

bool isAutoDaytime(DateTime now) {
  final minuteOfDay = now.hour * 60 + now.minute;
  return minuteOfDay >= autoDayStartHour * 60 &&
      minuteOfDay < autoNightStartHour * 60;
}

Brightness effectiveBrightness(AppThemeMode mode, DateTime now) {
  return switch (mode) {
    AppThemeMode.day => Brightness.light,
    AppThemeMode.night => Brightness.dark,
    AppThemeMode.auto => isAutoDaytime(now) ? Brightness.light : Brightness.dark,
  };
}

ThemeData buildTasbehTheme({
  required Brightness brightness,
  required CounterPalette palette,
  required TextTone textTone,
}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: isDark ? const Color(0xFF2C9CFF) : const Color(0xFF117BC8),
    brightness: brightness,
  );
  final surface = isDark ? const Color(0xFF071C3A) : const Color(0xFFF4F9FE);
  final onSurface = isDark ? const Color(0xFFF5F9FF) : const Color(0xFF102A43);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    appBarTheme: AppBarTheme(
      backgroundColor: surface.withValues(alpha: 0.92),
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF102D50) : Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF102D50) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.35),
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: onSurface,
          displayColor: onSurface,
        ),
    extensions: <ThemeExtension<dynamic>>[
      TasbehThemeExtension(
        counter: counterColorsFor(palette, textTone),
        isDark: isDark,
      ),
    ],
  );
}

class TasbehThemeExtension extends ThemeExtension<TasbehThemeExtension> {
  const TasbehThemeExtension({required this.counter, required this.isDark});

  final CounterColors counter;
  final bool isDark;

  @override
  TasbehThemeExtension copyWith({CounterColors? counter, bool? isDark}) {
    return TasbehThemeExtension(
      counter: counter ?? this.counter,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  TasbehThemeExtension lerp(
    covariant ThemeExtension<TasbehThemeExtension>? other,
    double t,
  ) {
    if (other is! TasbehThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension TasbehThemeContext on BuildContext {
  TasbehThemeExtension get tasbehTheme =>
      Theme.of(this).extension<TasbehThemeExtension>()!;
}

