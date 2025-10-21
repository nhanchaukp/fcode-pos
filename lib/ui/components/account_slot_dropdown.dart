import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
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
  List<AccountSlot> _availableSlots = [];
  bool _isLoading = false;
  AccountSlot? _currentSelectedSlot;

  @override
  void initState() {
    super.initState();
    _currentSelectedSlot = widget.selectedSlot;
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAvailableSlots() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final activeSlots = await _accountSlotService.available();

      if (!mounted) return;
      setState(() {
        _availableSlots = activeSlots.data ?? [];
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

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<AccountSlot>(
      enableSearch: false,
      requestFocusOnTap: true,
      initialSelection: _currentSelectedSlot,
      onSelected: (AccountSlot? slot) {
        if (slot != null && slot.id != 0) {
          widget.onSlotSelected(slot);
          setState(() {
            _currentSelectedSlot = slot;
          });
        }
      },
      expandedInsets: EdgeInsets.zero,
      menuHeight: 300,
      dropdownMenuEntries: _buildDropdownEntries(),
      hintText: 'Chọn account slot',
      label: const Text('Account Slot (Tùy chọn)'),
      leadingIcon: const Icon(Icons.account_box_outlined),
      trailingIcon: _currentSelectedSlot != null
          ? GestureDetector(
              onTap: () {
                widget.onSlotCleared();
                setState(() {
                  _currentSelectedSlot = null;
                });
              },
              child: const Icon(Icons.close),
            )
          : null,
    );
  }

  List<DropdownMenuEntry<AccountSlot>> _buildDropdownEntries() {
    if (_isLoading) {
      return [
        DropdownMenuEntry<AccountSlot>(
          value: AccountSlot(
            id: 0,
            accountMasterId: 0,
            name: 'Đang tải...',
            pin: '',
            durationMonths: 0,
            isActive: false,
          ),
          label: 'Đang tải...',
          enabled: false,
        ),
      ];
    }

    if (_availableSlots.isEmpty) {
      return [
        DropdownMenuEntry<AccountSlot>(
          value: AccountSlot(
            id: 0,
            accountMasterId: 0,
            name: 'Không có slot',
            pin: '',
            durationMonths: 0,
            isActive: false,
          ),
          label: 'Không có account slot nào',
          enabled: false,
        ),
      ];
    }

    return _availableSlots
        .map(
          (slot) => DropdownMenuEntry<AccountSlot>(
            value: slot,
            label: _buildSlotDisplayName(slot),
            leadingIcon: const Icon(Icons.account_circle),
            labelWidget: _buildSlotLabel(slot),
          ),
        )
        .toList();
  }

  Widget _buildSlotLabel(AccountSlot slot) {
    final serviceType = slot.accountMaster?.serviceType ?? 'N/A';
    final username = slot.accountMaster?.username ?? 'N/A';
    final expiryDateStr = slot.expiryDate != null
        ? DateFormat('dd/MM/yyyy').format(slot.expiryDate!)
        : 'N/A';

    // Check if slot is about to expire (within 7 days)
    final isExpiringSoon =
        slot.expiryDate != null &&
        slot.expiryDate!.difference(DateTime.now()).inDays <= 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: Service Type + Username
        Text(
          '$serviceType: $username',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Line 2: Slot Name + Expiry Date
        Row(
          children: [
            Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              slot.name,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
