enum BuyerType {
  personal('personal', 'Cá nhân'),
  company('company', 'Công ty');

  const BuyerType(this.value, this.label);

  final String value;
  final String label;

  static BuyerType? fromValue(String? value) {
    if (value == null) return null;
    for (final type in BuyerType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
