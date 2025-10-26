class ProductUpdateData {
  String? name;
  double? price;
  double? priceSale;
  int? instock;
  bool? isActive;
  bool? allowBuyMulti;
  bool? requireAccount;
  bool? requirePassword;
  int? expiryMonth;

  ProductUpdateData({
    this.name,
    this.price,
    this.priceSale,
    this.instock,
    this.isActive,
    this.allowBuyMulti,
    this.requireAccount,
    this.requirePassword,
    this.expiryMonth,
  });

  factory ProductUpdateData.fromJson(Map<String, dynamic> json) {
    return ProductUpdateData(
      name: json['name'] as String?,
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : null,
      priceSale: (json['price_sale'] != null)
          ? (json['price_sale'] as num).toDouble()
          : null,
      instock: json['instock'] as int?,
      isActive: json['is_active'] as bool?,
      allowBuyMulti: json['allow_buy_multi'] as bool?,
      requireAccount: json['require_account'] as bool?,
      requirePassword: json['require_password'] as bool?,
      expiryMonth: json['expiry_month'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (priceSale != null) 'price_sale': priceSale,
      if (instock != null) 'instock': instock,
      if (isActive != null) 'is_active': isActive,
      if (allowBuyMulti != null) 'allow_buy_multi': allowBuyMulti,
      if (requireAccount != null) 'require_account': requireAccount,
      if (requirePassword != null) 'require_password': requirePassword,
      if (expiryMonth != null) 'expiry_month': expiryMonth,
    };
  }
}
