class VietQrBusinessInfo {
  final String id;
  final String name;
  final String internationalName;
  final String shortName;
  final String address;
  final String status;

  const VietQrBusinessInfo({
    required this.id,
    required this.name,
    required this.internationalName,
    required this.shortName,
    required this.address,
    required this.status,
  });

  factory VietQrBusinessInfo.fromJson(Map<String, dynamic> json) {
    return VietQrBusinessInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      internationalName: json['internationalName']?.toString() ?? '',
      shortName: json['shortName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class VietQrBusinessResponse {
  final String code;
  final String desc;
  final VietQrBusinessInfo? data;

  const VietQrBusinessResponse({
    required this.code,
    required this.desc,
    this.data,
  });

  bool get isSuccess => code == '00';

  factory VietQrBusinessResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return VietQrBusinessResponse(
      code: json['code']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      data: dataJson != null && dataJson is Map<String, dynamic>
          ? VietQrBusinessInfo.fromJson(dataJson)
          : null,
    );
  }
}
