import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';

/// A TextFormField specifically designed for money input
/// Automatically formats the input as currency and returns numeric value
class MoneyFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(int value)? onChanged;
  final int? initialValue;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String suffixText;
  final int maxLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final bool isLoading;

  const MoneyFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.initialValue,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText = 'đ',
    this.maxLines = 1,
    this.autofocus = false,
    this.focusNode,
    this.decoration,
    this.isLoading = false,
  });

  @override
  State<MoneyFormField> createState() => _MoneyFormFieldState();
}

class _MoneyFormFieldState extends State<MoneyFormField> {
  late TextEditingController _controller;
  late CurrencyTextInputFormatter _formatter;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();

    _formatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: '',
    );

    // Use provided controller or create a new one
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isInternalController = true;
    }

    // Set initial value if provided
    if (widget.initialValue != null && _controller.text.isEmpty) {
      _controller.text = _formatter.formatString(
        widget.initialValue.toString(),
      );
    }

    // Listen to controller changes to auto-format values set externally
    _controller.addListener(_handleControllerChange);
  }

  bool _isFormatting = false;

  void _handleControllerChange() {
    // Prevent infinite loop
    if (_isFormatting) return;

    // Check if controller is still valid
    if (!mounted) return;

    final text = _controller.text;

    // Skip if already formatted or empty
    if (text.isEmpty || text.contains('.')) return;

    // Check if this is an unformatted number (no dots)
    final number = int.tryParse(text);
    if (number != null && number > 999) {
      _isFormatting = true;
      final formatted = _formatter.formatString(number.toString());

      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );

      _isFormatting = false;
    }
  }

  @override
  void dispose() {
    // Remove listener before disposing
    _controller.removeListener(_handleControllerChange);

    // Only dispose if we created the controller
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Get the numeric value from the formatted text
  int get value {
    final text = _controller.text.replaceAll('.', '').trim();
    return int.tryParse(text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      decoration:
          widget.decoration ??
          InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            suffixText: widget.isLoading ? null : widget.suffixText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.suffixIcon,
          ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_formatter],
      onTap: () {
        // Clear "0" when user taps on the field
        if (_controller.text == '0') {
          _controller.clear();
        }
      },
      onChanged: (value) {
        if (widget.onChanged != null) {
          final numericValue = this.value;
          widget.onChanged!(numericValue);
        }
      },
      validator:
          widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập giá trị';
            }
            final price = double.tryParse(value.replaceAll('.', ''));
            if (price == null || price < 0) {
              return 'Giá trị không hợp lệ';
            }
            return null;
          },
    );
  }
}

/// Extension to easily get numeric value from MoneyFormField controller
extension MoneyFormFieldControllerExtension on TextEditingController {
  /// Get the numeric value from a money formatted text
  int get moneyValue {
    final text = this.text.replaceAll('.', '').trim();
    return int.tryParse(text) ?? 0;
  }
}
