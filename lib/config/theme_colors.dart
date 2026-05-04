import 'package:flutter/material.dart';

// ── AppColors ThemeExtension ──────────────────────────────────────────────────

/// Màu ngữ nghĩa (semantic) cho SnackBar / badge: success, info, warning, danger.
/// Đăng ký vào ThemeData.extensions, truy cập qua Theme.of(ctx).extension<AppColors>().
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.info,
    required this.onInfo,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
  });

  final Color success;
  final Color onSuccess;
  final Color info;
  final Color onInfo;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? info,
    Color? onInfo,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
  }) =>
      AppColors(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        info: info ?? this.info,
        onInfo: onInfo ?? this.onInfo,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        danger: danger ?? this.danger,
        onDanger: onDanger ?? this.onDanger,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

// ── ThemePalette ──────────────────────────────────────────────────────────────

/// Một bộ màu đầy đủ cho cả light và dark mode.
class ThemePalette {
  final String name;
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;
  final Color? _previewColor;

  /// Border radius áp dụng cho card, button, input.
  /// Dùng [Radius.zero] cho các theme "sharp" như Industrial.
  final double borderRadius;

  final AppColors colors;

  const ThemePalette({
    required this.name,
    required this.lightScheme,
    required this.darkScheme,
    required this.colors,
    Color? previewColor,
    this.borderRadius = 12,
  }) : _previewColor = previewColor;

  /// Tạo palette từ seed color (Material 3 tonal).
  factory ThemePalette.fromSeed(String name, Color seed,
      {AppColors colors = _defaultColors}) {
    return ThemePalette(
      name: name,
      lightScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      darkScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      colors: colors,
      previewColor: seed,
    );
  }

  /// Màu hiển thị trong bộ chọn palette (dùng seed hoặc primary light).
  Color get previewColor => _previewColor ?? lightScheme.primary;
}

// ── Tailwind CSS v4 neutral palette values ────────────────────────────────────
// neutral-50:  #fafafa  neutral-100: #f5f5f5  neutral-200: #e5e5e5
// neutral-300: #d4d4d4  neutral-400: #a3a3a3  neutral-500: #737373
// neutral-600: #525252  neutral-700: #404040  neutral-800: #262626
// neutral-900: #171717  neutral-950: #0a0a0a

// ── Minimal — light ───────────────────────────────────────────────────────────
const _minimalLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF000000),           // black
  onPrimary: Color(0xFFf5f5f5),         // neutral-100
  primaryContainer: Color(0xFFe5e5e5),  // neutral-200
  onPrimaryContainer: Color(0xFF171717), // neutral-900
  secondary: Color(0xFF262626),         // neutral-800
  onSecondary: Color(0xFFffffff),
  secondaryContainer: Color(0xFFf5f5f5), // neutral-100
  onSecondaryContainer: Color(0xFF404040), // neutral-700
  tertiary: Color(0xFF525252),          // neutral-600
  onTertiary: Color(0xFFffffff),
  tertiaryContainer: Color(0xFFf5f5f5),
  onTertiaryContainer: Color(0xFF525252),
  error: Color(0xFFba1a1a),
  onError: Color(0xFFffffff),
  errorContainer: Color(0xFFffdad6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFffffff),
  onSurface: Color(0xFF171717),         // neutral-900 (on-surface-strong)
  surfaceDim: Color(0xFFe5e5e5),        // neutral-200
  surfaceBright: Color(0xFFffffff),
  surfaceContainerLowest: Color(0xFFffffff),
  surfaceContainerLow: Color(0xFFfafafa), // neutral-50
  surfaceContainer: Color(0xFFfafafa),    // neutral-50
  surfaceContainerHigh: Color(0xFFf5f5f5), // neutral-100
  surfaceContainerHighest: Color(0xFFe5e5e5), // neutral-200
  onSurfaceVariant: Color(0xFF525252),  // neutral-600 (on-surface)
  outline: Color(0xFFd4d4d4),           // neutral-300
  outlineVariant: Color(0xFFe5e5e5),    // neutral-200
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF171717),    // neutral-900
  onInverseSurface: Color(0xFFfafafa),  // neutral-50
  inversePrimary: Color(0xFFd4d4d4),   // neutral-300
);

