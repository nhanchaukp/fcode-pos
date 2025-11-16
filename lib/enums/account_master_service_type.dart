part of '../enums.dart';

enum AccountMasterServiceType {
  netflix('Netflix', 'netflix'),
  youtube('YouTube', 'youtube'),
  googleOne('Google One', 'google_one'),
  chatgpt('ChatGPT', 'chatgpt');

  const AccountMasterServiceType(this.label, this.value);

  final String label;
  final String value;

  static AccountMasterServiceType? fromValue(String? value) {
    if (value == null) return null;
    try {
      return AccountMasterServiceType.values.firstWhere(
        (type) => type.value == value,
      );
    } catch (e) {
      return null;
    }
  }
}
