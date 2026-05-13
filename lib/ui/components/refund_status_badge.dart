import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/enum_badge.dart';
import 'package:flutter/material.dart';

class RefundStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const RefundStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final refundStatus = RefundStatus.fromValue(status);

    return EnumBadge(
      value: refundStatus,
      fallbackLabel: status,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
