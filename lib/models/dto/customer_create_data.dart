class CustomerCreateData {
  final String name;
  final String email;
  final String? password;
  final String? facebook;
  final String? phone;

  CustomerCreateData({
    required this.name,
    required this.email,
    this.password,
    this.facebook,
    this.phone,
  });

  factory CustomerCreateData.fromJson(Map<String, dynamic> json) {
    return CustomerCreateData(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String?,
      facebook: json['facebook'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (password != null) 'password': password,
      if (facebook != null) 'facebook': facebook,
      if (phone != null) 'phone': phone,
    };
  }
}
