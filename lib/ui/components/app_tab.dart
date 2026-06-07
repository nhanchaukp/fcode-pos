import 'package:flutter/material.dart';

/// Tab với icon và text hiển thị ngang nhau.
///
/// Dùng thay cho [Tab] mặc định (icon trên text) khi muốn layout compact hơn.
///
/// ```dart
/// TabBar(
///   tabs: [
///     AppTab(icon: Icons.link, text: 'Access Links'),
///     AppTab(icon: Icons.history, text: 'Audit Log'),
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
          Text(text),
        ],
      ),
    );
  }
}
