import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityInput extends StatefulWidget {
  final int initialQuantity;
  final Function(int) onQuantityChanged;
  final int minQuantity;
  final int? maxQuantity;
  final String? labelText;
  final String? hintText;

  const QuantityInput({
    required this.initialQuantity,
    required this.onQuantityChanged,
    this.minQuantity = 1,
    this.maxQuantity,
    this.labelText = 'Số lượng',
    this.hintText = 'Nhập số lượng',
    super.key,
  });

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late TextEditingController _controller;
  late int _currentQuantity;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.initialQuantity;
    _controller = TextEditingController(text: _currentQuantity.toString());
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final value = _controller.text;
    if (value.isEmpty) return;

    final quantity = int.tryParse(value);
    if (quantity != null && quantity >= widget.minQuantity) {
      if (widget.maxQuantity == null || quantity <= widget.maxQuantity!) {
        _currentQuantity = quantity;
        widget.onQuantityChanged(quantity);
      }
    }
  }

  void _increment() {
    final newQuantity = _currentQuantity + 1;
    if (widget.maxQuantity == null || newQuantity <= widget.maxQuantity!) {
      setState(() {
        _currentQuantity = newQuantity;
        _controller.text = newQuantity.toString();
      });
      widget.onQuantityChanged(newQuantity);
    }
  }

  void _decrement() {
    if (_currentQuantity > widget.minQuantity) {
      final newQuantity = _currentQuantity - 1;
      setState(() {
        _currentQuantity = newQuantity;
        _controller.text = newQuantity.toString();
      });
      widget.onQuantityChanged(newQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        prefixIcon: IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            color: _currentQuantity <= widget.minQuantity
                ? Colors.grey.shade400
                : Theme.of(context).colorScheme.primary,
          ),
          onPressed: _currentQuantity <= widget.minQuantity ? null : _decrement,
          tooltip: 'Giảm',
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: widget.maxQuantity != null &&
                    _currentQuantity >= widget.maxQuantity!
                ? Colors.grey.shade400
                : Theme.of(context).colorScheme.primary,
          ),
          onPressed: widget.maxQuantity != null &&
                  _currentQuantity >= widget.maxQuantity!
              ? null
              : _increment,
          tooltip: 'Tăng',
        ),
      ),
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập ${widget.labelText?.toLowerCase() ?? 'số lượng'}';
        }
        final quantity = int.tryParse(value);
        if (quantity == null) {
          return 'Giá trị không hợp lệ';
        }
        if (quantity < widget.minQuantity) {
          return 'Số lượng phải >= ${widget.minQuantity}';
        }
        if (widget.maxQuantity != null && quantity > widget.maxQuantity!) {
          return 'Số lượng phải <= ${widget.maxQuantity}';
        }
        return null;
      },
    );
  }
}
