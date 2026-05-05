part of '../enums.dart';

enum InvoiceUnit {
  piece('Cái / chiếc', 'piece'),
  set_('Bộ', 'set'),
  box('Hộp', 'box'),
  package('Gói', 'package'),
  service('Dịch vụ', 'service'),
  hour('Giờ', 'hour'),
  day('Ngày', 'day'),
  month('Tháng', 'month'),
  year('Năm', 'year'),
  kg('Kilogram', 'kg'),
  g('Gram', 'g'),
  m('Mét', 'm'),
  l('Lít', 'l');

  const InvoiceUnit(this.label, this.value);

  final String label;
  final String value;

  static InvoiceUnit? fromValue(String? value) {
    if (value == null) return null;
    try {
      return InvoiceUnit.values.firstWhere((u) => u.value == value);
    } catch (e) {
      return null;
    }
  }
}
