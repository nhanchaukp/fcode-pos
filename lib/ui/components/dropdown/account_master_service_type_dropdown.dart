import 'package:fcode_pos/enums.dart' as enums;
import 'package:flutter/material.dart';

class AccountMasterServiceTypeDropdown extends StatelessWidget {
  final enums.AccountMasterServiceType? initialValue;
  final ValueChanged<enums.AccountMasterServiceType?> onChanged;
  final String? Function(enums.AccountMasterServiceType?)? validator;
  final String? labelText;
  final String? hintText;
  final bool showPrefixIcon;
  final bool required;

  const AccountMasterServiceTypeDropdown({
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
    return DropdownButtonFormField<enums.AccountMasterServiceType>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Loại dịch vụ',
        hintText: hintText,
        prefixIcon: showPrefixIcon ? const Icon(Icons.category) : null,
        border: const OutlineInputBorder(),
      ),
      items: enums.AccountMasterServiceType.values
          .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
          .toList(),
      onChanged: onChanged,
      validator:
          validator ??
          (required
              ? (value) {
                  if (value == null) {
                    return 'Vui lòng chọn loại dịch vụ';
                  }
                  return null;
                }
              : null),
    );
  }
}
