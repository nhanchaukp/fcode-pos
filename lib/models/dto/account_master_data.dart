class AccountMasterData {
  final String name;
  final String username;
  final String password;
  final String serviceType;
  final int maxSlots;
  final String? notes;
  final DateTime? paymentDate;
  final int? monthlyCost;
  final String? costNotes;
  final bool isActive;
  final bool showPassword;
  final String? cookies;
  final String? details;
  final int? supplyId;
  final String? externalSrc;
  final Map<String, dynamic>? externalConfig;

  const AccountMasterData({
    required this.name,
    required this.username,
    required this.password,
    required this.serviceType,
    required this.maxSlots,
    required this.isActive,
    required this.showPassword,
    this.notes,
    this.paymentDate,
    this.monthlyCost,
    this.costNotes,
    this.cookies,
    this.details,
    this.supplyId,
    this.externalSrc,
    this.externalConfig,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'password': password,
      'service_type': serviceType,
      'max_slots': maxSlots,
      'is_active': isActive,
      'show_password': showPassword,
      'notes': notes,
      if (paymentDate != null) 'payment_date': paymentDate!.toIso8601String(),
      'monthly_cost': monthlyCost,
      if (costNotes != null && costNotes!.isNotEmpty) 'cost_notes': costNotes,
      if (cookies != null && cookies!.isNotEmpty) 'cookies': cookies,
      if (details != null && details!.isNotEmpty) 'details': details,
      if (supplyId != null) 'supply_id': supplyId,
      if (externalSrc != null && externalSrc!.isNotEmpty) 'external_src': externalSrc,
      if (externalConfig != null && externalConfig!.isNotEmpty)
        'external_config': externalConfig,
    };
  }
}
