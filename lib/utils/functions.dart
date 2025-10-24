import 'package:url_launcher/url_launcher.dart';

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
