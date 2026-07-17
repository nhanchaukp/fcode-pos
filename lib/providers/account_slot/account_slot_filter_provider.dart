import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models.dart';
import 'package:flutter_riverpod/legacy.dart';

class AccountSlotFilter {
  final String search;
  final enums.AccountMasterServiceType? serviceType;
  final bool? isActive;
  final bool isFreeSlot;
  final Supply? supply;
  final int? daysRemaining;

  const AccountSlotFilter({
    this.search = '',
    this.serviceType,
    this.isActive,
    this.isFreeSlot = false,
    this.supply,
    this.daysRemaining,
  });

  bool get hasFilters =>
      serviceType != null ||
      isActive != null ||
      daysRemaining != null ||
      isFreeSlot ||
      supply != null;

  AccountSlotFilter copyWith({
    String? search,
    enums.AccountMasterServiceType? Function()? serviceType,
    bool? Function()? isActive,
    bool? isFreeSlot,
    Supply? Function()? supply,
    int? Function()? daysRemaining,
  }) {
    return AccountSlotFilter(
      search: search ?? this.search,
      serviceType: serviceType != null ? serviceType() : this.serviceType,
      isActive: isActive != null ? isActive() : this.isActive,
      isFreeSlot: isFreeSlot ?? this.isFreeSlot,
      supply: supply != null ? supply() : this.supply,
      daysRemaining: daysRemaining != null
          ? daysRemaining()
          : this.daysRemaining,
    );
  }
}

final accountSlotFilterProvider = StateProvider<AccountSlotFilter>(
  (ref) => const AccountSlotFilter(),
);
