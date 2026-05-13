import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/enum_badge.dart';
import 'package:flutter/material.dart';

class RefundTypeBadge extends StatelessWidget {
  final String type;
  final double fontSize;
  final EdgeInsets padding;

  const RefundTypeBadge({
    super.key,
    required this.type,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final refundType = RefundType.fromValue(type);

    return EnumBadge(
      value: refundType,
      fallbackLabel: type,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
