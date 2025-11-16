import 'package:url_launcher/url_launcher.dart';

int asInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;

  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    var s = value.trim();
    if (s.isEmpty) return defaultValue;

    // Remove common thousands separators and whitespace so values like
    final sanitized = s.replaceAll(RegExp(r'[,\s\u00A0]'), '');

    final d = double.tryParse(sanitized);
    if (d != null) return d.toInt();

    return int.tryParse(sanitized) ?? defaultValue;
  }

  if (value is bool) return value ? 1 : 0;

  return defaultValue;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    var s = value.trim();
    if (s.isEmpty) return null;

    // Sanitize common thousands separators so strings like
    // "526,572.43" are parsed as numbers.
    final sanitized = s.replaceAll(RegExp(r'[,\s\u00A0]'), '');

    final d = double.tryParse(sanitized);
    if (d != null) return d.toInt();

    return int.tryParse(sanitized);
  }

  if (value is bool) return value ? 1 : 0;

  return null;
}

double asDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is num) return value.toDouble();

  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return defaultValue;
    final sanitized = s.replaceAll(RegExp(r'[,\s\u00A0]'), '');
    return double.tryParse(sanitized) ?? defaultValue;
  }

  if (value is bool) return value ? 1.0 : 0.0;

  return defaultValue;
}

double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();

  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return null;
    final sanitized = s.replaceAll(RegExp(r'[,\s\u00A0]'), '');
    return double.tryParse(sanitized);
  }

  if (value is bool) return value ? 1.0 : 0.0;

  return null;
}

Map<String, dynamic> ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}

Future<void> openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

DateTime addMonths(DateTime date, int monthsToAdd) {
  var year = date.year;
  var month = date.month + monthsToAdd;
  var day = date.day;

  // Handle year rollover if the new month exceeds 12
  while (month > 12) {
    month -= 12;
    year++;
  }
  while (month < 1) {
    month += 12;
    year--;
  }

  // Adjust day if the resulting date is invalid (e.g., adding a month to January 31st results in February 31st)
  // This finds the last day of the target month
  var lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  if (day > lastDayOfTargetMonth) {
    day = lastDayOfTargetMonth;
  }

  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}
