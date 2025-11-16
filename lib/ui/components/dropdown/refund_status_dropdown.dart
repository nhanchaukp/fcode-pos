import 'package:fcode_pos/enums.dart' as enums;
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
    return DropdownButtonFormField<enums.RefundStatus>(
      value: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Trạng thái hoàn tiền',
        hintText: hintText,
        prefixIcon: showPrefixIcon ? const Icon(Icons.info_outline) : null,
        border: const OutlineInputBorder(),
      ),
      items: enums.RefundStatus.values
          .map(
            (status) =>
                DropdownMenuItem(value: status, child: Text(status.label)),
          )
          .toList(),
      onChanged: onChanged,
      validator:
          validator ??
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