// ── Minimal — dark ────────────────────────────────────────────────────────────
const _minimalDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFffffff),           // white
  onPrimary: Color(0xFF000000),         // black
  primaryContainer: Color(0xFF262626),  // neutral-800
  onPrimaryContainer: Color(0xFFfafafa), // neutral-50
  secondary: Color(0xFFd4d4d4),         // neutral-300
  onSecondary: Color(0xFF000000),       // black
  secondaryContainer: Color(0xFF262626), // neutral-800
  onSecondaryContainer: Color(0xFFd4d4d4),
  tertiary: Color(0xFFa3a3a3),          // neutral-400
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF262626),
  onTertiaryContainer: Color(0xFFd4d4d4),
  error: Color(0xFFCF6679),
  onError: Color(0xFF000000),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF0a0a0a),           // neutral-950
  onSurface: Color(0xFFffffff),         // white (on-surface-strong)
  surfaceDim: Color(0xFF0a0a0a),        // neutral-950
  surfaceBright: Color(0xFF262626),     // neutral-800
  surfaceContainerLowest: Color(0xFF0a0a0a), // neutral-950
  surfaceContainerLow: Color(0xFF0a0a0a),
  surfaceContainer: Color(0xFF171717),  // neutral-900 (surface-alt)
  surfaceContainerHigh: Color(0xFF262626), // neutral-800
  surfaceContainerHighest: Color(0xFF404040), // neutral-700
  onSurfaceVariant: Color(0xFFd4d4d4),  // neutral-300 (on-surface-dark)
  outline: Color(0xFF404040),           // neutral-700
  outlineVariant: Color(0xFF262626),    // neutral-800
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFe5e5e5),   // neutral-200
  onInverseSurface: Color(0xFF171717),
  inversePrimary: Color(0xFF404040),   // neutral-700
);

// ── Tailwind CSS v4 stone & amber values used in Industrial ──────────────────
// stone-50:#fafaf9  stone-100:#f5f5f4  stone-200:#e7e5e4  stone-300:#d6d3d1
// stone-400:#a8a29e stone-600:#57534e  stone-700:#44403c  stone-800:#292524
// stone-900:#1c1917 stone-950:#0c0a09
// amber-400:#fbbf24 amber-500:#f59e0b  blue-600:#2563eb   blue-500:#3b82f6

// ── Industrial — light ────────────────────────────────────────────────────────
const _industrialLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFf59e0b),           // amber-500
  onPrimary: Color(0xFF000000),         // black
  primaryContainer: Color(0xFFfef3c7),  // amber-100
  onPrimaryContainer: Color(0xFF78350f), // amber-900
  secondary: Color(0xFF1c1917),         // stone-900
  onSecondary: Color(0xFFfafaf9),       // stone-50
  secondaryContainer: Color(0xFFe7e5e4), // stone-200
  onSecondaryContainer: Color(0xFF292524), // stone-800
  tertiary: Color(0xFF57534e),          // stone-600
  onTertiary: Color(0xFFffffff),
  tertiaryContainer: Color(0xFFf5f5f4), // stone-100
  onTertiaryContainer: Color(0xFF44403c), // stone-700
  error: Color(0xFFdc2626),             // red-600
  onError: Color(0xFFf1f5f9),           // slate-100
  errorContainer: Color(0xFFfee2e2),
  onErrorContainer: Color(0xFF7f1d1d),
  surface: Color(0xFFfafaf9),           // stone-50
  onSurface: Color(0xFF000000),         // black (on-surface-strong)
  surfaceDim: Color(0xFFe7e5e4),        // stone-200
  surfaceBright: Color(0xFFfafaf9),
  surfaceContainerLowest: Color(0xFFffffff),
  surfaceContainerLow: Color(0xFFfafaf9),  // stone-50
  surfaceContainer: Color(0xFFf5f5f4),     // stone-100
  surfaceContainerHigh: Color(0xFFe7e5e4), // stone-200
  surfaceContainerHighest: Color(0xFFd6d3d1), // stone-300
  onSurfaceVariant: Color(0xFF292524),  // stone-800 (on-surface)
  outline: Color(0x00000000),           // transparent
  outlineVariant: Color(0x00000000),    // transparent
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1c1917),    // stone-900
  onInverseSurface: Color(0xFFfafaf9),  // stone-50
  inversePrimary: Color(0xFF78350f),    // amber-900
);

