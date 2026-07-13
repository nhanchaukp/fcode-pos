import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:flutter/material.dart';

class RefundStatusBadge extends StatelessWidget {
  const RefundStatusBadge({
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
      value: RefundStatus.fromValue(status),
      fallbackLabel: status,
      size: size,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
