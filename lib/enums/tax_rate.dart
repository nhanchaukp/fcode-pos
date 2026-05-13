part of '../enums.dart';

/// Matches PHP `TaxRate` backed by int.
enum TaxRate implements LabeledIconEnum {
  exempt(-2),
  noDeclaration(-1),
  zeroPercent(0),
  fivePercent(5),
  eightPercent(8),
  tenPercent(10);

  const TaxRate(this.value);

  final int value;

  @override
  String get label => switch (this) {
    TaxRate.exempt => 'Không chịu thuế',
    TaxRate.noDeclaration => 'Không kê khai, tính nộp thuế GTGT',
    TaxRate.zeroPercent => '0%',
    TaxRate.fivePercent => '5%',
    TaxRate.eightPercent => '8%',
    TaxRate.tenPercent => '10%',
  };

  @override
  IconData get icon => switch (this) {
    TaxRate.exempt => Icons.money_off,
    TaxRate.noDeclaration => Icons.description,
    TaxRate.zeroPercent => Icons.percent,
    TaxRate.fivePercent => Icons.percent,
    TaxRate.eightPercent => Icons.percent,
    TaxRate.tenPercent => Icons.percent,
  };

  @override
  Color get color => switch (this) {
    TaxRate.exempt => AppColor.gray,
    TaxRate.noDeclaration => AppColor.indigo,
    TaxRate.zeroPercent => AppColor.teal,
    TaxRate.fivePercent => AppColor.green,
    TaxRate.eightPercent => AppColor.orange,
    TaxRate.tenPercent => AppColor.red,
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
    return _enumFromValue(TaxRate.values, value, (item) => item.value);
  }
}