// ── Industrial — dark ─────────────────────────────────────────────────────────
const _industrialDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFfbbf24),           // amber-400
  onPrimary: Color(0xFF000000),         // black
  primaryContainer: Color(0xFF92400e),  // amber-800
  onPrimaryContainer: Color(0xFFfef3c7), // amber-100
  secondary: Color(0xFF44403c),         // stone-700
  onSecondary: Color(0xFFffffff),       // white
  secondaryContainer: Color(0xFF292524), // stone-800
  onSecondaryContainer: Color(0xFFd6d3d1), // stone-300
  tertiary: Color(0xFFa8a29e),          // stone-400
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF292524), // stone-800
  onTertiaryContainer: Color(0xFFd6d3d1), // stone-300
  error: Color(0xFFdc2626),             // red-600
  onError: Color(0xFFf1f5f9),           // slate-100
  errorContainer: Color(0xFF7f1d1d),
  onErrorContainer: Color(0xFFfee2e2),
  surface: Color(0xFF0c0a09),           // stone-950
  onSurface: Color(0xFFffffff),         // white (on-surface-dark-strong)
  surfaceDim: Color(0xFF0c0a09),
  surfaceBright: Color(0xFF44403c),     // stone-700
  surfaceContainerLowest: Color(0xFF0c0a09),
  surfaceContainerLow: Color(0xFF0c0a09),
  surfaceContainer: Color(0xFF1c1917),  // stone-900 (surface-alt)
  surfaceContainerHigh: Color(0xFF292524), // stone-800
  surfaceContainerHighest: Color(0xFF44403c), // stone-700
  onSurfaceVariant: Color(0xFFd6d3d1),  // stone-300 (on-surface-dark)
  outline: Color(0xFF44403c),           // stone-700
  outlineVariant: Color(0xFF292524),    // stone-800
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFe7e5e4),   // stone-200
  onInverseSurface: Color(0xFF1c1917),
  inversePrimary: Color(0xFFd97706),   // amber-600
);

// ── Tailwind CSS v4 values used in Pastel ────────────────────────────────────
// amber-50:#fffbeb  amber-100:#fef3c7  amber-300:#fcd34d  amber-700:#b45309
// neutral-200:#e5e5e5 neutral-500:#737373 neutral-600:#525252 neutral-700:#404040
// neutral-800:#262626 neutral-900:#171717
// rose-400:#fb7185   rose-100:#ffe4e6   rose-800:#9f1239   rose-200:#fecdd3
// orange-200:#fed7aa orange-50:#fff7ed  orange-100:#ffedd5
// violet-100:#ede9fe violet-300:#c4b5fd

// ── Pastel — light ────────────────────────────────────────────────────────────
const _pastelLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFfb7185),           // rose-400
  onPrimary: Color(0xFFffffff),
  primaryContainer: Color(0xFFffe4e6),  // rose-100
  onPrimaryContainer: Color(0xFF9f1239), // rose-800
  secondary: Color(0xFFfed7aa),         // orange-200
  onSecondary: Color(0xFF262626),       // neutral-800
  secondaryContainer: Color(0xFFfef3c7), // amber-100
  onSecondaryContainer: Color(0xFF92400e),
  tertiary: Color(0xFFc4b5fd),          // violet-300
  onTertiary: Color(0xFF4c1d95),        // violet-900
  tertiaryContainer: Color(0xFFede9fe), // violet-100
  onTertiaryContainer: Color(0xFF6d28d9),
  error: Color(0xFFf87171),             // red-400 (pastel red)
  onError: Color(0xFFffffff),
  errorContainer: Color(0xFFfee2e2),    // red-100
  onErrorContainer: Color(0xFF991b1b),  // red-800
  surface: Color(0xFFfffbeb),           // amber-50
  onSurface: Color(0xFF404040),         // neutral-700 (on-surface-strong)
  surfaceDim: Color(0xFFfef3c7),        // amber-100
  surfaceBright: Color(0xFFfffbeb),
  surfaceContainerLowest: Color(0xFFffffff),
  surfaceContainerLow: Color(0xFFfffbeb),  // amber-50
  surfaceContainer: Color(0xFFfef3c7),     // amber-100 (surface-alt)
  surfaceContainerHigh: Color(0xFFfff7ed), // orange-50
  surfaceContainerHighest: Color(0xFFffedd5), // orange-100
  onSurfaceVariant: Color(0xFF737373),  // neutral-500 (on-surface)
  outline: Color(0xFFe5e5e5),           // neutral-200
  outlineVariant: Color(0xFFe5e5e5),    // neutral-200
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF262626),    // neutral-800
  onInverseSurface: Color(0xFFf5f5f5), // neutral-100
  inversePrimary: Color(0xFFfecdd3),   // rose-200
);

