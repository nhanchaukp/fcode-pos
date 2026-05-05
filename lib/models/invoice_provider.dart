part of '../models.dart';

/// An invoice template belonging to a provider account.
class InvoiceTemplate {
  const InvoiceTemplate({
    required this.templateCode,
    required this.invoiceSeries,
    required this.invoiceLabel,
  });

  final String templateCode;
  final String invoiceSeries;
  final String invoiceLabel;

  factory InvoiceTemplate.fromJson(Map<String, dynamic> map) {
    return InvoiceTemplate(
      templateCode: map['template_code']?.toString() ?? '',
      invoiceSeries: map['invoice_series']?.toString() ?? '',
      invoiceLabel: map['invoice_label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'template_code': templateCode,
    'invoice_series': invoiceSeries,
    'invoice_label': invoiceLabel,
  };
}

/// Invoice provider account — returned in both list and detail.
/// [templates] is only populated in the detail response.
class InvoiceProviderAccount {
  const InvoiceProviderAccount({
    required this.id,
    required this.provider,
    required this.active,
    this.templates,
  });

  final String id;
  final String provider;
  final bool active;

  /// Non-null only when fetched via the detail endpoint.
  final List<InvoiceTemplate>? templates;

  factory InvoiceProviderAccount.fromJson(Map<String, dynamic> map) {
    final rawTemplates = map['templates'];
    return InvoiceProviderAccount(
      id: map['id']?.toString() ?? '',
      provider: map['provider']?.toString() ?? '',
      active: map['active'] == true || map['active'] == 1,
      templates: rawTemplates is List
          ? rawTemplates
              .map((e) => InvoiceTemplate.fromJson(ensureMap(e)))
              .toList(growable: false)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'provider': provider,
    'active': active,
    if (templates != null)
      'templates': templates!.map((e) => e.toMap()).toList(),
  };
}

/// Remaining invoice quota for the account.
class InvoiceQuota {
  const InvoiceQuota({
    required this.quotaRemaining,
    this.taxAuthorityApprovedDate,
  });

  final int quotaRemaining;
  final DateTime? taxAuthorityApprovedDate;

  factory InvoiceQuota.fromJson(Map<String, dynamic> map) {
    return InvoiceQuota(
      quotaRemaining: asInt(map['quota_remaning']),
      taxAuthorityApprovedDate: map['tax_authority_approved_date'] != null
          ? DateTime.tryParse(map['tax_authority_approved_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'quota_remaning': quotaRemaining,
    'tax_authority_approved_date':
        taxAuthorityApprovedDate?.toIso8601String(),
  };
}
