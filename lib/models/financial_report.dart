part of '../models.dart';

class FinancialReport {
  const FinancialReport({
    required this.period,
    required this.financialSummary,
    required this.orderStatistics,
    required this.productPerformance,
    required this.accountRenewalCosts,
    required this.generatedAt,
  });

  final Period period;
  final FinancialSummary financialSummary;
  final OrderStatistics orderStatistics;
  final List<ProductPerformance> productPerformance;
  final List<AccountRenewalCosts> accountRenewalCosts;
  final String generatedAt;

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      period: Period.fromJson(ensureMap(json['period'])),
      financialSummary: FinancialSummary.fromJson(
        ensureMap(json['financial_summary']),
      ),
      orderStatistics: OrderStatistics.fromJson(
        ensureMap(json['order_statistics']),
      ),
      productPerformance:
          (json['product_performance'] as List?)
              ?.map((e) => ProductPerformance.fromJson(ensureMap(e)))
              .toList() ??
          [],
      accountRenewalCosts:
          (json['account_renewal_costs'] as List?)
              ?.map((e) => AccountRenewalCosts.fromJson(ensureMap(e)))
              .toList() ??
          [],
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period.toMap(),
      'financial_summary': financialSummary.toMap(),
      'order_statistics': orderStatistics.toMap(),
      'product_performance': productPerformance.map((e) => e.toMap()).toList(),
      'account_renewal_costs': accountRenewalCosts,
      'generated_at': generatedAt,
    };
  }
}

class Period {
  const Period({required this.start, required this.end});

  final String start;
  final String end;

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'start': start, 'end': end};
  }
}

class FinancialSummary {
  const FinancialSummary({
    required this.period,
    required this.revenue,
    required this.expenses,
    required this.refunds,
    required this.costs,
    required this.fees,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.month,
    required this.monthName,
  });

  final Period period;
  final num revenue;
  final num expenses;
  final num refunds;
  final num costs;
  final num fees;
  final num grossProfit;
  final num netProfit;
  final num profitMargin;
  final num? month;
  final String monthName;

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      period: Period.fromJson(ensureMap(json['period'])),
      revenue: asInt(json['revenue']),
      expenses: asInt(json['expenses']),
      refunds: asInt(json['refunds']),
      costs: asInt(json['costs']),
      fees: asInt(json['fees']),
      grossProfit: asInt(json['gross_profit']),
      netProfit: asInt(json['net_profit']),
      profitMargin: asInt(json['profit_margin']),
      month: asIntOrNull(json['month']),
      monthName: json['month_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period.toMap(),
      'revenue': revenue,
      'expenses': expenses,
      'refunds': refunds,
      'costs': costs,
      'fees': fees,
      'gross_profit': grossProfit,
      'net_profit': netProfit,
      'profit_margin': profitMargin,
      'month': month,
      'month_name': monthName,
    };
  }
}

class OrderStatistics {
  const OrderStatistics({
    required this.totalOrders,
    required this.successfulOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.refundedOrders,
    required this.totalRevenue,
    required this.avgOrderValue,
  });

  final int totalOrders;
  final int successfulOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int refundedOrders;
  final int totalRevenue;
  final int avgOrderValue;

  factory OrderStatistics.fromJson(Map<String, dynamic> json) {
    return OrderStatistics(
      totalOrders: asInt(json['total_orders']),
      successfulOrders: asInt(json['successful_orders']),
      completedOrders: asInt(json['completed_orders']),
      cancelledOrders: asInt(json['cancelled_orders']),
      refundedOrders: asInt(json['refunded_orders']),
      totalRevenue: asInt(json['total_revenue']),
      avgOrderValue: asInt(json['avg_order_value']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_orders': totalOrders,
      'successful_orders': successfulOrders,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'refunded_orders': refundedOrders,
      'total_revenue': totalRevenue,
      'avg_order_value': avgOrderValue,
    };
  }
}

class ProductPerformance {
  const ProductPerformance({
    required this.id,
    required this.name,
    required this.sku,
    required this.orderCount,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.avgPrice,
  });

  final int id;
  final String name;
  final String sku;
  final int orderCount;
  final String totalQuantity;
  final String totalRevenue;
  final String avgPrice;

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      id: asInt(json['id']),
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      orderCount: asInt(json['order_count']),
      totalQuantity: json['total_quantity']?.toString() ?? '0',
      totalRevenue: json['total_revenue']?.toString() ?? '0',
      avgPrice: json['avg_price']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'order_count': orderCount,
      'total_quantity': totalQuantity,
      'total_revenue': totalRevenue,
      'avg_price': avgPrice,
    };
  }
}

class AccountRenewalCosts {
  const AccountRenewalCosts({
    required this.serviceType,
    required this.totalAmount,
    required this.transactions,
  });

  final String serviceType;
  final int totalAmount;
  final List<Transaction> transactions;

  factory AccountRenewalCosts.fromJson(Map<String, dynamic> json) {
    return AccountRenewalCosts(
      serviceType: json['service_type'] as String? ?? '',
      totalAmount: asInt(json['total_amount']),
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map((item) => Transaction.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_type': serviceType,
      'total_amount': totalAmount,
      'transactions': transactions.map((item) => item.toMap()).toList(),
    };
  }
}

class Transaction {
  const Transaction({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.category,
    required this.status,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String transactionId;
  final String type;
  final String category;
  final String status;
  final int amount;
  final String description;
  final DateTime createdAt;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: asInt(json['id']),
      transactionId: json['transaction_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: asInt(json['amount']),
      description: json['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'type': type,
      'category': category,
      'status': status,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
