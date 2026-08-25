import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/app_dropdown.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    // Combine fetched sources with selectedValue if it's not present in fetched items
    final displayItems = <String>{
      if (_selectedValue != null && _selectedValue!.trim().isNotEmpty)
        _selectedValue!,
      ..._sources,
    }.toList();

    final allItems = <String?>[
      null,
      ...displayItems,
    ];

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return AppDropdown<String?>.search(
      items: allItems,
      initialItem: (displayItems.contains(_selectedValue)) ? _selectedValue : null,
      labelText: widget.isRequired ? '${widget.labelText} *' : widget.labelText,
      hintText: 'Chọn nguồn ngoài',
      searchHintText: 'Tìm nguồn ngoài...',
      prefixIcon: widget.showPrefixIcon ? const Icon(Icons.extension, size: 20) : null,
      headerBuilder: (context, selectedItem, enabled) {
        return Text(
          selectedItem ?? 'Chưa chọn (Không có)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selectedItem == null ? Colors.grey : colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return Row(
          children: [
            Expanded(
              child: Text(
                item ?? 'Chưa chọn (Không có)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: item == null
                      ? Colors.grey
                      : (isSelected ? colorScheme.primary : colorScheme.onSurface),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
          ],
        );
      },
      onChanged: (value) {
        setState(() => _selectedValue = value);
        widget.onChanged?.call(value);
      },
    );
  }
}
