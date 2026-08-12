import 'package:flutter/material.dart';

/// Kích thước badge dùng chung.
enum BadgeSize { compact, normal, pill }

/// Variant hiển thị badge.
enum BadgeVariant {
  /// Hiển thị với nền nhạt + viền mỏng (Mặc định).
  filled,

  /// Chỉ có viền và chữ.
  outlined,

  /// Chế độ 'ghost': chỉ hiện text và icon, không có viền và background.
  ghost,
}

/// Helper lấy border radius và opacity badge theo theme hiện tại.
abstract final class AppBadgeTheme {
  static double borderRadius(
    BuildContext context, {
    BadgeSize size = BadgeSize.compact,
    double? override,
  }) {
    if (override != null) return override;

    final base = _fromChipTheme(context);
    return switch (size) {
      BadgeSize.compact => base > 4 ? base - 4 : base,
      BadgeSize.normal => base,
      BadgeSize.pill => base >= 12 ? 20 : base + 8,
    };
  }

  static double backgroundOpacity(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.12;
  }

  static double borderOpacity(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.22;
  }

  static EdgeInsets padding(BadgeSize size) {
    return switch (size) {
      BadgeSize.compact => const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      BadgeSize.normal => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      BadgeSize.pill => const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    };
  }

  static double fontSize(BadgeSize size) {
    return switch (size) {
      BadgeSize.compact => 10,
      BadgeSize.normal => 12,
      BadgeSize.pill => 11,
    };
  }

  static double _fromChipTheme(BuildContext context) {
    final shape = Theme.of(context).chipTheme.shape;
    if (shape case RoundedRectangleBorder(borderRadius: final radius)) {
      return radius.resolve(Directionality.of(context)).topLeft.x;
    }
    return 8;
  }
}