// ── Pastel — dark ─────────────────────────────────────────────────────────────
const _pastelDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFfb7185),           // rose-400
  onPrimary: Color(0xFFffffff),
  primaryContainer: Color(0xFF9f1239),  // rose-800
  onPrimaryContainer: Color(0xFFffe4e6), // rose-100
  secondary: Color(0xFFfed7aa),         // orange-200
  onSecondary: Color(0xFF262626),       // neutral-800
  secondaryContainer: Color(0xFF262626), // neutral-800
  onSecondaryContainer: Color(0xFFfed7aa), // orange-200
  tertiary: Color(0xFFc4b5fd),          // violet-300
  onTertiary: Color(0xFF4c1d95),        // violet-900
  tertiaryContainer: Color(0xFF404040), // neutral-700
  onTertiaryContainer: Color(0xFFede9fe), // violet-100
  error: Color(0xFFfca5a5),             // red-300 (pastel)
  onError: Color(0xFF991b1b),           // red-800
  errorContainer: Color(0xFF7f1d1d),
  onErrorContainer: Color(0xFFfecaca),  // red-200
  surface: Color(0xFF171717),           // neutral-900
  onSurface: Color(0xFFffffff),         // white (on-surface-dark-strong)
  surfaceDim: Color(0xFF171717),
  surfaceBright: Color(0xFF404040),     // neutral-700
  surfaceContainerLowest: Color(0xFF171717),
  surfaceContainerLow: Color(0xFF171717),
  surfaceContainer: Color(0xFF262626),  // neutral-800 (surface-alt)
  surfaceContainerHigh: Color(0xFF404040), // neutral-700
  surfaceContainerHighest: Color(0xFF404040),
  onSurfaceVariant: Color(0xFFede9fe),  // violet-100 (on-surface-dark)
  outline: Color(0xFF404040),           // neutral-700
  outlineVariant: Color(0xFF525252),    // neutral-600
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFe5e5e5),   // neutral-200
  onInverseSurface: Color(0xFF262626),
  inversePrimary: Color(0xFFe11d48),   // rose-600
);

// ── Tailwind CSS v4 values used in Arctic ─────────────────────────────────────
// slate-100:#f1f5f9  slate-200:#e2e8f0  slate-300:#cbd5e1  slate-400:#94a3b8
// slate-600:#475569  slate-700:#334155  slate-800:#1e293b  slate-900:#0f172a
// blue-100:#dbeafe   blue-200:#bfdbfe   blue-600:#2563eb   blue-700:#1d4ed8
// blue-800:#1e40af   blue-300:#93c5fd
// indigo-100:#e0e7ff indigo-200:#c7d2fe indigo-600:#4f46e5 indigo-700:#4338ca
// indigo-800:#3730a3

