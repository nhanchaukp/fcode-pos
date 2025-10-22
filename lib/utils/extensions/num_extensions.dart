int asInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;

  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return defaultValue;

    final d = double.tryParse(s);
    if (d != null) return d.toInt();

    return int.tryParse(s) ?? defaultValue;
  }

  if (value is bool) return value ? 1 : 0;

  return defaultValue;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;

  if (value is int) return value;
  if (value is num) return value.toInt();

  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return null;

    final d = double.tryParse(s);
    if (d != null) return d.toInt();

    return int.tryParse(s);
  }

  if (value is bool) return value ? 1 : 0;

  return null;
}
