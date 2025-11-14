import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/supply_service.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/ui/components/debounced_search_input.dart';
import 'package:fcode_pos/screens/supply/supply_form_screen.dart';

class SupplyDropdown extends StatefulWidget {
  final Supply? selectedSupply;
  final Function(Supply?)? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? Function(Supply?)? validator;
  final String? labelText;

  const SupplyDropdown({
    this.selectedSupply,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.labelText,
    super.key,
  });

  @override
  State<SupplyDropdown> createState() => _SupplyDropdownState();
}

class _SupplyDropdownState extends State<SupplyDropdown> {
  final _supplyService = SupplyService();
  List<Supply> _supplies = [];
  bool _isLoading = false;
  Supply? _selectedSupply;

  @override
  void initState() {
    super.initState();
    _selectedSupply = widget.selectedSupply;
    _loadSupplies();
  }

  @override
  void didUpdateWidget(SupplyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSupply != oldWidget.selectedSupply) {
      setState(() {
        _selectedSupply = widget.selectedSupply;
      });
    }
  }

  Future<void> _loadSupplies() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supplyService.list(perPage: 100);
      final items = response.data?.items ?? [];
      if (!mounted) return;
      setState(() {
        _supplies = items;
        // Nếu có selectedSupply, tìm lại trong danh sách để đảm bảo reference đúng
        if (_selectedSupply != null) {
          _selectedSupply = _supplies.firstWhere(
            (s) => s.id == _selectedSupply!.id,
            orElse: () => _selectedSupply!,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading supplies: $e');
      if (!mounted) return;
      setState(() {
        _supplies = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labelText ?? 'Nhà cung cấp';

    if (_isLoading) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: '$label${widget.isRequired ? ' *' : ''}',
          prefixIcon: const Icon(Icons.local_shipping_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const SizedBox(
            width: 16,
            height: 16,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        enabled: false,
      );
    }

    return TextFormField(
      controller: TextEditingController(text: _selectedSupply?.name ?? ''),
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: '$label${widget.isRequired ? ' *' : ''}',
        prefixIcon: const Icon(Icons.local_shipping_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedSupply != null && widget.enabled)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedSupply = null;
                  });
                  widget.onChanged?.call(null);
                },
              ),
            if (widget.enabled)
              IconButton(
                icon: const Icon(Icons.add_business),
                tooltip: 'Thêm nhà cung cấp',
                onPressed: () async {
                  final created = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SupplyFormScreen(),
                    ),
                  );
                  if (created == true) {
                    // Reload supplies and select the newest one
                    await _loadSupplies();
                    if (_supplies.isNotEmpty) {
                      setState(() {
                        _selectedSupply = _supplies.last;
                      });
                      widget.onChanged?.call(_selectedSupply);
                    }
                  }
                },
              ),
          ],
        ),
      ),
      onTap: widget.enabled
          ? () async {
              final selected = await showModalBottomSheet<Supply>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return _SupplySelectSheet(
                    supplies: _supplies,
                    selected: _selectedSupply,
                  );
                },
              );
              if (selected != null) {
                setState(() {
                  _selectedSupply = selected;
                });
                widget.onChanged?.call(selected);
              }
            }
          : null,
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(_selectedSupply);
        } else if (widget.isRequired && _selectedSupply == null) {
          return 'Vui lòng chọn nhà cung cấp';
        }
        return null;
      },
    );
  }
}

class _SupplySelectSheet extends StatefulWidget {
  final List<Supply> supplies;
  final Supply? selected;
  const _SupplySelectSheet({required this.supplies, this.selected});

  @override
  State<_SupplySelectSheet> createState() => _SupplySelectSheetState();
}

class _SupplySelectSheetState extends State<_SupplySelectSheet> {
  late List<Supply> _filtered;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.supplies;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              DebouncedSearchInput(
                controller: _searchController,
                autofocus: true,
                hintText: 'Tìm kiếm nhà cung cấp...',
                onChanged: (query) {
                  if (!mounted) return;
                  final q = query.toLowerCase();
                  setState(() {
                    _filtered = widget.supplies.where((supply) {
                      return supply.name.toLowerCase().contains(q) ||
                          (supply.content?.toLowerCase().contains(q) ?? false);
                    }).toList();
                  });
                },
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _filtered.isEmpty
                    ? const Center(child: Text('Không có nhà cung cấp phù hợp'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final supply = _filtered[index];
                          return ListTile(
                            title: Text(supply.name),
                            trailing: widget.selected?.id == supply.id
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(supply);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
