import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/supply_service.dart';
import 'package:flutter/material.dart';

class SupplyDropdown extends StatefulWidget {
  final Supply? selectedSupply;
  final Function(Supply) onSupplySelected;
  final VoidCallback onSupplyCleared;

  const SupplyDropdown({
    this.selectedSupply,
    required this.onSupplySelected,
    required this.onSupplyCleared,
    super.key,
  });

  @override
  State<SupplyDropdown> createState() => _SupplyDropdownState();
}

class _SupplyDropdownState extends State<SupplyDropdown> {
  late TextEditingController _searchController;
  final _supplyService = SupplyService();
  List<Supply> _allSupplies = [];
  List<Supply> _filteredSupplies = [];
  bool _isLoading = false;
  Supply? _currentSelectedSupply;

  @override
  void initState() {
    super.initState();
    _currentSelectedSupply = widget.selectedSupply;
    _searchController =
        TextEditingController(text: widget.selectedSupply?.name ?? '');
    _searchController.addListener(_onSearchChanged);
    _loadSupplies();
  }

  @override
  void didUpdateWidget(SupplyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update when selectedSupply changes from parent
    if (widget.selectedSupply != oldWidget.selectedSupply) {
      setState(() {
        _currentSelectedSupply = widget.selectedSupply;
        _searchController.text = widget.selectedSupply?.name ?? '';
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplies() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final supplies = await _supplyService.list();
      if (!mounted) return;
      setState(() {
        _allSupplies = supplies;
        _filteredSupplies = supplies;
      });
    } catch (e) {
      debugPrint('Error loading supplies: $e');
      if (!mounted) return;
      setState(() {
        _allSupplies = [];
        _filteredSupplies = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredSupplies = _allSupplies);
      return;
    }

    setState(() {
      _filteredSupplies = _allSupplies.where((supply) {
        return supply.name.toLowerCase().contains(query) ||
            (supply.content?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<Supply>(
      controller: _searchController,
      enableSearch: true,
      requestFocusOnTap: true,
      onSelected: (Supply? supply) {
        if (supply != null) {
          widget.onSupplySelected(supply);
          setState(() {
            _currentSelectedSupply = supply;
            _searchController.text = supply.name;
          });
        }
      },
      expandedInsets: EdgeInsets.zero,
      menuHeight: 300,
      dropdownMenuEntries: _buildDropdownEntries(),
      hintText: widget.selectedSupply?.name ?? 'Chọn nhà cung cấp',
      label: const Text(
        'Nhà cung cấp',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      leadingIcon: const Icon(Icons.business_outlined),
      trailingIcon: _currentSelectedSupply != null
          ? GestureDetector(
              onTap: () {
                _searchController.clear();
                widget.onSupplyCleared();
                setState(() {
                  _currentSelectedSupply = null;
                  _filteredSupplies = _allSupplies;
                });
              },
              child: const Icon(Icons.close),
            )
          : null,
    );
  }

  List<DropdownMenuEntry<Supply>> _buildDropdownEntries() {
    if (_isLoading) {
      return [
        DropdownMenuEntry<Supply>(
          value: Supply(
            id: 0,
            name: 'Đang tải...',
          ),
          label: 'Đang tải...',
          enabled: false,
        )
      ];
    }

    if (_filteredSupplies.isEmpty) {
      return [
        DropdownMenuEntry<Supply>(
          value: Supply(
            id: 0,
            name: 'Không tìm thấy',
          ),
          label: 'Không tìm thấy nhà cung cấp',
          enabled: false,
        )
      ];
    }

    return _filteredSupplies
        .map((supply) => DropdownMenuEntry<Supply>(
              value: supply,
              label: supply.name,
              leadingIcon: const Icon(Icons.business),
              labelWidget: _buildSupplyLabel(supply),
            ))
        .toList();
  }

  Widget _buildSupplyLabel(Supply supply) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          supply.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
