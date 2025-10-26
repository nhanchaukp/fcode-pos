import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityInput extends StatelessWidget {
  final TextEditingController controller;
  final int minQuantity;
  final int? maxQuantity;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;

  const QuantityInput({
    super.key,
    required this.controller,
    this.minQuantity = 1,
    this.maxQuantity,
    this.labelText = 'Số lượng',
    this.hintText = 'Nhập số lượng',
    this.validator,
    this.onSaved,
    this.onChanged,
    this.decoration,
  });

  void _increment(BuildContext context) {
    final value = int.tryParse(controller.text) ?? minQuantity;
    final newValue = maxQuantity != null && value >= maxQuantity!
        ? value
        : value + 1;
    if (maxQuantity == null || newValue <= maxQuantity!) {
      controller.text = newValue.toString();
      onChanged?.call(controller.text);
    }
  }

  void _decrement(BuildContext context) {
    final value = int.tryParse(controller.text) ?? minQuantity;
    final newValue = value > minQuantity ? value - 1 : value;
    if (newValue >= minQuantity) {
      controller.text = newValue.toString();
      onChanged?.call(controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = int.tryParse(controller.text) ?? minQuantity;
    final InputDecoration effectiveDecoration =
        (decoration ?? const InputDecoration()).copyWith(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          prefixIcon: IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              color: value <= minQuantity
                  ? Colors.grey.shade400
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: value <= minQuantity ? null : () => _decrement(context),
            tooltip: 'Giảm',
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: maxQuantity != null && value >= maxQuantity!
                  ? Colors.grey.shade400
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: maxQuantity != null && value >= maxQuantity!
                ? null
                : () => _increment(context),
            tooltip: 'Tăng',
          ),
        );
    return TextFormField(
      controller: controller,
      decoration: effectiveDecoration,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập ${labelText?.toLowerCase() ?? 'số lượng'}';
            }
            final quantity = int.tryParse(value);
            if (quantity == null) {
              return 'Giá trị không hợp lệ';
            }
            if (quantity < minQuantity) {
              return 'Số lượng phải >= $minQuantity';
            }
            if (maxQuantity != null && quantity > maxQuantity!) {
              return 'Số lượng phải <= $maxQuantity';
            }
            return null;
          },
      onSaved: onSaved,
      onChanged: onChanged,
    );
  }
}
