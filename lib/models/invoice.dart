part of '../models.dart';

/// Buyer information on an invoice.
class InvoiceBuyer {
  const InvoiceBuyer({
    required this.name,
    this.taxCode,
    this.address,
    this.email,
    this.phone,
  });

  final String name;
  final String? taxCode;
  final String? address;
  final String? email;
  final String? phone;

  factory InvoiceBuyer.fromJson(Map<String, dynamic> map) {
    return InvoiceBuyer(
      name: map['name']?.toString() ?? '',
      taxCode: map['tax_code']?.toString(),
      address: map['address']?.toString(),
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'tax_code': taxCode,
    'address': address,
    'email': email,
    'phone': phone,
  };
}

/// A single line item on an invoice (only present in detail response).
class InvoiceItem {
  const InvoiceItem({
    required this.lineNumber,
    required this.lineType,
    required this.itemName,
    this.itemCode,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.taxRate,
    required this.taxAmount,
  });

  final int lineNumber;
  final int lineType;
  final String itemName;
  final String? itemCode;
  final String? unit;

  /// Stored as string to preserve decimal precision from the API.
  final String quantity;
  final String unitPrice;
  final String totalAmount;
  final String taxRate;
  final String taxAmount;

  double get quantityValue => double.tryParse(quantity) ?? 0;
  double get unitPriceValue => double.tryParse(unitPrice) ?? 0;
  double get totalAmountValue => double.tryParse(totalAmount) ?? 0;
  double get taxRateValue => double.tryParse(taxRate) ?? 0;
  double get taxAmountValue => double.tryParse(taxAmount) ?? 0;

  factory InvoiceItem.fromJson(Map<String, dynamic> map) {
    return InvoiceItem(
      lineNumber: asInt(map['line_number']),
      lineType: asInt(map['line_type']),
      itemName: map['item_name']?.toString() ?? '',
      itemCode: map['item_code']?.toString(),
      unit: map['unit']?.toString(),
      quantity: map['quantity']?.toString() ?? '0',
      unitPrice: map['unit_price']?.toString() ?? '0',
      totalAmount: map['total_amount']?.toString() ?? '0',
      taxRate: map['tax_rate']?.toString() ?? '0',
      taxAmount: map['tax_amount']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() => {
    'line_number': lineNumber,
    'line_type': lineType,
    'item_name': itemName,
    'item_code': itemCode,
    'unit': unit,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_amount': totalAmount,
    'tax_rate': taxRate,
    'tax_amount': taxAmount,
  };
}

/// Invoice — both list and detail share the same model.
/// [items] is only populated in the detail response.
class Invoice {
  const Invoice({
    required this.referenceCode,
    required this.invoiceNumber,
    required this.issuedDate,
    this.pdfUrl,
    this.xmlUrl,
    required this.status,
    required this.buyer,
    required this.totalBeforeTax,
    required this.taxAmount,
    required this.totalAmount,
    this.notes,
    this.items,
  });

  final String referenceCode;
  final String invoiceNumber;
  final DateTime issuedDate;
  final String? pdfUrl;
  final String? xmlUrl;

  /// Known values: draft, issued, cancelled. May extend in the future.
  final String status;

  final InvoiceBuyer buyer;
  final int totalBeforeTax;
  final int taxAmount;
  final int totalAmount;
  final String? notes;

  /// Non-null only when fetched via the detail endpoint.
  final List<InvoiceItem>? items;

  bool get isDraft => status == 'draft';
  bool get isIssued => status == 'issued';
  bool get isCancelled => status == 'cancelled';

  factory Invoice.fromJson(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return Invoice(
      referenceCode: map['reference_code']?.toString() ?? '',
      invoiceNumber: map['invoice_number']?.toString() ?? '',
      issuedDate: _parseDate(map['issued_date']?.toString()),
      pdfUrl: map['pdf_url']?.toString(),
      xmlUrl: map['xml_url']?.toString(),
      status: map['status']?.toString() ?? '',
      buyer: InvoiceBuyer.fromJson(
        ensureMap(map['buyer']),
      ),
      totalBeforeTax: asInt(map['total_before_tax']),
      taxAmount: asInt(map['tax_amount']),
      totalAmount: asInt(map['total_amount']),
      notes: map['notes']?.toString(),
      items: rawItems is List
          ? rawItems
              .map((e) => InvoiceItem.fromJson(ensureMap(e)))
              .toList(growable: false)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'reference_code': referenceCode,
    'invoice_number': invoiceNumber,
    'issued_date':
        '${issuedDate.year}-${issuedDate.month.toString().padLeft(2, '0')}-${issuedDate.day.toString().padLeft(2, '0')}',
    'pdf_url': pdfUrl,
    'xml_url': xmlUrl,
    'status': status,
    'buyer': buyer.toMap(),
    'total_before_tax': totalBeforeTax,
    'tax_amount': taxAmount,
    'total_amount': totalAmount,
    'notes': notes,
    if (items != null) 'items': items!.map((e) => e.toMap()).toList(),
  };

  static DateTime _parseDate(String? raw) {
    if (raw == null) return DateTime(1970);
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime(1970);
    }
  }
}