// ── Arctic — light ────────────────────────────────────────────────────────────
const _arcticLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1d4ed8),           // blue-700
  onPrimary: Color(0xFFf1f5f9),         // slate-100
  primaryContainer: Color(0xFFdbeafe),  // blue-100
  onPrimaryContainer: Color(0xFF1e40af), // blue-800
  secondary: Color(0xFF4338ca),         // indigo-700
  onSecondary: Color(0xFFf1f5f9),       // slate-100
  secondaryContainer: Color(0xFFe0e7ff), // indigo-100
  onSecondaryContainer: Color(0xFF3730a3), // indigo-800
  tertiary: Color(0xFF475569),          // slate-600
  onTertiary: Color(0xFFffffff),
  tertiaryContainer: Color(0xFFf1f5f9), // slate-100
  onTertiaryContainer: Color(0xFF334155), // slate-700
  error: Color(0xFFdc2626),             // red-600
  onError: Color(0xFFffffff),
  errorContainer: Color(0xFFfee2e2),
  onErrorContainer: Color(0xFF7f1d1d),
  surface: Color(0xFFffffff),           // white
  onSurface: Color(0xFF000000),         // black (on-surface-strong)
  surfaceDim: Color(0xFFe2e8f0),        // slate-200
  surfaceBright: Color(0xFFffffff),
  surfaceContainerLowest: Color(0xFFffffff),
  surfaceContainerLow: Color(0xFFffffff),
  surfaceContainer: Color(0xFFf1f5f9),     // slate-100 (surface-alt)
  surfaceContainerHigh: Color(0xFFe2e8f0), // slate-200
  surfaceContainerHighest: Color(0xFFcbd5e1), // slate-300
  onSurfaceVariant: Color(0xFF334155),  // slate-700 (on-surface)
  outline: Color(0xFFcbd5e1),           // slate-300
  outlineVariant: Color(0xFFcbd5e1),    // slate-300
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1e293b),    // slate-800
  onInverseSurface: Color(0xFFf1f5f9), // slate-100
  inversePrimary: Color(0xFF93c5fd),   // blue-300
);

// ── Arctic — dark ─────────────────────────────────────────────────────────────
const _arcticDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF2563eb),           // blue-600
  onPrimary: Color(0xFFf1f5f9),         // slate-100
  primaryContainer: Color(0xFF1e40af),  // blue-800
  onPrimaryContainer: Color(0xFFdbeafe), // blue-100
  secondary: Color(0xFF4f46e5),         // indigo-600
  onSecondary: Color(0xFFf1f5f9),       // slate-100
  secondaryContainer: Color(0xFF3730a3), // indigo-800
  onSecondaryContainer: Color(0xFFc7d2fe), // indigo-200
  tertiary: Color(0xFF94a3b8),          // slate-400
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF1e293b), // slate-800
  onTertiaryContainer: Color(0xFFcbd5e1), // slate-300
  error: Color(0xFFdc2626),             // red-600
  onError: Color(0xFFf1f5f9),
  errorContainer: Color(0xFF7f1d1d),
  onErrorContainer: Color(0xFFfee2e2),
  surface: Color(0xFF0f172a),           // slate-900
  onSurface: Color(0xFFffffff),         // white (on-surface-dark-strong)
  surfaceDim: Color(0xFF0f172a),
  surfaceBright: Color(0xFF334155),     // slate-700
  surfaceContainerLowest: Color(0xFF0f172a),
  surfaceContainerLow: Color(0xFF0f172a),
  surfaceContainer: Color(0xFF1e293b),     // slate-800 (surface-alt)
  surfaceContainerHigh: Color(0xFF334155), // slate-700
  surfaceContainerHighest: Color(0xFF475569), // slate-600
  onSurfaceVariant: Color(0xFFcbd5e1),  // slate-300 (on-surface-dark)
  outline: Color(0xFF334155),           // slate-700
  outlineVariant: Color(0xFF475569),    // slate-600
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFe2e8f0),   // slate-200
  onInverseSurface: Color(0xFF1e293b),
  inversePrimary: Color(0xFF93c5fd),   // blue-300
);

// ── Tailwind CSS v4 values used in High Contrast ──────────────────────────────
// gray-50:#f9fafb   gray-100:#f3f4f6  gray-200:#e5e7eb  gray-300:#d1d5db
// gray-400:#9ca3af  gray-500:#6b7280  gray-600:#4b5563  gray-700:#374151
// gray-800:#1f2937  gray-900:#111827  gray-950:#030712
// sky-100:#e0f2fe   sky-300:#7dd3fc   sky-400:#38bdf8   sky-500:#0ea5e9
// sky-700:#0369a1   sky-900:#0c4a6e
// indigo-100:#e0e7ff indigo-400:#818cf8 indigo-900:#312e81

