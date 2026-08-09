import 'package:fcode_pos/utils/functions.dart';

/// DTO chứa thông tin mã/link xác minh từ Account Master API.
class AccountMasterCodeItem {
  final String? code;
  final String? link;
  final String? message;
  final DateTime? createdAt;
  final String? rawCreatedAt;

  const AccountMasterCodeItem({
    this.code,
    this.link,
    this.message,
    this.createdAt,
    this.rawCreatedAt,
  });

  factory AccountMasterCodeItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final createdVal =
        json['created_at'] ?? json['createdAt'] ?? json['time'] ?? json['date'];

    if (createdVal != null) {
      if (createdVal is String) {
        parsedDate = DateTime.tryParse(createdVal);
      } else if (createdVal is int) {
        if (createdVal > 10000000000) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(createdVal);
        } else {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(createdVal * 1000);
        }
      }
    }

    final codeVal = json['code'] ?? json['pin'] ?? json['otp'];
    final linkVal = json['link'] ?? json['url'] ?? json['click_action'];
    final msgVal =
        json['message'] ?? json['title'] ?? json['body'] ?? json['text'];

    return AccountMasterCodeItem(
      code: codeVal?.toString(),
      link: linkVal?.toString(),
      message: msgVal?.toString(),
      createdAt: parsedDate,
      rawCreatedAt: createdVal?.toString(),
    );
  }

  factory AccountMasterCodeItem.fromDynamic(dynamic item) {
    if (item is Map<String, dynamic>) {
      return AccountMasterCodeItem.fromJson(item);
    }
    if (item is Map) {
      return AccountMasterCodeItem.fromJson(ensureMap(item));
    }
    if (item is String) {
      final trimmed = item.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return AccountMasterCodeItem(link: trimmed);
      }
      return AccountMasterCodeItem(code: trimmed);
    }
    return AccountMasterCodeItem(message: item.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      if (code != null) 'code': code,
      if (link != null) 'link': link,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (rawCreatedAt != null && createdAt == null) 'created_at': rawCreatedAt,
    };
  }
}
