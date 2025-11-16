import 'package:fcode_pos/enums.dart';
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
    final config = _getTypeConfig(refundType);

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
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _TypeConfig _getTypeConfig(RefundType? type) {
    switch (type) {
      case RefundType.item:
        return _TypeConfig(
          backgroundColor: Colors.purple.shade50,
          textColor: Colors.purple.shade700,
          label: type!.label,
          icon: Icons.inventory_2_outlined,
        );
      case RefundType.full:
        return _TypeConfig(
          backgroundColor: Colors.indigo.shade50,
          textColor: Colors.indigo.shade700,
          label: type!.label,
          icon: Icons.receipt_long_outlined,
        );
      case RefundType.partial:
        return _TypeConfig(
          backgroundColor: Colors.teal.shade50,
          textColor: Colors.teal.shade700,
          label: type!.label,
          icon: Icons.payments_outlined,
        );
      case RefundType.pending:
        return _TypeConfig(
          backgroundColor: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
          label: type!.label,
          icon: Icons.pending_outlined,
        );
      case RefundType.none:
        return _TypeConfig(
          backgroundColor: Colors.grey.shade50,
          textColor: Colors.grey.shade700,
          label: type!.label,
          icon: Icons.block_outlined,
        );
      case null:
        return _TypeConfig(
          backgroundColor: Colors.grey.shade50,
          textColor: Colors.grey.shade700,
          label: this.type,
          icon: Icons.category_outlined,
        );
    }
  }
}

class _TypeConfig {
  final Color backgroundColor;
  final Color textColor;
  final String label;
  final IconData icon;

  _TypeConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
    required this.icon,
  });
}
