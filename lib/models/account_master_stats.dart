import 'package:fcode_pos/utils/extensions.dart';

class AccountMasterStats {
  final int? totalAccounts;
  final int? activeAccounts;
  final int? inactiveAccounts;
  final int? totalMaxSlots;
  final int? totalActiveSlots;
  final int? totalFreeSlots;
  final int? expiringSlotsCount;
  final int? expiredSlotsCount;
  final int? totalMonthlyCost;
  final List<ByServiceType>? byServiceType;

  AccountMasterStats({
    required this.totalAccounts,
    required this.activeAccounts,
    required this.inactiveAccounts,
    required this.totalMaxSlots,
    required this.totalActiveSlots,
    required this.totalFreeSlots,
    required this.expiringSlotsCount,
    required this.expiredSlotsCount,
    required this.totalMonthlyCost,
    required this.byServiceType,
  });

  factory AccountMasterStats.fromJson(Map<String, dynamic> map) {
    return AccountMasterStats(
      totalAccounts: asInt(map['total_accounts']),
      activeAccounts: asInt(map['active_accounts']),
      inactiveAccounts: asInt(map['inactive_accounts']),
      totalMaxSlots: asInt(map['total_max_slots']),
      totalActiveSlots: asInt(map['total_active_slots']),
      totalFreeSlots: asInt(map['total_free_slots']),
      expiringSlotsCount: asInt(map['expiring_slots_count']),
      expiredSlotsCount: asInt(map['expired_slots_count']),
      totalMonthlyCost: asInt(map['total_monthly_cost']),
      byServiceType: map['by_service_type'] is List
          ? (map['by_service_type'] as List)
              .map((v) => ByServiceType.fromJson(ensureMap(v)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_accounts': totalAccounts,
      'active_accounts': activeAccounts,
      'inactive_accounts': inactiveAccounts,
      'total_max_slots': totalMaxSlots,
      'total_active_slots': totalActiveSlots,
      'total_free_slots': totalFreeSlots,
      'expiring_slots_count': expiringSlotsCount,
      'expired_slots_count': expiredSlotsCount,
      'total_monthly_cost': totalMonthlyCost,
      'by_service_type': byServiceType?.map((v) => v.toMap()).toList(),
    };
  }
}

class ByServiceType {
  String? serviceType;
  String? serviceLabel;
  int? totalAccounts;
  int? activeAccounts;
  int? totalMaxSlots;
  int? totalActiveSlots;
  int? totalFreeSlots;

  ByServiceType({
    this.serviceType,
    this.serviceLabel,
    this.totalAccounts,
    this.activeAccounts,
    this.totalMaxSlots,
    this.totalActiveSlots,
    this.totalFreeSlots,
  });

  factory ByServiceType.fromJson(Map<String, dynamic> map) {
    return ByServiceType(
      serviceType: (map['service_type']) ?? '',
      serviceLabel: (map['service_label']) ?? '',
      totalAccounts: asInt(map['total_accounts']),
      activeAccounts: asInt(map['active_accounts']),
      totalMaxSlots: asInt(map['total_max_slots']),
      totalActiveSlots: asInt(map['total_active_slots']),
      totalFreeSlots: asInt(map['total_free_slots']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_type': serviceType,
      'service_label': serviceLabel,
      'total_accounts': totalAccounts,
      'active_accounts': activeAccounts,
      'total_max_slots': totalMaxSlots,
      'total_active_slots': totalActiveSlots,
      'total_free_slots': totalFreeSlots,
    };
  }
}
