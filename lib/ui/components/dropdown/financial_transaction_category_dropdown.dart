import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/ui/components/app_dropdown.dart';
import 'package:flutter/material.dart';

class FinancialTransactionCategoryDropdown extends StatelessWidget {
  final enums.FinancialTransactionCategory? initialValue;
  final ValueChanged<enums.FinancialTransactionCategory?> onChanged;
  final String? Function(enums.FinancialTransactionCategory?)? validator;
  final String? labelText;
  final String? hintText;
  final bool showPrefixIcon;
  final bool required;

  const FinancialTransactionCategoryDropdown({
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

    return AppDropdown<enums.FinancialTransactionCategory>(
      initialItem: initialValue,
      hintText: hintText ?? labelText ?? 'Nhóm giao dịch',
      prefixIcon: showPrefixIcon
          ? const Icon(Icons.category_outlined, size: 20)
          : null,
      items: enums.FinancialTransactionCategory.values,
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
                    return 'Vui lòng chọn nhóm giao dịch';
                  }
                  return null;
                }
              : null),
    );
  }
}
