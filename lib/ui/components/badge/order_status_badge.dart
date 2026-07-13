import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.compact,
    this.fontSize,
    this.padding,
  });

  final String status;
  final BadgeSize size;
  final double? fontSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return EnumBadge(
      value: enums.OrderStatus.fromValue(status),
      fallbackLabel: status,
      size: size,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
