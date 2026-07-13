import 'package:fcode_pos/ui/components/badge/app_badge.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:flutter/material.dart';

(Color, IconData, String) eventMeta(String event, ColorScheme cs) {
  return switch (event.toLowerCase()) {
    'created' => (Colors.green, Icons.add_circle_outline, 'Tạo mới'),
    'updated' => (Colors.orange, Icons.edit_outlined, 'Cập nhật'),
    'deleted' => (Colors.red, Icons.delete_outline, 'Xóa'),
    'restored' => (Colors.blue, Icons.restore, 'Khôi phục'),
    _ => (cs.primary, Icons.history, event),
  };
}

/// Badge sự kiện audit / lịch sử thay đổi.
class AuditEventBadge extends StatelessWidget {
  const AuditEventBadge({
    super.key,
    required this.event,
    this.size = BadgeSize.compact,
  });

  final String event;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (color, icon, label) = eventMeta(event, cs);

    return AppBadge(
      label: label,
      color: color,
      icon: icon,
      size: size,
      fontWeight: FontWeight.w700,
    );
  }
}
