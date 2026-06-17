import 'package:fcode_pos/enums.dart' as enums;
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
    return DropdownButtonFormField<enums.FinancialTransactionStatus>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Trạng thái',
        prefixIcon: const Icon(Icons.flag_outlined),
        border: const OutlineInputBorder(),
      ),
      items: enums.FinancialTransactionStatus.values
          .map(
            (status) => DropdownMenuItem(
              value: status,
              child: Text(status.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (value == null) return 'Vui lòng chọn trạng thái';
            return null;
          },
    );
  }
}