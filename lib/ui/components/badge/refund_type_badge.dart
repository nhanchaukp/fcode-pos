import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:flutter/material.dart';

class RefundTypeBadge extends StatelessWidget {
  const RefundTypeBadge({
    super.key,
    required this.type,
    this.size = BadgeSize.compact,
    this.fontSize,
    this.padding,
  });

  final String type;
  final BadgeSize size;
  final double? fontSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return EnumBadge(
      value: RefundType.fromValue(type),
      fallbackLabel: type,
      size: size,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
