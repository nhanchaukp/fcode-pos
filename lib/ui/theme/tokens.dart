import 'package:flutter/material.dart';

/// Spacing tokens dùng chung cho toàn bộ app.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
}

/// Radius tokens dùng chung cho toàn bộ app.
class AppRadius {
  const AppRadius._();

  static const BorderRadius s = BorderRadius.all(Radius.circular(8));
  static const BorderRadius m = BorderRadius.all(Radius.circular(12));
  static const BorderRadius l = BorderRadius.all(Radius.circular(16));
}

