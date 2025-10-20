import 'package:flutter/material.dart';

/// Extension on [BuildContext] to provide easy access to media query properties.
extension MediaQueryExtensions on BuildContext {
  /// Returns `true` if the device width is greater than 768 pixels.
  bool get isLargeScreen => MediaQuery.of(this).size.width > 768;

  bool get isExtraWideScreen => MediaQuery.of(this).size.width > 1024;

  /// Returns `true` if the device width is 768 pixels or less.
  bool get isMobile => !isLargeScreen;

  /// Returns a scaled width factor based on the screen size.
  double widthFactor({
    required double mobileFactor,
    required double largeScreenFactor,
  }) {
    return MediaQuery.of(this).size.width *
        (isMobile ? mobileFactor : largeScreenFactor);
  }
}
