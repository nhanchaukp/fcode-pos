import 'package:fcode_pos/enums.dart' as enums;
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
    return DropdownButtonFormField<enums.RefundType>(
      value: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Loại hoàn tiền',
        hintText: hintText,
        prefixIcon: showPrefixIcon
            ? const Icon(Icons.settings_backup_restore)
            : null,
        border: const OutlineInputBorder(),
      ),
      items: enums.RefundType.values
          .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
          .toList(),
      onChanged: onChanged,
      validator:
          validator ??
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
