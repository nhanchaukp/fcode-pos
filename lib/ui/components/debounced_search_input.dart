import 'dart:async';
import 'package:flutter/material.dart';

class DebouncedSearchInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? hintText;
  final Duration debounceDuration;
  final TextEditingController? controller;
  final bool autofocus;

  const DebouncedSearchInput({
    super.key,
    required this.onChanged,
    this.hintText,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.controller,
    this.autofocus = false,
  });

  @override
  State<DebouncedSearchInput> createState() => _DebouncedSearchInputState();
}

class _DebouncedSearchInputState extends State<DebouncedSearchInput> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      if (!mounted) return;
      widget.onChanged(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Tìm kiếm...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
    );
  }
}
