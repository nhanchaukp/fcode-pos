import 'package:fcode_pos/ui/theme/tokens.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ô ghi chú nhiều dòng kèm thanh action phía dưới
/// (copy, cắt, dán, chọn tất cả, chọn dòng, xóa) theo kiểu `markdown_editor_plus`.
class NoteFormField extends StatefulWidget {
  const NoteFormField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText = 'Ghi chú',
    this.hintText,
    this.minLines = 2,
    this.maxLines = 6,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.showToolbar = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool showToolbar;

  @override
  State<NoteFormField> createState() => _NoteFormFieldState();
}

class _NoteFormFieldState extends State<NoteFormField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focused = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused != _focused) {
      setState(() => _focused = focused);
    }
  }

  TextSelection get _selection {
    final selection = widget.controller.selection;
    if (selection.isValid) return selection;
    final end = widget.controller.text.length;
    return TextSelection.collapsed(offset: end);
  }

  String get _selectedOrAll {
    final selection = widget.controller.selection;
    final text = widget.controller.text;
    return switch (selection) {
      TextSelection(isValid: true, isCollapsed: false) => selection.textInside(
        text,
      ),
      _ => text,
    };
  }

  void _ensureFocus() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _replaceRange(int start, int end, String value) {
    final text = widget.controller.text;
    widget.controller.value = TextEditingValue(
      text: text.replaceRange(start, end, value),
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  Future<void> _copy() async {
    final text = _selectedOrAll;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    Toastr.success('Đã sao chép');
  }

  Future<void> _cut() async {
    final text = _selectedOrAll;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    final selection = _selection;
    if (selection.isCollapsed) {
      widget.controller.clear();
    } else {
      _replaceRange(selection.start, selection.end, '');
    }
    Toastr.success('Đã cắt');
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) {
      Toastr.info('Clipboard trống');
      return;
    }
    _ensureFocus();
    final selection = _selection;
    _replaceRange(selection.start, selection.end, pasted);
  }

  void _selectAll() {
    _ensureFocus();
    final text = widget.controller.text;
    if (text.isEmpty) return;
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  void _selectCurrentLine() {
    _ensureFocus();
    final controller = widget.controller;
    final text = controller.text;
    if (text.isEmpty) return;

    final selection = _selection;
    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final lineEndIndex = text.indexOf('\n', selection.end);
    final lineEnd = lineEndIndex == -1 ? text.length : lineEndIndex;

    controller.selection = TextSelection(
      baseOffset: lineStart,
      extentOffset: lineEnd,
    );
  }

  void _clear() {
    if (widget.controller.text.isEmpty) return;
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.only(
          bottomLeft: AppRadius.s.bottomLeft,
          bottomRight: AppRadius.s.bottomRight,
          topLeft: AppRadius.m.topLeft,
          topRight: AppRadius.m.topRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            validator: widget.validator,
            onChanged: widget.onChanged,
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              alignLabelWithHint: true,
              filled: true,
              contentPadding: const EdgeInsets.all(8),
            ),
          ),
          if (widget.showToolbar && widget.enabled) _buildToolbar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final hasText = widget.controller.text.isNotEmpty;
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          descendantsAreFocusable: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.only(
                bottomLeft: AppRadius.s.bottomLeft,
                bottomRight: AppRadius.s.bottomRight,
              ),
            ),
            child: SizedBox(
              height: 40,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    _ToolbarIconButton(
                      icon: Icons.copy_outlined,
                      tooltip: 'Sao chép',
                      onPressed: hasText ? _copy : null,
                    ),
                    _ToolbarIconButton(
                      icon: Icons.content_cut,
                      tooltip: 'Cắt',
                      onPressed: hasText ? _cut : null,
                    ),
                    _ToolbarIconButton(
                      icon: Icons.paste_outlined,
                      tooltip: 'Dán',
                      onPressed: _paste,
                    ),
                    _ToolbarIconButton(
                      icon: Icons.select_all,
                      tooltip: 'Chọn tất cả',
                      onPressed: hasText ? _selectAll : null,
                    ),
                    _ToolbarIconButton(
                      icon: Icons.wrap_text,
                      tooltip: 'Chọn dòng hiện tại',
                      onPressed: hasText ? _selectCurrentLine : null,
                    ),
                    _ToolbarIconButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Xóa nội dung',
                      onPressed: hasText ? _clear : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}
