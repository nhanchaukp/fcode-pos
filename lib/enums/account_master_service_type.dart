part of '../enums.dart';

enum AccountMasterServiceType implements LabeledIconEnum {
  netflix('Netflix', 'netflix'),
  youtube('YouTube', 'youtube'),
  googleOne('Google One', 'google_one'),
  chatgpt('ChatGPT', 'chatgpt'),
  microsoft('Microsoft', 'microsoft');

  const AccountMasterServiceType(this.label, this.value);

  @override
  final String label;
  final String value;

  @override
  IconData get icon => switch (this) {
    AccountMasterServiceType.netflix => Icons.movie,
    AccountMasterServiceType.youtube => Icons.ondemand_video,
    AccountMasterServiceType.googleOne => Icons.cloud,
    AccountMasterServiceType.chatgpt => Icons.chat,
    AccountMasterServiceType.microsoft => Icons.computer,
  };

  @override
  Color get color => switch (this) {
    AccountMasterServiceType.netflix => AppColor.red,
    AccountMasterServiceType.youtube => AppColor.red,
    AccountMasterServiceType.googleOne => AppColor.blue,
    AccountMasterServiceType.chatgpt => AppColor.green,
    AccountMasterServiceType.microsoft => AppColor.indigo,
  };

  static AccountMasterServiceType? fromValue(String? value) {
    return _enumFromStringValue(
      AccountMasterServiceType.values,
      value,
      (type) => type.value,
      caseInsensitive: true,
    );
  }
}
