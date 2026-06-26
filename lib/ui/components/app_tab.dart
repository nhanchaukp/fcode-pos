import 'package:flutter/material.dart';

/// Tab với icon và text hiển thị ngang nhau.
///
/// Dùng thay cho [Tab] mặc định (icon trên text) khi muốn layout compact hơn.
///
/// Khi có nhiều tab và nội dung bị tràn, hãy dùng:
/// - `TabBar(isScrollable: true)` để cho phép vuốt ngang (scroll tabs)
/// - (tùy chọn) `tabAlignment: TabAlignment.start` để các tab bắt đầu từ bên trái
///
/// ```dart
/// TabBar(
///   isScrollable: true,
///   tabAlignment: TabAlignment.start,
///   tabs: [
///     AppTab(icon: Icons.link, text: 'Access Links'),
///     AppTab(icon: Icons.history, text: 'Audit Log'),
///     AppTab(icon: Icons.settings, text: 'Cài đặt'),
///   ],
/// )
/// ```
class AppTab extends StatelessWidget {
  final IconData icon;
  final String text;
  final double iconSize;
  final double spacing;

  const AppTab({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 16,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          SizedBox(width: spacing),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
