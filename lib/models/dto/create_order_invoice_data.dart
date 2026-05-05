import 'package:fcode_pos/enums.dart';

/// Body `POST /order/{id}/invoice` — khớp rule Laravel.
class CreateOrderInvoiceData {
  CreateOrderInvoiceData({
    required this.providerAccountId,
    required this.templateCode,
    required this.invoiceSeries,
    this.issuedDate,
    this.currency,
    this.paymentMethod,
    this.isDraft,
    this.taxRate,
    this.notes,
  });

  final String providerAccountId;
  final String templateCode;
  final String invoiceSeries;
  final String? issuedDate;
  final InvoiceCurrency? currency;
  final InvoicePaymentMethod? paymentMethod;
  final bool? isDraft;
  final TaxRate? taxRate;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'provider_account_id': providerAccountId,
      'template_code': templateCode,
      'invoice_series': invoiceSeries,
      if (issuedDate != null && issuedDate!.isNotEmpty)
        'issued_date': issuedDate,
      if (currency != null) 'currency': currency!.value,
      if (paymentMethod != null) 'payment_method': paymentMethod!.value,
      if (isDraft != null) 'is_draft': isDraft,
      if (taxRate != null) 'tax_rate': taxRate!.value,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }
}
