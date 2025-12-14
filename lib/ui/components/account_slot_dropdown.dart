import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_slot_service.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fcode_pos/ui/components/debounced_search_input.dart';
import 'package:fcode_pos/ui/components/dropdown/account_master_dropdown.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';

class AccountSlotDropdown extends StatefulWidget {
  final AccountSlot? selectedSlot;
  final Function(AccountSlot?)? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? Function(AccountSlot?)? validator;
  final String? labelText;

  const AccountSlotDropdown({
    this.selectedSlot,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.labelText,
    super.key,
  });

  @override
  State<AccountSlotDropdown> createState() => _AccountSlotDropdownState();
}

class _AccountSlotDropdownState extends State<AccountSlotDropdown> {
  final _accountSlotService = AccountSlotService();
  List<AccountSlot> _availableSlots = [];
  bool _isLoading = false;
  AccountSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.selectedSlot;
    _loadAvailableSlots();
  }

  @override
  void didUpdateWidget(AccountSlotDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSlot != oldWidget.selectedSlot) {
      setState(() {
        _selectedSlot = widget.selectedSlot;
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final activeSlots = await _accountSlotService.available(
        _selectedSlot?.id,
      );

      if (!mounted) return;
      final items = activeSlots.data ?? [];
      setState(() {
        _availableSlots = items;
        // Nếu có selectedSlot, tìm lại trong danh sách để đảm bảo reference đúng
        if (_selectedSlot != null) {
          _selectedSlot = _availableSlots.firstWhere(
            (s) => s.id == _selectedSlot!.id,
            orElse: () => _selectedSlot!,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading account slots: $e');
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
    return '$username • ${slot.name}';
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labelText ?? 'Account Slot';

    if (_isLoading) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: '$label${widget.isRequired ? ' *' : ''}',
          prefixIcon: const Icon(Icons.account_box_outlined),
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
      controller: TextEditingController(
        text: _selectedSlot != null
            ? _buildSlotDisplayName(_selectedSlot!)
            : '',
      ),
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: '$label${widget.isRequired ? ' *' : ''}',
        prefixIcon: const Icon(Icons.account_box_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedSlot != null && widget.enabled)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedSlot = null;
                  });
                  widget.onChanged?.call(null);
                },
              ),
            if (widget.enabled)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Thêm slot mới',
                onPressed: () async {
                  final newSlot = await showModalBottomSheet<AccountSlot>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (context) => const _AddSlotSheet(),
                  );
                  if (newSlot != null) {
                    await _loadAvailableSlots();
                    setState(() {
                      _selectedSlot = newSlot;
                    });
                    widget.onChanged?.call(newSlot);
                  }
                },
              ),
          ],
        ),
      ),
      onTap: widget.enabled
          ? () async {
              final selected = await showModalBottomSheet<AccountSlot>(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return _AccountSlotSelectSheet(
                    slots: _availableSlots,
                    selected: _selectedSlot,
                  );
                },
              );
              if (selected != null) {
                setState(() {
                  _selectedSlot = selected;
                });
                widget.onChanged?.call(selected);
              }
            }
          : null,
      validator: (value) {
        if (widget.validator != null) {
          return widget.validator!(_selectedSlot);
        } else if (widget.isRequired && _selectedSlot == null) {
          return 'Vui lòng chọn account slot';
        }
        return null;
      },
    );
  }
}

class _AccountSlotSelectSheet extends StatefulWidget {
  final List<AccountSlot> slots;
  final AccountSlot? selected;
  const _AccountSlotSelectSheet({required this.slots, this.selected});

  @override
  State<_AccountSlotSelectSheet> createState() =>
      _AccountSlotSelectSheetState();
}

class _AccountSlotSelectSheetState extends State<_AccountSlotSelectSheet> {
  late List<AccountSlot> _filtered;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.slots;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _buildSlotDisplayName(AccountSlot slot) {
    final username = slot.accountMaster?.username ?? 'N/A';
    return '$username • ${slot.name}';
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
              // Container(
              //   width: 40,
              //   height: 4,
              //   margin: const EdgeInsets.only(bottom: 12),
              //   // decoration: BoxDecoration(
              //   //   color: Colors.grey[300],
              //   //   borderRadius: BorderRadius.circular(2),
              //   // ),
              // ),
              DebouncedSearchInput(
                controller: _searchController,
                autofocus: true,
                hintText: 'Tìm kiếm account slot...',
                onChanged: (query) {
                  if (!mounted) return;
                  final q = query.toLowerCase();
                  setState(() {
                    _filtered = widget.slots.where((slot) {
                      final username = (slot.accountMaster?.username ?? '')
                          .toLowerCase();
                      final slotName = slot.name.toLowerCase();
                      final serviceType =
                          (slot.accountMaster?.serviceType ?? '').toLowerCase();
                      return username.contains(q) ||
                          slotName.contains(q) ||
                          serviceType.contains(q);
                    }).toList();
                  });
                },
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _filtered.isEmpty
                    ? const Center(child: Text('Không có account slot phù hợp'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final slot = _filtered[index];
                          return ListTile(
                            // contentPadding: const EdgeInsets.symmetric(
                            //   horizontal: 16,
                            //   vertical: 4,
                            // ),
                            title: Text(_buildSlotDisplayName(slot)),
                            subtitle: _buildSlotSubtitle(slot),
                            trailing: widget.selected?.id == slot.id
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(slot);
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

  Widget _buildSlotSubtitle(AccountSlot slot) {
    final serviceType = slot.accountMaster?.serviceType ?? 'N/A';
    final expiryDateStr = slot.expiryDate != null
        ? DateFormat('dd/MM/yyyy').format(slot.expiryDate!)
        : 'N/A';

    // Check if slot is about to expire (within 7 days)
    final isExpiringSoon =
        slot.expiryDate != null &&
        slot.expiryDate!.difference(DateTime.now()).inDays <= 7;

    return Row(
      children: [
        Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          serviceType.toUpperCase(),
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
            fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (slot.shopOrderItemId == null) const SizedBox(width: 8),
        if (slot.shopOrderItemId == null)
          Icon(
            Icons.remove_shopping_cart,
            size: 14,
            color: Colors.green.shade600,
          ),
      ],
    );
  }
}

class _AddSlotSheet extends StatefulWidget {
  const _AddSlotSheet();

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _accountMasterService = AccountMasterService();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  AccountMaster? _selectedAccountMaster;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _accountMasterService.addSlot(
        _selectedAccountMaster!.id,
        name: _nameController.text.trim(),
        pin: _pinController.text.trim().isEmpty
            ? null
            : _pinController.text.trim(),
      );

      if (!mounted) return;
      Toastr.success('Thêm slot thành công', context: context);
      Navigator.of(context).pop(response.data);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: ${e.toString()}', context: context);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Thêm slot mới',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AccountMasterDropdown(
                selectedAccountMaster: _selectedAccountMaster,
                onChanged: (accountMaster) {
                  setState(() {
                    _selectedAccountMaster = accountMaster;
                  });
                },
                isRequired: true,
                labelText: 'Account Master',
                validator: (_) {
                  if (_selectedAccountMaster == null) {
                    return 'Vui lòng chọn account master';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên slot *',
                  hintText: 'Nhập tên slot',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên slot';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  hintText: 'Nhập PIN (không bắt buộc)',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: LoadingIcon(
                  icon: Icons.check_circle_outline_outlined,
                  loading: _isSubmitting,
                ),
                label: Text(_isSubmitting ? 'Đang thêm...' : 'Thêm'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
