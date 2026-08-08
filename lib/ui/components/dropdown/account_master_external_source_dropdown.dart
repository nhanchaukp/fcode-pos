import 'package:fcode_pos/services/account_master_service.dart';
import 'package:flutter/material.dart';

class AccountMasterExternalSourceDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?>? onChanged;
  final String labelText;
  final bool isRequired;
  final bool showPrefixIcon;

  const AccountMasterExternalSourceDropdown({
    super.key,
    this.initialValue,
    this.onChanged,
    this.labelText = 'Nguồn ngoài',
    this.isRequired = false,
    this.showPrefixIcon = true,
  });

  @override
  State<AccountMasterExternalSourceDropdown> createState() =>
      _AccountMasterExternalSourceDropdownState();
}

class _AccountMasterExternalSourceDropdownState
    extends State<AccountMasterExternalSourceDropdown> {
  final _service = AccountMasterService();
  List<String> _sources = [];
  bool _isLoading = false;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _loadSources();
  }

  @override
  void didUpdateWidget(AccountMasterExternalSourceDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedValue = widget.initialValue;
      });
    }
  }

  Future<void> _loadSources() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await _service.getExternalSources();
      final items = response.data ?? [];
      if (!mounted) return;

      setState(() {
        _sources = items;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine fetched sources with selectedValue if it's not present in fetched items
    final displayItems = <String>{
      if (_selectedValue != null && _selectedValue!.trim().isNotEmpty)
        _selectedValue!,
      ..._sources,
    }.toList();

    return DropdownButtonFormField<String>(
      initialValue: (displayItems.contains(_selectedValue)) ? _selectedValue : null,
      decoration: InputDecoration(
        labelText: widget.isRequired ? '${widget.labelText} *' : widget.labelText,
        hintText: 'Chọn nguồn ngoài',
        border: const OutlineInputBorder(),
        prefixIcon: widget.showPrefixIcon ? const Icon(Icons.extension) : null,
        suffixIcon: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (_selectedValue != null && _selectedValue!.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Xóa chọn',
                    onPressed: () {
                      setState(() => _selectedValue = null);
                      widget.onChanged?.call(null);
                    },
                  )
                : null,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Chưa chọn (Không có)',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ...displayItems.map((source) {
          return DropdownMenuItem<String>(
            value: source,
            child: Text(source),
          );
        }),
      ],
      onChanged: (value) {
        setState(() => _selectedValue = value);
        widget.onChanged?.call(value);
      },
    );
  }
}
