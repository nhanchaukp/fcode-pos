import 'package:amazing_icons/bulk.dart';
import 'package:fcode_pos/ui/components/badge/app_badge.dart';
import 'package:fcode_pos/ui/components/badge/badge_bulk_icon.dart';
import 'package:fcode_pos/ui/components/badge/badge_theme.dart';
import 'package:flutter/material.dart';

(Color, BulkIconBuilder, String) eventMeta(String event, ColorScheme cs) {
  return switch (event.toLowerCase()) {
    'created' => (Colors.green, AmazingIconBulk.addCircle, 'Tạo mới'),
    'updated' => (Colors.orange, AmazingIconBulk.edit, 'Cập nhật'),
    'deleted' => (Colors.red, AmazingIconBulk.trash, 'Xóa'),
    'restored' => (Colors.blue, AmazingIconBulk.rotateLeft, 'Khôi phục'),
    _ => (cs.primary, AmazingIconBulk.clock, event),
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
      bulkIcon: icon,
      size: size,
      fontWeight: FontWeight.w700,
    );
  }
}
