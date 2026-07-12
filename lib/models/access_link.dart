part of '../models.dart';

class AccessLink {
  final int id;
  final int accountSlotId;
  final String slug;
  final String url;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? shopOrderId;
  final int? accountMasterId;

  AccessLink({
    required this.id,
    required this.accountSlotId,
    required this.slug,
    required this.url,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.shopOrderId,
    this.accountMasterId,
  });

  factory AccessLink.fromJson(Map<String, dynamic> json) {
    return AccessLink(
      id: asInt(json['id']),
      accountSlotId: asInt(json['account_slot_id']),
      slug: json['slug']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      shopOrderId: asIntOrNull(json['shop_order_id']),
      accountMasterId: asIntOrNull(json['account_master_id']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_slot_id': accountSlotId,
      'slug': slug,
      'url': url,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'shop_order_id': shopOrderId,
      'account_master_id': accountMasterId,
    };
  }
}

class AccessLinkVisit {
  final int id;
  final int accountSlotAccessLinkId;
  final int? accountSlotId;
  final int? shopOrderItemId;
  final int? userId;
  final String? ipAddress;
  final String? userAgent;
  final String? referer;
  final String? locationProvider;
  final String? locationStatus;
  final String? locationMessage;
  final String? country;
  final String? countryCode;
  final String? region;
  final String? regionName;
  final String? city;
  final String? zip;
  final double? lat;
  final double? lon;
  final String? timezone;
  final String? isp;
  final String? org;

  /// Thông tin AS (autonomous system) — key JSON là `as`.
  final String? asInfo;
  final DateTime? visitedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AccessLinkVisit({
    required this.id,
    required this.accountSlotAccessLinkId,
    this.accountSlotId,
    this.shopOrderItemId,
    this.userId,
    this.ipAddress,
    this.userAgent,
    this.referer,
    this.locationProvider,
    this.locationStatus,
    this.locationMessage,
    this.country,
    this.countryCode,
    this.region,
    this.regionName,
    this.city,
    this.zip,
    this.lat,
    this.lon,
    this.timezone,
    this.isp,
    this.org,
    this.asInfo,
    this.visitedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AccessLinkVisit.fromJson(Map<String, dynamic> json) {
    return AccessLinkVisit(
      id: asInt(json['id']),
      accountSlotAccessLinkId: asInt(json['account_slot_access_link_id']),
      accountSlotId: asIntOrNull(json['account_slot_id']),
      shopOrderItemId: asIntOrNull(json['shop_order_item_id']),
      userId: asIntOrNull(json['user_id']),
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      referer: json['referer']?.toString(),
      locationProvider: json['location_provider']?.toString(),
      locationStatus: json['location_status']?.toString(),
      locationMessage: json['location_message']?.toString(),
      country: json['country']?.toString(),
      countryCode: json['country_code']?.toString(),
      region: json['region']?.toString(),
      regionName: json['region_name']?.toString(),
      city: json['city']?.toString(),
      zip: json['zip']?.toString(),
      lat: asDoubleOrNull(json['lat']),
      lon: asDoubleOrNull(json['lon']),
      timezone: json['timezone']?.toString(),
      isp: json['isp']?.toString(),
      org: json['org']?.toString(),
      asInfo: json['as']?.toString(),
      visitedAt: json['visited_at'] != null
          ? DateTime.tryParse(json['visited_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Vị trí gộp ngắn gọn (city, region, country) nếu có.
  String get locationSummary {
    final parts = [
      city,
      regionName,
      country,
    ].where((e) => e != null && e.isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.join(', ');
  }

  bool get hasLocation => locationSummary.isNotEmpty;
}
