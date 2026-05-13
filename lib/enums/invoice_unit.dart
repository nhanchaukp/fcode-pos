part of '../enums.dart';

enum InvoiceUnit implements LabeledIconEnum {
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

  @override
  final String label;
  final String value;

  @override
  IconData get icon => switch (this) {
    InvoiceUnit.piece => Icons.shopping_basket,
    InvoiceUnit.set_ => Icons.widgets,
    InvoiceUnit.box => Icons.inbox,
    InvoiceUnit.package => Icons.local_shipping,
    InvoiceUnit.service => Icons.build,
    InvoiceUnit.hour => Icons.access_time,
    InvoiceUnit.day => Icons.today,
    InvoiceUnit.month => Icons.date_range,
    InvoiceUnit.year => Icons.event,
    InvoiceUnit.kg => Icons.fitness_center,
    InvoiceUnit.g => Icons.fitness_center,
    InvoiceUnit.m => Icons.straighten,
    InvoiceUnit.l => Icons.local_drink,
  };

  @override
  Color get color => switch (this) {
    InvoiceUnit.piece => AppColor.blue,
    InvoiceUnit.set_ => AppColor.indigo,
    InvoiceUnit.box => AppColor.orange,
    InvoiceUnit.package => AppColor.teal,
    InvoiceUnit.service => AppColor.purple,
    InvoiceUnit.hour => AppColor.amber,
    InvoiceUnit.day => AppColor.green,
    InvoiceUnit.month => AppColor.blue,
    InvoiceUnit.year => AppColor.indigo,
    InvoiceUnit.kg => AppColor.orange,
    InvoiceUnit.g => AppColor.orange,
    InvoiceUnit.m => AppColor.teal,
    InvoiceUnit.l => AppColor.blue,
  };

  static InvoiceUnit? fromValue(String? value) {
    return _enumFromStringValue(
      InvoiceUnit.values,
      value,
      (item) => item.value,
      caseInsensitive: true,
    );
  }
}
