import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/ui/components/app_dropdown.dart';
import 'package:flutter/material.dart';

class RefundTypeDropdown extends StatelessWidget {
  final enums.RefundType? initialValue;
  final ValueChanged<enums.RefundType?> onChanged;
  final String? Function(enums.RefundType?)? validator;
  final String? labelText;
  final String? hintText;
  final bool showPrefixIcon;
  final bool required;

  const RefundTypeDropdown({
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.labelText,
    this.hintText,
    this.showPrefixIcon = false,
    this.required = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDropdown<enums.RefundType>(
      initialItem: initialValue,
      hintText: hintText ?? labelText ?? 'Loại hoàn tiền',
      prefixIcon: showPrefixIcon
          ? const Icon(Icons.settings_backup_restore, size: 20)
          : null,
      items: enums.RefundType.values,
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          selectedItem.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
          ],
        );
      },
      onChanged: onChanged,
      validator: validator ??
          (required
              ? (value) {
                  if (value == null) {
                    return 'Vui lòng chọn loại hoàn tiền';
                  }
                  return null;
                }
              : null),
    );
  }
}
