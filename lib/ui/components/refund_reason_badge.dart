import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/enum_badge.dart';
import 'package:flutter/material.dart';

class RefundReasonBadge extends StatelessWidget {
  final String reason;
  final double fontSize;
  final EdgeInsets padding;

  const RefundReasonBadge({
    super.key,
    required this.reason,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final refundReason = RefundReason.fromValue(reason);

    return EnumBadge(
      value: refundReason,
      fallbackLabel: reason,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