// ── High Contrast — light ─────────────────────────────────────────────────────
const _highContrastLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF0c4a6e),           // sky-900
  onPrimary: Color(0xFFffffff),
  primaryContainer: Color(0xFFbae6fd),  // sky-200
  onPrimaryContainer: Color(0xFF0c4a6e), // sky-900
  secondary: Color(0xFF312e81),         // indigo-900
  onSecondary: Color(0xFFffffff),
  secondaryContainer: Color(0xFFe0e7ff), // indigo-100
  onSecondaryContainer: Color(0xFF312e81), // indigo-900
  tertiary: Color(0xFF4b5563),          // gray-600
  onTertiary: Color(0xFFffffff),
  tertiaryContainer: Color(0xFFe5e7eb), // gray-200
  onTertiaryContainer: Color(0xFF1f2937), // gray-800
  error: Color(0xFFef4444),             // red-500
  onError: Color(0xFF000000),
  errorContainer: Color(0xFFfee2e2),
  onErrorContainer: Color(0xFF7f1d1d),
  surface: Color(0xFFf9fafb),           // gray-50
  onSurface: Color(0xFF030712),         // gray-950 (on-surface-strong)
  surfaceDim: Color(0xFFe5e7eb),        // gray-200
  surfaceBright: Color(0xFFf9fafb),
  surfaceContainerLowest: Color(0xFFffffff),
  surfaceContainerLow: Color(0xFFf9fafb),  // gray-50
  surfaceContainer: Color(0xFFf3f4f6),     // gray-100
  surfaceContainerHigh: Color(0xFFe5e7eb), // gray-200
  surfaceContainerHighest: Color(0xFFd1d5db), // gray-300
  onSurfaceVariant: Color(0xFF1f2937),  // gray-800 (on-surface)
  outline: Color(0xFF6b7280),           // gray-500
  outlineVariant: Color(0xFF6b7280),    // gray-500
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF111827),    // gray-900
  onInverseSurface: Color(0xFFf3f4f6), // gray-100
  inversePrimary: Color(0xFF7dd3fc),   // sky-300
);

// ── High Contrast — dark ──────────────────────────────────────────────────────
const _highContrastDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF38bdf8),           // sky-400
  onPrimary: Color(0xFF000000),
  primaryContainer: Color(0xFF0c4a6e),  // sky-900
  onPrimaryContainer: Color(0xFFe0f2fe), // sky-100
  secondary: Color(0xFF818cf8),         // indigo-400
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFF312e81), // indigo-900
  onSecondaryContainer: Color(0xFFe0e7ff), // indigo-100
  tertiary: Color(0xFF9ca3af),          // gray-400
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF1f2937), // gray-800
  onTertiaryContainer: Color(0xFFd1d5db), // gray-300
  error: Color(0xFFef4444),             // red-500
  onError: Color(0xFF000000),
  errorContainer: Color(0xFF7f1d1d),
  onErrorContainer: Color(0xFFfee2e2),
  surface: Color(0xFF111827),           // gray-900
  onSurface: Color(0xFFf3f4f6),         // gray-100 (on-surface-dark-strong)
  surfaceDim: Color(0xFF111827),
  surfaceBright: Color(0xFF374151),     // gray-700
  surfaceContainerLowest: Color(0xFF111827),
  surfaceContainerLow: Color(0xFF111827),
  surfaceContainer: Color(0xFF1f2937),     // gray-800 (surface-alt)
  surfaceContainerHigh: Color(0xFF374151), // gray-700
  surfaceContainerHighest: Color(0xFF4b5563), // gray-600
  onSurfaceVariant: Color(0xFFd1d5db),  // gray-300 (on-surface-dark)
  outline: Color(0xFF6b7280),           // gray-500
  outlineVariant: Color(0xFF6b7280),    // gray-500
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFe5e7eb),   // gray-200
  onInverseSurface: Color(0xFF1f2937),
  inversePrimary: Color(0xFF0369a1),   // sky-700
);

