import 'package:fcode_pos/enums/buyer_type.dart';

class CustomerCreateData {
  final String name;
  final String email;
  final String? password;
  final String? facebookUrl;
  final String? phone;
  final BuyerType buyerType;
  final String? legalName;
  final String? taxCode;
  final String? address;
  final String? buyerCode;
  final String? nationalId;
  final String? invoiceEmail;
  final bool? invoiceProfileComplete;
  final String? invoiceProfileCompletedAt;

  CustomerCreateData({
    required this.name,
    required this.email,
    required this.buyerType,
    this.password,
    this.facebookUrl,
    this.phone,
    this.legalName,
    this.taxCode,
    this.address,
    this.buyerCode,
    this.nationalId,
    this.invoiceEmail,
    this.invoiceProfileComplete,
    this.invoiceProfileCompletedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (facebookUrl != null && facebookUrl!.isNotEmpty)
        'facebook_url': facebookUrl,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'buyer_type': buyerType.value,
      if (legalName != null && legalName!.isNotEmpty) 'legal_name': legalName,
      if (taxCode != null && taxCode!.isNotEmpty) 'tax_code': taxCode,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (buyerCode != null && buyerCode!.isNotEmpty) 'buyer_code': buyerCode,
      if (nationalId != null && nationalId!.isNotEmpty)
        'national_id': nationalId,
      if (invoiceEmail != null && invoiceEmail!.isNotEmpty)
        'invoice_email': invoiceEmail,
      if (invoiceProfileComplete != null)
        'invoice_profile_complete': invoiceProfileComplete,
      if (invoiceProfileCompletedAt != null)
        'invoice_profile_completed_at': invoiceProfileCompletedAt,
    };
  }
}
