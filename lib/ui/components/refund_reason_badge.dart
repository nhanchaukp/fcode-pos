import 'package:fcode_pos/enums.dart';
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
    final config = _getReasonConfig(refundReason);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: fontSize + 2, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _ReasonConfig _getReasonConfig(RefundReason? reason) {
    switch (reason) {
      case RefundReason.customerRequest:
        return _ReasonConfig(
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade700,
          label: reason!.label,
          icon: Icons.person_outline,
        );
      case RefundReason.productDefect:
        return _ReasonConfig(
          backgroundColor: Colors.red.shade50,
          textColor: Colors.red.shade700,
          label: reason!.label,
          icon: Icons.warning_amber_outlined,
        );
      case RefundReason.deliveryIssue:
        return _ReasonConfig(
          backgroundColor: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
          label: reason!.label,
          icon: Icons.local_shipping_outlined,
        );
      case RefundReason.accountExpired:
        return _ReasonConfig(
          backgroundColor: Colors.amber.shade50,
          textColor: Colors.amber.shade900,
          label: reason!.label,
          icon: Icons.schedule_outlined,
        );
      case RefundReason.serviceIssue:
        return _ReasonConfig(
          backgroundColor: Colors.pink.shade50,
          textColor: Colors.pink.shade700,
          label: reason!.label,
          icon: Icons.support_agent_outlined,
        );
      case RefundReason.other:
        return _ReasonConfig(
          backgroundColor: Colors.grey.shade50,
          textColor: Colors.grey.shade700,
          label: reason!.label,
          icon: Icons.help_outline,
        );
      case null:
        return _ReasonConfig(
          backgroundColor: Colors.grey.shade50,
          textColor: Colors.grey.shade700,
          label: this.reason,
          icon: Icons.comment_outlined,
        );
    }
  }
}

class _ReasonConfig {
  final Color backgroundColor;
  final Color textColor;
  final String label;
  final IconData icon;

  _ReasonConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
    required this.icon,
  });
}
