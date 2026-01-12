part of '../models.dart';

/// Top customer info
class TopCustomer {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final int ordersCount;

  TopCustomer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.ordersCount,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      id: asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      ordersCount: asInt(json['orders_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'orders_count': ordersCount,
    };
  }
}

/// Customer statistics
class CustomerStats {
  final int totalUsers;
  final int newUsersLast30Days;
  final int customersWithOrders;
  final List<TopCustomer> top10CustomersThisYear;

  CustomerStats({
    required this.totalUsers,
    required this.newUsersLast30Days,
    required this.customersWithOrders,
    required this.top10CustomersThisYear,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    final top10 =
        (json['top_10_customers_this_year'] as List?)
            ?.map((item) => TopCustomer.fromJson(ensureMap(item)))
            .toList(growable: false) ??
        [];

    return CustomerStats(
      totalUsers: asInt(json['total_users']),
      newUsersLast30Days: asInt(json['new_users_last_30_days']),
      customersWithOrders: asInt(json['customers_with_orders']),
      top10CustomersThisYear: top10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'new_users_last_30_days': newUsersLast30Days,
      'customers_with_orders': customersWithOrders,
      'top_10_customers_this_year': top10CustomersThisYear
          .map((customer) => customer.toJson())
          .toList(),
    };
  }
}
