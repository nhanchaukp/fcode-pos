import 'package:fcode_pos/enums.dart' as enums;
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
    return DropdownButtonFormField<enums.FinancialTransactionCategory>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Nhóm giao dịch',
        hintText: hintText,
        prefixIcon: showPrefixIcon ? const Icon(Icons.category_outlined) : null,
        border: const OutlineInputBorder(),
      ),
      items: enums.FinancialTransactionCategory.values
          .map(
            (category) =>
                DropdownMenuItem(value: category, child: Text(category.label)),
          )
          .toList(),
      onChanged: onChanged,
      validator:
          validator ??
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
