import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/account_slot/account_slot_filter_provider.dart';
import 'package:fcode_pos/ui/components/app_switch_tile.dart';
import 'package:fcode_pos/ui/components/dropdown/supply_dropdown.dart';
import 'package:fcode_pos/ui/components/service_icon.dart';
import 'package:flutter/material.dart';

class AccountMasterFilterSheet extends StatefulWidget {
  final AccountSlotFilter initialFilter;
  final ValueChanged<AccountSlotFilter> onApply;
  final VoidCallback onReset;

  const AccountMasterFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    required this.onReset,
  });

  static Future<void> show(
    BuildContext context, {
    required AccountSlotFilter initialFilter,
    required ValueChanged<AccountSlotFilter> onApply,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => AccountMasterFilterSheet(
        initialFilter: initialFilter,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<AccountMasterFilterSheet> createState() =>
      _AccountMasterFilterSheetState();
}

class _AccountMasterFilterSheetState extends State<AccountMasterFilterSheet> {
  enums.AccountMasterServiceType? _selectedServiceType;
  bool? _selectedIsActive;
  bool _selectedIsFreeSlot = false;
  Supply? _selectedSupply;
  int? _selectedDaysRemaining;

  @override
  void initState() {
    super.initState();
    _selectedServiceType = widget.initialFilter.serviceType;
    _selectedIsActive = widget.initialFilter.isActive;
    _selectedIsFreeSlot = widget.initialFilter.isFreeSlot;
    _selectedSupply = widget.initialFilter.supply;
    _selectedDaysRemaining = widget.initialFilter.daysRemaining;
  }

  void _reset() {
    setState(() {
      _selectedServiceType = null;
      _selectedIsActive = null;
      _selectedIsFreeSlot = false;
      _selectedSupply = null;
      _selectedDaysRemaining = null;
    });
    widget.onReset();
    Navigator.pop(context);
  }

  void _apply() {
    final updatedFilter = widget.initialFilter.copyWith(
      serviceType: () => _selectedServiceType,
      isActive: () => _selectedIsActive,
      isFreeSlot: _selectedIsFreeSlot,
      supply: () => _selectedSupply,
      daysRemaining: () => _selectedDaysRemaining,
    );
    widget.onApply(updatedFilter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Bộ lọc',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _reset,
                child: const Text('Đặt lại'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOẠI DỊCH VỤ', style: labelStyle),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _selectedServiceType == null,
                        showCheckmark: false,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setState(
                          () => _selectedServiceType = null,
                        ),
                      ),
                      ...enums.AccountMasterServiceType.values.map(
                        (type) => ChoiceChip(
                          avatar: ServiceIcon(
                            serviceType: type,
                            size: 14,
                          ),
                          label: Text(type.label),
                          selected: _selectedServiceType == type,
                          showCheckmark: false,
                          labelStyle: const TextStyle(fontSize: 12),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(
                            () => _selectedServiceType = type,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('TRẠNG THÁI', style: labelStyle),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _selectedIsActive == null,
                        showCheckmark: false,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setState(
                          () => _selectedIsActive = null,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Hoạt động'),
                        selected: _selectedIsActive == true,
                        showCheckmark: false,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setState(
                          () => _selectedIsActive = true,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Không hoạt động'),
                        selected: _selectedIsActive == false,
                        showCheckmark: false,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setState(
                          () => _selectedIsActive = false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('SỐ NGÀY CÒN LẠI', style: labelStyle),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final entry in {
                        'Tất cả': null,
                        '≤ 0': 0,
                        '≤ 1': 1,
                        '≤ 3': 3,
                        '≤ 5': 5,
                      }.entries)
                        ChoiceChip(
                          label: Text(entry.key),
                          selected: _selectedDaysRemaining == entry.value,
                          showCheckmark: false,
                          labelStyle: const TextStyle(fontSize: 12),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(
                            () => _selectedDaysRemaining = entry.value,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('NHÀ CUNG CẤP', style: labelStyle),
                  const SizedBox(height: 6),
                  SupplyDropdown(
                    selectedSupply: _selectedSupply,
                    onChanged: (supply) {
                      setState(() {
                        _selectedSupply = supply;
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  AppSwitchTile(
                    title: 'Chỉ hiện TK còn slot trống',
                    value: _selectedIsFreeSlot,
                    onChanged: (v) => setState(() => _selectedIsFreeSlot = v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
