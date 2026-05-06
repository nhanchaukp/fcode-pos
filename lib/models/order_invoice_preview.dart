part of '../models.dart';

/// Linked invoice row when đơn hàng đã có hóa đơn (preview).
class OrderInvoiceExistingInvoice {
  const OrderInvoiceExistingInvoice({
    required this.id,
    required this.status,
    required this.referenceCode,
    required this.providerAccountId,
    required this.templateCode,
    required this.invoiceSeries,
    this.issuedDate,
  });

  final int id;
  final String status;
  final String referenceCode;

  /// Often UUID string.
  final String providerAccountId;

  final String templateCode;
  final String invoiceSeries;
  final DateTime? issuedDate;

  factory OrderInvoiceExistingInvoice.fromJson(Map<String, dynamic> map) {
    DateTime? parseIssued(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return OrderInvoiceExistingInvoice(
      id: asInt(map['id']),
      status: map['status']?.toString() ?? '',
      referenceCode: map['reference_code']?.toString() ?? '',
      providerAccountId: map['provider_account_id']?.toString() ?? '',
      templateCode: map['template_code']?.toString() ?? '',
      invoiceSeries: map['invoice_series']?.toString() ?? '',
      issuedDate: parseIssued(map['issued_date']),
    );
  }
}

/// Line item in order invoice preview.
class OrderInvoicePreviewItem {
  const OrderInvoicePreviewItem({
    required this.orderItemId,
    required this.lineNumber,
    required this.lineType,
    required this.itemCode,
    required this.itemName,
    required this.unitValue,
    this.unitLabel,
    required this.quantity,
    required this.unitPrice,
    required this.taxRateValue,
    required this.lineTotal,
    required this.beforeDiscountAndTaxAmount,
  });

  final int orderItemId;
  final int lineNumber;
  final int lineType;
  final String itemCode;
  final String itemName;
  final String unitValue;
  final String? unitLabel;
  final num quantity;
  final int unitPrice;
  final int taxRateValue;
  final int lineTotal;
  final int beforeDiscountAndTaxAmount;

  enums.InvoiceUnit? get unitEnum => enums.InvoiceUnit.fromValue(unitValue);
  enums.TaxRate? get taxRateEnum => enums.TaxRate.fromValue(taxRateValue);

  String get lineTypeLabel =>
      enums.LineType.fromValue(lineType)?.label ?? 'Loại dòng $lineType';

  String get unitDisplay {
    if ((unitLabel ?? '').isNotEmpty) return '${unitLabel!} ($unitValue)';
    if (unitEnum != null) return unitEnum!.label;
    return unitValue;
  }

  int get taxAmount {
    final raw = lineTotal - beforeDiscountAndTaxAmount;
    return raw < 0 ? 0 : raw;
  }

  factory OrderInvoicePreviewItem.fromJson(Map<String, dynamic> map) {
    return OrderInvoicePreviewItem(
      orderItemId: asInt(map['order_item_id']),
      lineNumber: asInt(map['line_number']),
      lineType: asInt(map['line_type']),
      itemCode: map['item_code']?.toString() ?? '',
      itemName: map['item_name']?.toString() ?? '',
      unitValue: map['unit']?.toString() ?? '',
      unitLabel: map['unit_label']?.toString(),
      quantity: map['quantity'] is num
          ? map['quantity'] as num
          : asInt(map['quantity']),
      unitPrice: asInt(map['unit_price']),
      taxRateValue: asInt(map['tax_rate']),
      lineTotal: asInt(map['line_total']),
      beforeDiscountAndTaxAmount: asInt(map['before_discount_and_tax_amount']),
    );
  }
}

class OrderInvoicePreviewSummary {
  const OrderInvoicePreviewSummary({
    required this.subtotal,
    required this.discount,
    required this.totalAfterDiscount,
    required this.orderTotal,
  });

  final int subtotal;
  final int discount;
  final int totalAfterDiscount;
  final int orderTotal;

  factory OrderInvoicePreviewSummary.fromJson(Map<String, dynamic> map) {
    return OrderInvoicePreviewSummary(
      subtotal: asInt(map['subtotal']),
      discount: asInt(map['discount']),
      totalAfterDiscount: asInt(map['total_after_discount']),
      orderTotal: asInt(map['order_total']),
    );
  }
}

class OrderInvoicePreviewDefaults {
  const OrderInvoicePreviewDefaults({
    required this.currency,
    required this.currencyValue,
    required this.taxRate,
    required this.isDraft,
  });

  final enums.InvoiceCurrency? currency;
  final String currencyValue;

  final enums.TaxRate? taxRate;
  final bool isDraft;

  factory OrderInvoicePreviewDefaults.fromJson(Map<String, dynamic> map) {
    final rawCurrency = map['currency']?.toString() ?? 'VND';
    return OrderInvoicePreviewDefaults(
      currencyValue: rawCurrency,
      currency: enums.InvoiceCurrency.fromValue(rawCurrency),
      taxRate: enums.TaxRate.fromValue(asInt(map['tax_rate'])),
      isDraft: map['is_draft'] == true || map['is_draft'] == 1,
    );
  }
}

/// Response `data` for `GET /order/{id}/invoice/preview`.
class OrderInvoicePreview {
  const OrderInvoicePreview({
    required this.orderId,
    required this.buyer,
    this.existingInvoice,
    required this.items,
    required this.summary,
    required this.defaults,
  });

  final int orderId;
  final InvoiceBuyer buyer;
  final OrderInvoiceExistingInvoice? existingInvoice;
  final List<OrderInvoicePreviewItem> items;
  final OrderInvoicePreviewSummary summary;
  final OrderInvoicePreviewDefaults defaults;

  factory OrderInvoicePreview.fromJson(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return OrderInvoicePreview(
      orderId: asInt(map['order_id']),
      buyer: InvoiceBuyer.fromJson(ensureMap(map['buyer'])),
      existingInvoice: map['existing_invoice'] != null
          ? OrderInvoiceExistingInvoice.fromJson(
              ensureMap(map['existing_invoice']),
            )
          : null,
      items: rawItems is List
          ? rawItems
                .map((e) => OrderInvoicePreviewItem.fromJson(ensureMap(e)))
                .toList(growable: false)
          : const [],
      summary: OrderInvoicePreviewSummary.fromJson(ensureMap(map['summary'])),
      defaults: OrderInvoicePreviewDefaults.fromJson(
        ensureMap(map['defaults']),
      ),
    );
  }
}
