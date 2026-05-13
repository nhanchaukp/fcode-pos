/// Appwrite Enums
library;

import 'package:fcode_pos/config/app_color.dart';
import 'package:flutter/material.dart';

part 'enums/order_status.dart';
part 'enums/tax_rate.dart';
part 'enums/financial_transaction_type.dart';
part 'enums/financial_transaction_category.dart';
part 'enums/account_master_service_type.dart';
part 'enums/invoice_currency.dart';
part 'enums/invoice_status.dart';
part 'enums/invoice_payment_method.dart';
part 'enums/invoice_unit.dart';
part 'enums/mail_log_status.dart';
part 'enums/refund_type.dart';
part 'enums/refund_status.dart';
part 'enums/refund_reason.dart';
part 'enums/buyer_type.dart';
part 'enums/line_type.dart';
part 'enums/coupon_type.dart';

abstract interface class LabeledIconEnum {
  String get label;
  IconData get icon;
  Color get color;
}

T? _enumFromValue<T extends Enum, V>(
  Iterable<T> values,
  V? value,
  V Function(T item) getValue,
) {
  if (value == null) return null;
  for (final item in values) {
    if (getValue(item) == value) return item;
  }
  return null;
}

T? _enumFromStringValue<T extends Enum>(
  Iterable<T> values,
  String? value,
  String Function(T item) getValue, {
  bool trim = true,
  bool caseInsensitive = false,
  bool allowEmpty = false,
}) {
  if (value == null) return null;
  var normalizedInput = trim ? value.trim() : value;
  if (normalizedInput.isEmpty && !allowEmpty) return null;
  if (caseInsensitive) normalizedInput = normalizedInput.toLowerCase();

  for (final item in values) {
    var enumValue = getValue(item);
    if (trim) enumValue = enumValue.trim();
    if (caseInsensitive) enumValue = enumValue.toLowerCase();
    if (enumValue == normalizedInput) return item;
  }
  return null;
}
