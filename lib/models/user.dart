part of '../models.dart';

/// User
class User implements Model {
  /// User ID.
  final int id;

  /// Username.
  final String username;

  /// User balance.
  final int balance;

  /// User name.
  final String name;

  /// User email address.
  final String email;

  /// Email verification date in ISO 8601 format.
  final String? emailVerifiedAt;

  /// User phone number.
  final String? phone;

  /// Google ID.
  final String? googleId;

  /// Facebook ID.
  final String? facebookId;

  /// Telegram ID.
  final String? telegramId;

  /// Two factor confirmation date.
  final String? twoFactorConfirmedAt;

  /// Current team ID.
  final int? currentTeamId;

  /// Profile photo path.
  final String? profilePhotoPath;

  /// User creation date in ISO 8601 format.
  final String? createdAt;

  /// User update date in ISO 8601 format.
  final String? updatedAt;

  /// Role ID.

  /// Avatar URL.
  final String? avatar;

  /// Full name.
  final String? fullname;

  /// Session login info.
  final String? sessionLogin;

  /// Reset password token.
  final String? resetPasswordToken;

  /// Facebook info.
  final String? facebook;

  /// FCM token.
  final String? fcmToken;

  /// User settings.
  final String? settings;

  /// User address.
  final String? address;

  /// Province ID.
  final int? provinceId;

  /// Facebook URL.
  final String? facebookUrl;

  /// Profile photo URL.
  final String? profilePhotoUrl;

  User({
    required this.id,
    required this.username,
    required this.balance,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.phone,
    this.googleId,
    this.facebookId,
    this.telegramId,
    this.twoFactorConfirmedAt,
    this.currentTeamId,
    this.profilePhotoPath,
    this.createdAt,
    this.updatedAt,
    this.avatar,
    this.fullname,
    this.sessionLogin,
    this.resetPasswordToken,
    this.facebook,
    this.fcmToken,
    this.settings,
    this.address,
    this.provinceId,
    this.facebookUrl,
    this.profilePhotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: asInt(map['id']),
      username: map['username']?.toString() ?? '',
      balance: asInt(map['balance']),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      emailVerifiedAt: map['email_verified_at']?.toString(),
      phone: map['phone']?.toString(),
      googleId: map['google_id'],
      facebookId: map['facebook_id'],
      telegramId: map['telegram_id'],
      twoFactorConfirmedAt: map['two_factor_confirmed_at']?.toString(),
      currentTeamId: asIntOrNull(map['current_team_id']),
      profilePhotoPath: map['profile_photo_path']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      avatar: map['avatar']?.toString(),
      fullname: map['fullname']?.toString(),
      sessionLogin: map['session_login']?.toString(),
      resetPasswordToken: map['reset_password_token']?.toString(),
      facebook: map['facebook']?.toString(),
      fcmToken: map['fcm_token']?.toString(),
      settings: map['settings']?.toString(),
      address: map['address']?.toString(),
      provinceId: asIntOrNull(map['province_id']),
      facebookUrl: map['facebook_url']?.toString(),
      profilePhotoUrl: map['profile_photo_url']?.toString(),
    );
  }
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'balance': balance,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'phone': phone,
      'google_id': googleId,
      'facebook_id': facebookId,
      'telegram_id': telegramId,
      'two_factor_confirmed_at': twoFactorConfirmedAt,
      'current_team_id': currentTeamId,
      'profile_photo_path': profilePhotoPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'avatar': avatar,
      'fullname': fullname,
      'session_login': sessionLogin,
      'reset_password_token': resetPasswordToken,
      'facebook': facebook,
      'fcm_token': fcmToken,
      'settings': settings,
      'address': address,
      'province_id': provinceId,
      'facebook_url': facebookUrl,
      'profile_photo_url': profilePhotoUrl,
    };
  }
}
