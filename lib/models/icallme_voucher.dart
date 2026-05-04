/// Icallme Voucher models (standalone - không dùng part of models.dart)

enum IcallmeVoucherStatus {
  available,
  used,
  revoked,
  expired,
  unknown;

  static IcallmeVoucherStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'available' => available,
      'used' => used,
      'revoked' => revoked,
      'expired' => expired,
      _ => unknown,
    };
  }

  String get label => switch (this) {
        available => 'Khả dụng',
        used => 'Đã dùng',
        revoked => 'Đã thu hồi',
        expired => 'Hết hạn',
        unknown => 'Không xác định',
      };
}

class IcallmeVoucher {
  const IcallmeVoucher({
    required this.voucherCode,
    required this.premiumDays,
    required this.status,
    required this.externalRefId,
    this.expiredAt,
    this.createdAt,
    this.redeemedAt,
    this.revokedAt,
    this.redeemedByUserId,
    this.externalMetadata,
  });

  final String voucherCode;
  final int premiumDays;
  final IcallmeVoucherStatus status;
  final String externalRefId;
  final DateTime? expiredAt;
  final DateTime? createdAt;
  final DateTime? redeemedAt;
  final DateTime? revokedAt;
  final String? redeemedByUserId;
  final Map<String, dynamic>? externalMetadata;

  bool get isExpired {
    if (expiredAt == null) return false;
    return expiredAt!.isBefore(DateTime.now());
  }

  factory IcallmeVoucher.fromJson(Map<String, dynamic> json) {
    return IcallmeVoucher(
      voucherCode: json['voucherCode']?.toString() ?? '',
      premiumDays: _parseInt(json['premiumDays']),
      status: IcallmeVoucherStatus.fromString(json['status']?.toString()),
      externalRefId: json['externalRefId']?.toString() ?? '',
      expiredAt: _parseDate(json['expiredAt']),
      createdAt: _parseDate(json['createdAt']),
      redeemedAt: _parseDate(json['redeemedAt']),
      revokedAt: _parseDate(json['revokedAt']),
      redeemedByUserId: json['redeemedByUserId']?.toString(),
      externalMetadata: json['externalMetadata'] is Map
          ? Map<String, dynamic>.from(json['externalMetadata'] as Map)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    try {
      return DateTime.parse(val.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
}

class IcallmeVoucherSummary {
  const IcallmeVoucherSummary({
    required this.totalCreated,
    required this.totalRedeemed,
    required this.totalExpired,
    required this.totalRevoked,
    required this.totalAvailable,
    required this.redemptionRate,
  });

  final int totalCreated;
  final int totalRedeemed;
  final int totalExpired;
  final int totalRevoked;
  final int totalAvailable;
  final double redemptionRate;

  factory IcallmeVoucherSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return IcallmeVoucherSummary(
      totalCreated: toInt(json['totalCreated']),
      totalRedeemed: toInt(json['totalRedeemed']),
      totalExpired: toInt(json['totalExpired']),
      totalRevoked: toInt(json['totalRevoked']),
      totalAvailable: toInt(json['totalAvailable']),
      redemptionRate: toDouble(json['redemptionRate']),
    );
  }
}

/// Kết quả phân trang từ icallme API (page/limit/total/totalPages format).
class IcalmePagedResult<T> {
  const IcalmePagedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory IcalmePagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final rawItems = json['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(itemParser)
            .toList(growable: false)
        : <T>[];

    return IcalmePagedResult<T>(
      items: items,
      page: toInt(json['page']),
      limit: toInt(json['limit']),
      total: toInt(json['total']),
      totalPages: toInt(json['totalPages']),
    );
  }
}
