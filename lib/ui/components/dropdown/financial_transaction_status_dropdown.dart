import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/ui/components/app_dropdown.dart';
import 'package:flutter/material.dart';

class FinancialTransactionStatusDropdown extends StatelessWidget {
  const FinancialTransactionStatusDropdown({
    required this.initialValue,
    required this.onChanged,
    this.validator,
    this.labelText,
    super.key,
  });

  final enums.FinancialTransactionStatus? initialValue;
  final ValueChanged<enums.FinancialTransactionStatus?> onChanged;
  final String? Function(enums.FinancialTransactionStatus?)? validator;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDropdown<enums.FinancialTransactionStatus>(
      initialItem: initialValue,
      hintText: labelText ?? 'Trạng thái',
      prefixIcon: const Icon(Icons.flag_outlined, size: 20),
      items: enums.FinancialTransactionStatus.values,
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
          (value) {
            if (value == null) return 'Vui lòng chọn trạng thái';
            return null;
          },
    );
  }
}