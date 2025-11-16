import 'package:fcode_pos/enums.dart' as enums;
import 'package:flutter/material.dart';

class FinancialTransactionTypeDropdown extends StatelessWidget {
  final enums.FinancialTransactionType? initialValue;
  final ValueChanged<enums.FinancialTransactionType?> onChanged;
  final String? Function(enums.FinancialTransactionType?)? validator;
  final String? labelText;
  final String? hintText;
  final bool showPrefixIcon;
  final bool required;

  const FinancialTransactionTypeDropdown({
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
    return DropdownButtonFormField<enums.FinancialTransactionType>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Loại giao dịch',
        hintText: hintText,
        prefixIcon: showPrefixIcon
            ? const Icon(Icons.swap_horiz_rounded)
            : null,
        border: const OutlineInputBorder(),
      ),
      items: enums.FinancialTransactionType.values
          .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
          .toList(),
      onChanged: onChanged,
      validator:
          validator ??
          (required
              ? (value) {
                  if (value == null) {
                    return 'Vui lòng chọn loại giao dịch';
                  }
                  return null;
                }
              : null),
    );
  }
}
