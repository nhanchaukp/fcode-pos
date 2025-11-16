import 'package:fcode_pos/enums.dart' as enums;
import 'package:flutter/material.dart';

class RefundReasonDropdown extends StatelessWidget {
  final enums.RefundReason? initialValue;
  final ValueChanged<enums.RefundReason?> onChanged;
  final String? Function(enums.RefundReason?)? validator;
  final String? labelText;
  final String? hintText;
  final bool showPrefixIcon;
  final bool required;

  const RefundReasonDropdown({
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
    return DropdownButtonFormField<enums.RefundReason>(
      value: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Lý do hoàn tiền',
        hintText: hintText,
        prefixIcon: showPrefixIcon ? const Icon(Icons.help_outline) : null,
        border: const OutlineInputBorder(),
      ),
      items: enums.RefundReason.values
          .map(
            (reason) =>
                DropdownMenuItem(value: reason, child: Text(reason.label)),
          )
          .toList(),
      onChanged: onChanged,
      validator:
          validator ??
          (required
              ? (value) {
                  if (value == null) {
                    return 'Vui lòng chọn lý do hoàn tiền';
                  }
                  return null;
                }
              : null),
    );
  }
}
