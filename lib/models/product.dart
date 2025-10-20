part of '../models.dart';

/// Product
class Product {
  /// Product ID.
  final int id;

  /// Product name.
  final String name;

  /// Product slug.
  final String slug;

  /// Product picture.
  final String? picture;

  /// In stock quantity.
  final int instock;

  /// SEO meta description.
  final String? seoMeta;

  /// Product description (HTML).
  final String? description;

  /// Warranty information (HTML).
  final String? warranty;

  /// Product group.
  final String? group;

  /// SKU.
  final String? sku;

  /// Allow buy multiple.
  final bool allowBuyMulti;

  /// Require account.
  final bool requireAccount;

  /// Require password.
  final bool requirePassword;

  /// Product price.
  final int price;

  /// Is active.
  final bool isActive;

  /// Sale price.
  final int? priceSale;

  /// Warning message.
  final String? warning;

  /// Expiry months.
  final int? expiryMonth;

  /// Upgrade method.
  final String? upgradeMethod;

  /// FAQ ID.
  final int? faqId;

  /// Creation date.
  final DateTime? createdAt;

  /// Update date.
  final DateTime? updatedAt;

  /// Page ID.
  final int? pageId;

  /// Tags.
  final List<dynamic> tags;

  /// Best price.
  final int? bestPrice;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.picture,
    required this.instock,
    this.seoMeta,
    this.description,
    this.warranty,
    this.group,
    this.sku,
    this.allowBuyMulti = false,
    this.requireAccount = false,
    this.requirePassword = false,
    required this.price,
    this.isActive = true,
    this.priceSale,
    this.warning,
    this.expiryMonth,
    this.upgradeMethod,
    this.faqId,
    this.createdAt,
    this.updatedAt,
    this.pageId,
    this.tags = const [],
    this.bestPrice,
  });

  factory Product.fromJson(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toInt() ?? 0,
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      picture: map['picture']?.toString(),
      instock: map['instock']?.toInt() ?? 0,
      seoMeta: map['seo_meta']?.toString(),
      description: map['description']?.toString(),
      warranty: map['warranty']?.toString(),
      group: map['group']?.toString(),
      sku: map['sku']?.toString(),
      allowBuyMulti:
          map['allow_buy_multi'] == true || map['allow_buy_multi'] == 1,
      requireAccount:
          map['require_account'] == true || map['require_account'] == 1,
      requirePassword:
          map['require_password'] == true || map['require_password'] == 1,
      price: double.tryParse(map['price']?.toString() ?? '0')?.toInt() ?? 0,
      isActive: map['is_active'] == true || map['is_active'] == 1,
      priceSale: double.tryParse(map['price_sale']?.toString() ?? '0')?.toInt(),
      warning: map['warning']?.toString(),
      expiryMonth: map['expiry_month']?.toInt(),
      upgradeMethod: map['upgrade_method']?.toString(),
      faqId: map['faq_id']?.toInt(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
      pageId: map['page_id']?.toInt(),
      tags: (map['tags'] as List?) ?? [],
      bestPrice: map['best_price']?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'picture': picture,
      'instock': instock,
      'seo_meta': seoMeta,
      'description': description,
      'warranty': warranty,
      'group': group,
      'sku': sku,
      'allow_buy_multi': allowBuyMulti,
      'require_account': requireAccount,
      'require_password': requirePassword,
      'price': price,
      'is_active': isActive,
      'price_sale': priceSale,
      'warning': warning,
      'expiry_month': expiryMonth,
      'upgrade_method': upgradeMethod,
      'faq_id': faqId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'page_id': pageId,
      'tags': tags,
      'best_price': bestPrice,
    };
  }
}
