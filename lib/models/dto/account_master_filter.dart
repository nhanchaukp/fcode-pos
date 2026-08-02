class AccountMasterFilter {
  final int? accountMasterId;
  final bool? isActive;
  final String? serviceType;
  final String? search;
  final int? daysRemaining;
  final bool? isFreeSlot;
  final int? supplyId;
  final int? page;
  final int? perPage;

  const AccountMasterFilter({
    this.accountMasterId,
    this.isActive,
    this.serviceType,
    this.search,
    this.daysRemaining,
    this.isFreeSlot,
    this.supplyId,
    this.page,
    this.perPage,
  });

  Map<String, dynamic> toJson() {
    return {
      'account_master_id': accountMasterId,
      'is_active': isActive,
      'service_type': serviceType,
      'search': search,
      'days_remaining': daysRemaining,
      'is_free_slot': isFreeSlot,
      'supply_id': supplyId,
      'page': page ?? 1,
      'per_page': perPage ?? 15,
    };
  }
}
