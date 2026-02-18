import 'package:fcode_pos/models.dart';

class StringHelper {
  static String formatAccountString(Map<String, dynamic> account) {
    return account.entries
        .map((entry) => entry.value == null
            ? entry.key.toLowerCase()
            : '${entry.key.toLowerCase()}: ${entry.value}')
        .join('\n');
  }

  /// Chuỗi copy thông tin slot (tài khoản, mật khẩu, slot, pin).
  /// Dùng chung cho OrderDetailScreen và AccountSlotManagementScreen.
  static String formatSlotCopyText(AccountSlot accountSlot) {
    final username = accountSlot.accountMaster?.username ?? 'N/A';
    final slot = accountSlot.name;
    final pin = accountSlot.pin;
    final password = accountSlot.accountMaster?.password ?? 'N/A';
    return '''- Tài khoản: $username
- Mật khẩu: $password
- Slot: $slot
- Pin: $pin''';
  }
}
