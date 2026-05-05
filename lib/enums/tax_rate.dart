part of '../enums.dart';

/// Matches PHP `TaxRate` backed by int.
enum TaxRate {
  exempt(-2),
  noDeclaration(-1),
  zeroPercent(0),
  fivePercent(5),
  eightPercent(8),
  tenPercent(10);

  const TaxRate(this.value);

  final int value;

  String get label => switch (this) {
        TaxRate.exempt => 'Không chịu thuế',
        TaxRate.noDeclaration => 'Không kê khai, tính nộp thuế GTGT',
        TaxRate.zeroPercent => '0%',
        TaxRate.fivePercent => '5%',
        TaxRate.eightPercent => '8%',
        TaxRate.tenPercent => '10%',
      };

  /// `null` for [exempt] and [noDeclaration], same as PHP `percentage()`.
  int? get percentage => switch (this) {
        TaxRate.zeroPercent => 0,
        TaxRate.fivePercent => 5,
        TaxRate.eightPercent => 8,
        TaxRate.tenPercent => 10,
        TaxRate.exempt || TaxRate.noDeclaration => null,
      };

  static TaxRate? fromValue(int? value) {
    if (value == null) return null;
    try {
      return TaxRate.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}
