part of '../models.dart';

/// List item – không chứa secrets, chỉ dùng các cờ has_*.
class AccountVaultItem implements Model {
  final int id;
  final String email;
  final String? provider;
  final bool isActive;
  final String? notes;
  final bool hasPassword;
  final bool hasClientId;
  final bool hasRefreshToken;
  final bool hasTwoFactorSecret;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountVaultItem({
    required this.id,
    required this.email,
    this.provider,
    required this.isActive,
    this.notes,
    required this.hasPassword,
    required this.hasClientId,
    required this.hasRefreshToken,
    required this.hasTwoFactorSecret,
    this.createdAt,
    this.updatedAt,
  });

  factory AccountVaultItem.fromJson(Map<String, dynamic> json) {
    return AccountVaultItem(
      id: json['id'],
      email: json['email']?.toString() ?? '',
      provider: json['provider']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      notes: json['notes']?.toString(),
      hasPassword: json['has_password'] == true || json['has_password'] == 1,
      hasClientId: json['has_client_id'] == true || json['has_client_id'] == 1,
      hasRefreshToken:
          json['has_refresh_token'] == true || json['has_refresh_token'] == 1,
      hasTwoFactorSecret:
          json['has_two_factor_secret'] == true ||
          json['has_two_factor_secret'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'provider': provider,
    'is_active': isActive,
    'notes': notes,
    'has_password': hasPassword,
    'has_client_id': hasClientId,
    'has_refresh_token': hasRefreshToken,
    'has_two_factor_secret': hasTwoFactorSecret,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// Detail – có thêm secrets (đã decrypt từ server).
class AccountVault extends AccountVaultItem {
  final String? password;
  final String? clientId;
  final String? refreshToken;
  final String? twoFactorSecret;

  const AccountVault({
    required super.id,
    required super.email,
    super.provider,
    required super.isActive,
    super.notes,
    required super.hasPassword,
    required super.hasClientId,
    required super.hasRefreshToken,
    required super.hasTwoFactorSecret,
    super.createdAt,
    super.updatedAt,
    this.password,
    this.clientId,
    this.refreshToken,
    this.twoFactorSecret,
  });

  bool get canReadMail =>
      email.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty &&
      clientId != null &&
      clientId!.isNotEmpty;

  factory AccountVault.fromJson(Map<String, dynamic> json) {
    return AccountVault(
      id: asInt(json['id']),
      email: json['email']?.toString() ?? '',
      provider: json['provider']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      notes: json['notes']?.toString(),
      hasPassword: json['has_password'] == true || json['has_password'] == 1,
      hasClientId: json['has_client_id'] == true || json['has_client_id'] == 1,
      hasRefreshToken:
          json['has_refresh_token'] == true || json['has_refresh_token'] == 1,
      hasTwoFactorSecret:
          json['has_two_factor_secret'] == true ||
          json['has_two_factor_secret'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      password: json['password']?.toString(),
      clientId: json['client_id']?.toString(),
      refreshToken: json['refresh_token']?.toString(),
      twoFactorSecret: json['two_factor_secret']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'password': password,
    'client_id': clientId,
    'refresh_token': refreshToken,
    'two_factor_secret': twoFactorSecret,
  };
}

/// Mail message trả về từ dongvanfb external API.
class VaultMailMessage {
  final int uid;
  final String date;
  final String subject;
  final String code;
  final List<VaultMailSender> from;

  /// Nội dung HTML đầy đủ của mail (có thể rỗng).
  final String htmlContent;

  const VaultMailMessage({
    required this.uid,
    required this.date,
    required this.subject,
    required this.code,
    required this.from,
    this.htmlContent = '',
  });

  factory VaultMailMessage.fromJson(Map<String, dynamic> json) {
    // `from` có thể là List<{name,address}> hoặc plain String
    final rawFrom = json['from'];
    final List<VaultMailSender> fromList;
    if (rawFrom is List) {
      fromList = rawFrom
          .map((e) => VaultMailSender.fromJson(ensureMap(e)))
          .toList();
    } else if (rawFrom is String && rawFrom.isNotEmpty) {
      fromList = [VaultMailSender(name: '', address: rawFrom)];
    } else {
      fromList = [];
    }
    return VaultMailMessage(
      uid: asInt(json['uid']),
      date: json['date']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      from: fromList,
      htmlContent: json['message']?.toString() ?? '',
    );
  }

  String get senderName => from.isNotEmpty ? from.first.name : '';
  String get senderAddress => from.isNotEmpty ? from.first.address : '';
  bool get hasContent => htmlContent.isNotEmpty;
}

class VaultMailSender {
  final String name;
  final String address;

  const VaultMailSender({required this.name, required this.address});

  factory VaultMailSender.fromJson(Map<String, dynamic> json) => VaultMailSender(
    name: json['name']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
  );
}
