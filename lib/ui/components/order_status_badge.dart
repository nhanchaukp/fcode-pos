import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/enums.dart' as enums;

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final orderStatus = enums.OrderStatus.fromString(status);
    final color = _getStatusColor(orderStatus);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.applyOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(orderStatus?.label.toString() ?? '',
              style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(enums.OrderStatus? status) {
    return status?.color ?? Colors.grey;
  }
}
