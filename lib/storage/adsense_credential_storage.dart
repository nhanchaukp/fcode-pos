import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdsenseCredential {
  AdsenseCredential({
    required this.email,
    this.displayName,
    this.photoUrl,
    this.accessToken,
    this.idToken,
    this.accountName,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? accessToken;
  final String? idToken;
  final String? accountName;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'accessToken': accessToken,
    'idToken': idToken,
    'accountName': accountName,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AdsenseCredential.fromJson(Map<String, dynamic> json) {
    return AdsenseCredential(
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      accessToken: json['accessToken'] as String?,
      idToken: json['idToken'] as String?,
      accountName: json['accountName'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class AdsenseCredentialStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );
  static const _keyCredential = 'adsense_credential';

  static Future<void> saveCredential(AdsenseCredential credential) async {
    try {
      final payload = jsonEncode(credential.toJson());
      await _storage.write(key: _keyCredential, value: payload);
    } catch (e) {
      debugPrint('Error saving AdSense credentials: $e');
      rethrow;
    }
  }

  static Future<AdsenseCredential?> readCredential() async {
    try {
      final data = await _storage.read(key: _keyCredential);
      if (data == null || data.isEmpty) return null;
      final decoded = jsonDecode(data);
      if (decoded is! Map) return null;
      return AdsenseCredential.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );
    } catch (e) {
      debugPrint('Error reading AdSense credentials: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _keyCredential);
    } catch (e) {
      debugPrint('Error clearing AdSense credentials: $e');
    }
  }
}
