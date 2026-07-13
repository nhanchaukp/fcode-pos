import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:flutter/material.dart';

class RefundReasonBadge extends StatelessWidget {
  const RefundReasonBadge({
    super.key,
    required this.reason,
    this.size = BadgeSize.compact,
    this.fontSize,
    this.padding,
  });

  final String reason;
  final BadgeSize size;
  final double? fontSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return EnumBadge(
      value: RefundReason.fromValue(reason),
      fallbackLabel: reason,
      size: size,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
