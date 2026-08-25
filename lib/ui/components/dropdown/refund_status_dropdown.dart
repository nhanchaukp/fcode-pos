import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/ui/components/app_dropdown.dart';
import 'package:flutter/material.dart';

class RefundStatusDropdown extends StatelessWidget {
  final enums.RefundStatus? initialValue;
  final ValueChanged<enums.RefundStatus?> onChanged;
  final String? Function(enums.RefundStatus?)? validator;
  final String? labelText;
  final String? hintText;
  final bool showPrefixIcon;
  final bool required;

  const RefundStatusDropdown({
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

    return AppDropdown<enums.RefundStatus>(
      initialItem: initialValue,
      hintText: hintText ?? labelText ?? 'Trạng thái hoàn tiền',
      prefixIcon: showPrefixIcon ? const Icon(Icons.info_outline, size: 20) : null,
      items: enums.RefundStatus.values,
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
                    return 'Vui lòng chọn trạng thái hoàn tiền';
                  }
                  return null;
                }
              : null),
    );
  }
}
