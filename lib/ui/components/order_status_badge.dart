import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/ui/components/enum_badge.dart';
import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final orderStatus = enums.OrderStatus.fromValue(status);

    return EnumBadge(
      value: orderStatus,
      fallbackLabel: status,
      fontSize: fontSize,
      padding: padding,
      showIcon: true,
    );
  }
}
