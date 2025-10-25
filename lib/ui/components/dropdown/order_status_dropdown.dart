import 'package:fcode_pos/enums.dart' as enums;
import 'package:flutter/material.dart';

class OrderStatusDropdown extends StatelessWidget {
  final enums.OrderStatus? initialValue;
  final ValueChanged<enums.OrderStatus?> onChanged;
  final String? Function(enums.OrderStatus?)? validator;
  final String? labelText;
  final String? hintText;
  final bool showPrefixIcon;
  final bool required;
  final bool includeAllOption;

  const OrderStatusDropdown({
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.labelText,
    this.hintText,
    this.showPrefixIcon = false,
    this.required = true,
    this.includeAllOption = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<enums.OrderStatus>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText ?? 'Trạng thái',
        hintText: hintText,
        prefixIcon: showPrefixIcon ? const Icon(Icons.info_outline) : null,
        border: const OutlineInputBorder(),
      ),
      items: enums.OrderStatus.values
          .where(
              (status) => includeAllOption || status != enums.OrderStatus.all)
          .map((status) => DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status.label),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator ??
          (required
              ? (value) {
                  if (value == null) {
                    return 'Vui lòng chọn trạng thái';
                  }
                  return null;
                }
              : null),
    );
  }
}
