import 'package:fcode_pos/enums.dart';
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
    final config = _getStatusConfig(refundStatus);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: config.textColor,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(RefundStatus? status) {
    switch (status) {
      case RefundStatus.pending:
        return _StatusConfig(
          backgroundColor: Colors.orange.shade100,
          textColor: Colors.orange.shade900,
          label: status!.label,
        );
      case RefundStatus.completed:
        return _StatusConfig(
          backgroundColor: Colors.green.shade100,
          textColor: Colors.green.shade900,
          label: status!.label,
        );
      case RefundStatus.rejected:
        return _StatusConfig(
          backgroundColor: Colors.red.shade100,
          textColor: Colors.red.shade900,
          label: status!.label,
        );
      case RefundStatus.approved:
        return _StatusConfig(
          backgroundColor: Colors.blue.shade100,
          textColor: Colors.blue.shade900,
          label: status!.label,
        );
      case null:
        return _StatusConfig(
          backgroundColor: Colors.grey.shade100,
          textColor: Colors.grey.shade900,
          label: this.status,
        );
    }
  }
}

class _StatusConfig {
  final Color backgroundColor;
  final Color textColor;
  final String label;

  _StatusConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
  });
}
