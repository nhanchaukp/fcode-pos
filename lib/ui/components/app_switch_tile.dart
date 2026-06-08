import 'package:flutter/material.dart';

/// Switch tile nhất quán với style toàn app (Card elevation 0 + SwitchListTile compact).
///
/// Ví dụ sử dụng:
/// ```dart
/// AppSwitchTile(
///   icon: Icons.toggle_on_outlined,
///   title: 'Kích hoạt',
///   subtitle: 'Slot đang hoạt động',
///   value: _isActive,
///   onChanged: (v) => setState(() => _isActive = v),
/// )
/// ```
class AppSwitchTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitchTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        secondary: icon != null
            ? Icon(icon, color: cs.primary)
            : null,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
