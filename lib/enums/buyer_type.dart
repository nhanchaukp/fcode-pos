part of '../enums.dart';

enum BuyerType implements LabeledIconEnum {
  personal('personal', 'Cá nhân'),
  company('company', 'Công ty');

  const BuyerType(this.value, this.label);

  final String value;

  @override
  final String label;

  @override
  IconData get icon => switch (this) {
    BuyerType.personal => Icons.person,
    BuyerType.company => Icons.business,
  };

  @override
  Color get color => switch (this) {
    BuyerType.personal => AppColor.blue,
    BuyerType.company => AppColor.indigo,
  };

  static BuyerType? fromValue(String? value) {
    return _enumFromStringValue(
      BuyerType.values,
      value,
      (type) => type.value,
      caseInsensitive: true,
    );
  }
}
