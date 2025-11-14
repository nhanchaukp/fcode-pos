import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/ui/components/debounced_search_input.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountSlotDropdown extends StatefulWidget {
  final AccountSlot? selectedSlot;
  final Function(AccountSlot) onSlotSelected;
  final VoidCallback onSlotCleared;

  const AccountSlotDropdown({
    this.selectedSlot,
    required this.onSlotSelected,
    required this.onSlotCleared,
    super.key,
  });

  @override
  State<AccountSlotDropdown> createState() => _AccountSlotDropdownState();
}

class _AccountSlotDropdownState extends State<AccountSlotDropdown> {
  final _accountSlotService = AccountSlotService();
  final _controller = TextEditingController();
  List<AccountSlot> _availableSlots = [];
  bool _isLoading = false;
  AccountSlot? _currentSelectedSlot;

  @override
  void initState() {
    super.initState();
    _currentSelectedSlot = widget.selectedSlot;
    if (_currentSelectedSlot != null) {
      _controller.text = _buildSlotDisplayName(_currentSelectedSlot!);
    }
    _loadAvailableSlots();
  }

  @override
  void didUpdateWidget(AccountSlotDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSlot?.id != oldWidget.selectedSlot?.id) {
      _currentSelectedSlot = widget.selectedSlot;
      if (_currentSelectedSlot != null) {
        _controller.text = _buildSlotDisplayName(_currentSelectedSlot!);
      } else {
        _controller.clear();
      }
      _loadAvailableSlots();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final activeSlots = await _accountSlotService.available(
        _currentSelectedSlot?.id,
      );

      if (!mounted) return;
      setState(() {
        _availableSlots = activeSlots.data ?? [];
        if (_currentSelectedSlot != null) {
          _currentSelectedSlot = _availableSlots.firstWhere(
            (slot) => slot.id == _currentSelectedSlot!.id,
            orElse: () => _currentSelectedSlot!,
          );
          _controller.text = _buildSlotDisplayName(_currentSelectedSlot!);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _availableSlots = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _buildSlotDisplayName(AccountSlot slot) {
    final username = slot.accountMaster?.username ?? 'N/A';
    return '$username - ${slot.name}';
  }

  Future<void> _openSlotPicker() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<AccountSlot>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _AccountSlotSelectSheet(
          slots: _availableSlots,
          selectedSlot: _currentSelectedSlot,
          displayBuilder: _buildSlotDisplayName,
          labelBuilder: _buildSlotLabel,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _currentSelectedSlot = selected;
        _controller.text = _buildSlotDisplayName(selected);
      });
      widget.onSlotSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    const label = 'Chọn account slot';

    if (_isLoading) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: label,
          prefixIcon: const Icon(Icons.account_box_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        enabled: false,
      );
    }

    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: const Icon(Icons.account_box_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentSelectedSlot != null)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Bỏ chọn account slot',
                onPressed: () {
                  setState(() {
                    _currentSelectedSlot = null;
                    _controller.clear();
                  });
                  widget.onSlotCleared();
                },
              ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Chọn account slot',
              onPressed: _openSlotPicker,
            ),
          ],
        ),
      ),
      onTap: _openSlotPicker,
    );
  }

  Widget _buildSlotLabel(AccountSlot slot) {
    final serviceType = slot.accountMaster?.serviceType ?? 'N/A';
    final username = slot.accountMaster?.username ?? 'N/A';
    final expiryDateStr = slot.expiryDate != null
        ? DateFormat('dd/MM/yyyy').format(slot.expiryDate!)
        : 'N/A';

    final isExpiringSoon =
        slot.expiryDate != null &&
        slot.expiryDate!.difference(DateTime.now()).inDays <= 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$serviceType: $username',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                slot.name,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.event_outlined,
              size: 14,
              color: isExpiringSoon ? Colors.orange : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              expiryDateStr,
              style: TextStyle(
                fontSize: 12,
                color: isExpiringSoon ? Colors.orange : Colors.grey.shade700,
                fontWeight: isExpiringSoon
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountSlotSelectSheet extends StatefulWidget {
  final List<AccountSlot> slots;
  final AccountSlot? selectedSlot;
  final String Function(AccountSlot) displayBuilder;
  final Widget Function(AccountSlot) labelBuilder;

  const _AccountSlotSelectSheet({
    required this.slots,
    this.selectedSlot,
    required this.displayBuilder,
    required this.labelBuilder,
  });

  @override
  State<_AccountSlotSelectSheet> createState() =>
      _AccountSlotSelectSheetState();
}

class _AccountSlotSelectSheetState extends State<_AccountSlotSelectSheet> {
  late List<AccountSlot> _filteredSlots;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _filteredSlots = widget.slots;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(AccountSlot slot, String query) {
    final lower = query.toLowerCase();
    final username = slot.accountMaster?.username?.toLowerCase() ?? '';
    final serviceType = slot.accountMaster?.serviceType?.toLowerCase() ?? '';
    final name = slot.name.toLowerCase();
    final pin = slot.pin.toLowerCase();
    final expiry = slot.expiryDate != null
        ? DateFormat('dd/MM/yyyy').format(slot.expiryDate!).toLowerCase()
        : '';
    final combined = widget.displayBuilder(slot).toLowerCase();

    return username.contains(lower) ||
        serviceType.contains(lower) ||
        name.contains(lower) ||
        pin.contains(lower) ||
        expiry.contains(lower) ||
        combined.contains(lower);
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
          constraints: const BoxConstraints(maxHeight: 420),
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
                hintText: 'Tìm kiếm account slot...',
                onChanged: (query) {
                  if (!mounted) return;
                  final trimmed = query.trim();
                  setState(() {
                    if (trimmed.isEmpty) {
                      _filteredSlots = widget.slots;
                    } else {
                      _filteredSlots = widget.slots
                          .where((slot) => _matchesQuery(slot, trimmed))
                          .toList();
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _filteredSlots.isEmpty
                    ? const Center(
                        child: Text('Không có account slot phù hợp'),
                      )
                    : ListView.separated(
                        itemCount: _filteredSlots.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final slot = _filteredSlots[index];
                          final isSelected =
                              widget.selectedSlot?.id == slot.id;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            leading: const Icon(Icons.account_circle_outlined),
                            title: widget.labelBuilder(slot),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () => Navigator.of(context).pop(slot),
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
