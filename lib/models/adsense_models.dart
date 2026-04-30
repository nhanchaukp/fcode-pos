// Các giá trị hợp lệ của ReportingDateRange trong AdSense Management API v2:
// TODAY, YESTERDAY, LAST_7_DAYS, LAST_30_DAYS, MONTH_TO_DATE, YEAR_TO_DATE, CUSTOM
enum AdsenseDateRange {
  today('TODAY', 'Hôm nay'),
  yesterday('YESTERDAY', 'Hôm qua'),
  last7Days('LAST_7_DAYS', '7 ngày'),
  last30Days('LAST_30_DAYS', '30 ngày'),
  monthToDate('MONTH_TO_DATE', 'Tháng này'),
  yearToDate('YEAR_TO_DATE', 'Năm nay'),
  custom('CUSTOM', 'Tùy chỉnh');

  const AdsenseDateRange(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum AdsenseDimension {
  date('DATE', 'Ngày'),
  week('WEEK', 'Tuần'),
  month('MONTH', 'Tháng'),
  country('COUNTRY_NAME', 'Quốc gia'),
  ownedSiteDomain('OWNED_SITE_DOMAIN_NAME', 'Trang web'),
  adUnit('AD_UNIT_NAME', 'Đơn vị QC'),
  platform('PLATFORM_TYPE_NAME', 'Nền tảng');

  const AdsenseDimension(this.apiValue, this.label);

  final String apiValue;
  final String label;

  bool get isTemporal =>
      this == AdsenseDimension.date ||
      this == AdsenseDimension.week ||
      this == AdsenseDimension.month;
}

class AdsenseAccount {
  const AdsenseAccount({
    required this.name,
    required this.displayName,
    this.premium = false,
  });

  final String name;
  final String displayName;
  final bool premium;

  String get publisherId => name.split('/').last;

  factory AdsenseAccount.fromJson(Map<String, dynamic> json) {
    return AdsenseAccount(
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      premium: json['premium'] as bool? ?? false,
    );
  }
}

class AdsenseReportRow {
  const AdsenseReportRow({
    required this.dimensionValue,
    required this.estimatedEarnings,
    required this.pageViews,
    required this.clicks,
    required this.pageRpm,
    required this.impressions,
    required this.ctr,
    required this.cpc,
  });

  final String dimensionValue;
  final double estimatedEarnings;
  final int pageViews;
  final int clicks;
  final double pageRpm;
  final int impressions;
  // PAGE_VIEWS_CTR — tỉ lệ nhấp/lượt xem (0.005 = 0.5%)
  final double ctr;
  // COST_PER_CLICK — giá mỗi nhấp chuột
  final double cpc;

  factory AdsenseReportRow.fromCells(List<dynamic> cells) {
    String cellStr(int i) =>
        (cells.length > i ? cells[i] as Map? : null)?['value']?.toString() ?? '';
    double d(int i) => double.tryParse(cellStr(i)) ?? 0;
    int n(int i) => int.tryParse(cellStr(i)) ?? 0;

    return AdsenseReportRow(
      dimensionValue: cellStr(0),
      estimatedEarnings: d(1),
      pageViews: n(2),
      clicks: n(3),
      pageRpm: d(4),
      impressions: n(5),
      ctr: d(6),
      cpc: d(7),
    );
  }
}

/// Dữ liệu hiệu suất: 6 chỉ số cho section Hiệu suất.
class AdsensePerformanceData {
  const AdsensePerformanceData({
    required this.pageViews,
    required this.pageRpm,
    required this.impressions,
    required this.clicks,
    required this.cpc,
    required this.ctr,
  });

  final int pageViews;
  final double pageRpm;
  final int impressions;
  final int clicks;
  final double cpc;
  // PAGE_VIEWS_CTR (0.05 = 5%)
  final double ctr;

  static const empty = AdsensePerformanceData(
    pageViews: 0,
    pageRpm: 0,
    impressions: 0,
    clicks: 0,
    cpc: 0,
    ctr: 0,
  );

  // Thứ tự cells khớp với _performanceMetrics trong service (không có dimension):
  // [0]=PAGE_VIEWS, [1]=PAGE_VIEWS_RPM, [2]=IMPRESSIONS,
  // [3]=CLICKS, [4]=COST_PER_CLICK, [5]=PAGE_VIEWS_CTR
  factory AdsensePerformanceData.fromCells(List<dynamic> cells) {
    String cellStr(int i) =>
        (cells.length > i ? cells[i] as Map? : null)?['value']?.toString() ?? '';
    double d(int i) => double.tryParse(cellStr(i)) ?? 0;
    int n(int i) => int.tryParse(cellStr(i)) ?? 0;

    return AdsensePerformanceData(
      pageViews: n(0),
      pageRpm: d(1),
      impressions: n(2),
      clicks: n(3),
      cpc: d(4),
      ctr: d(5),
    );
  }
}

/// Thu nhập ước tính theo 4 khoảng thời gian nhanh.
class AdsenseEarningsOverview {
  const AdsenseEarningsOverview({
    required this.today,
    required this.yesterday,
    required this.last7Days,
    required this.thisMonth,
  });

  final double today;
  final double yesterday;
  final double last7Days;
  final double thisMonth;
}

/// Một bản ghi thanh toán từ API payments.
class AdsensePayment {
  const AdsensePayment({
    required this.name,
    required this.paymentAmount,
    required this.currencyCode,
    this.date,
  });

  final String name;
  /// Số tiền đã format sẵn, ví dụ: "USD 1,234.56"
  final String paymentAmount;
  final String currencyCode;
  final DateTime? date;

  /// true nếu đây là số dư chưa thanh toán (tên chứa "/unpaid")
  bool get isUnpaid => name.contains('/unpaid');

  factory AdsensePayment.fromJson(Map<String, dynamic> json) {
    final dateJson = json['date'] as Map<String, dynamic>?;
    DateTime? date;
    if (dateJson != null) {
      date = DateTime(
        dateJson['year'] as int? ?? 2024,
        dateJson['month'] as int? ?? 1,
        dateJson['day'] as int? ?? 1,
      );
    }
    return AdsensePayment(
      name: json['name'] as String? ?? '',
      paymentAmount: json['paymentAmount'] as String? ?? '',
      currencyCode: json['paymentAmountCurrencyCode'] as String? ?? 'USD',
      date: date,
    );
  }
}

class AdsenseReport {
  const AdsenseReport({
    required this.rows,
    this.totals,
    required this.currencyCode,
  });

  final List<AdsenseReportRow> rows;
  final AdsenseReportRow? totals;
  final String currencyCode;

  factory AdsenseReport.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    final rows = rawRows.map((r) {
      final cells = (r as Map<String, dynamic>)['cells'] as List<dynamic>? ?? [];
      return AdsenseReportRow.fromCells(cells);
    }).toList();

    AdsenseReportRow? totals;
    final rawTotals = json['totals'] as Map<String, dynamic>?;
    if (rawTotals != null) {
      final cells = rawTotals['cells'] as List<dynamic>? ?? [];
      if (cells.isNotEmpty) {
        totals = AdsenseReportRow.fromCells(cells);
      }
    }

    return AdsenseReport(
      rows: rows,
      totals: totals,
      currencyCode: json['responseCurrencyCode'] as String? ?? 'USD',
    );
  }
}
