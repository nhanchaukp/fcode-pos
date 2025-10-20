import 'package:intl/intl.dart';

class DateHelper {
  /// Format ngày giờ đầy đủ: dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Format ngày giờ ngắn: dd/MM/yy HH:mm
  static String formatDateTimeShort(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yy HH:mm').format(date);
  }

  /// Format chỉ ngày: dd/MM/yyyy
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format chỉ ngày ngắn: dd/MM/yy
  static String formatDateShort(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yy').format(date);
  }

  /// Format chỉ giờ: HH:mm
  static String formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('HH:mm').format(date);
  }

  /// Format với custom pattern
  static String formatCustom(DateTime? date, String pattern) {
    if (date == null) return 'N/A';
    return DateFormat(pattern).format(date);
  }

  /// Parse string ISO8601 thành DateTime
  static DateTime? parseIso8601(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Tính khoảng thời gian từ bây giờ (relative time)
  static String timeAgo(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Kiểm tra ngày đã hết hạn
  static bool isExpired(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  /// Số ngày còn lại đến hạn
  static int daysUntil(DateTime? date) {
    if (date == null) return 0;
    final difference = date.difference(DateTime.now());
    return difference.inDays;
  }
}