// ── AppColors instances per palette ──────────────────────────────────────────

// Default (dùng làm fallback & Minimal)
const _defaultColors = AppColors(
  success:   Color(0xFF16a34a), onSuccess: Color(0xFFffffff), // green-600
  info:      Color(0xFF0284c7), onInfo:    Color(0xFFffffff), // sky-600
  warning:   Color(0xFFf59e0b), onWarning: Color(0xFF0f172a), // amber-500 / slate-900
  danger:    Color(0xFFdc2626), onDanger:  Color(0xFFffffff), // red-600
);

// Industrial: vivid semantic colors (shared light/dark per CSS)
const _industrialColors = AppColors(
  success:   Color(0xFF16a34a), onSuccess: Color(0xFFffffff), // green-600
  info:      Color(0xFF0284c7), onInfo:    Color(0xFFf1f5f9), // sky-600 / slate-100
  warning:   Color(0xFFf59e0b), onWarning: Color(0xFF0f172a), // amber-500 / slate-900
  danger:    Color(0xFFdc2626), onDanger:  Color(0xFFf1f5f9), // red-600 / slate-100
);

// Pastel: soft pastel semantic colors
const _pastelColors = AppColors(
  success:   Color(0xFF86efac), onSuccess: Color(0xFF166534), // green-300 / green-800
  info:      Color(0xFF93c5fd), onInfo:    Color(0xFF075985), // blue-300 / sky-800
  warning:   Color(0xFFfcd34d), onWarning: Color(0xFFb45309), // amber-300 / amber-700
  danger:    Color(0xFFfca5a5), onDanger:  Color(0xFF991b1b), // red-300 / red-800
);

// Arctic: crisp on-white semantic colors
const _arcticColors = AppColors(
  success:   Color(0xFF16a34a), onSuccess: Color(0xFFffffff), // green-600
  info:      Color(0xFF0284c7), onInfo:    Color(0xFFffffff), // sky-600
  warning:   Color(0xFFf59e0b), onWarning: Color(0xFFffffff), // amber-500
  danger:    Color(0xFFdc2626), onDanger:  Color(0xFFffffff), // red-600
);

// High Contrast: vivid on-black semantic colors
const _highContrastColors = AppColors(
  success:   Color(0xFF22c55e), onSuccess: Color(0xFF000000), // green-500
  info:      Color(0xFF0ea5e9), onInfo:    Color(0xFF000000), // sky-500
  warning:   Color(0xFFeab308), onWarning: Color(0xFF000000), // yellow-500
  danger:    Color(0xFFef4444), onDanger:  Color(0xFF000000), // red-500
);

// ── Palette list ──────────────────────────────────────────────────────────────

/// Danh sách palette toàn custom — không dùng ColorScheme.fromSeed.
/// Thêm palette mới bằng cách khai báo _xxxLight / _xxxDark và đưa vào list.
final List<ThemePalette> themePalettes = [
  const ThemePalette(
    name: 'Minimal',
    lightScheme: _minimalLight,
    darkScheme: _minimalDark,
    colors: _defaultColors,
    previewColor: Color(0xFF737373), // neutral-500
  ),
  const ThemePalette(
    name: 'Industrial',
    lightScheme: _industrialLight,
    darkScheme: _industrialDark,
    colors: _industrialColors,
    previewColor: Color(0xFFf59e0b), // amber-500
    borderRadius: 0,
  ),
  const ThemePalette(
    name: 'Pastel',
    lightScheme: _pastelLight,
    darkScheme: _pastelDark,
    colors: _pastelColors,
    previewColor: Color(0xFFfb7185), // rose-400
    borderRadius: 16,
  ),
  const ThemePalette(
    name: 'Arctic',
    lightScheme: _arcticLight,
    darkScheme: _arcticDark,
    colors: _arcticColors,
    previewColor: Color(0xFF2563eb), // blue-600
    borderRadius: 12,
  ),
  const ThemePalette(
    name: 'High Contrast',
    lightScheme: _highContrastLight,
    darkScheme: _highContrastDark,
    colors: _highContrastColors,
    previewColor: Color(0xFF0c4a6e), // sky-900
    borderRadius: 4,
  ),
];
