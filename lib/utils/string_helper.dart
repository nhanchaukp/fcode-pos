class StringHelper {
  static String formatAccountString(Map<String, dynamic> account) {
    return account.entries
        .map((entry) => entry.value == null
            ? entry.key.toLowerCase()
            : '${entry.key.toLowerCase()}: ${entry.value}')
        .join('\n');
  }
}
