import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:flutter/material.dart';

class BuyerTypeBadge extends StatelessWidget {
  const BuyerTypeBadge({
    super.key,
    required this.buyerType,
    this.size = BadgeSize.compact,
    this.fontSize,
    this.padding,
  });

  final String buyerType;
  final BadgeSize size;
  final double? fontSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return EnumBadge(
      value: BuyerType.fromValue(buyerType),
      fallbackLabel: buyerType,
      size: size,
      fontSize: fontSize,
      padding: padding,
    );
  }
}
