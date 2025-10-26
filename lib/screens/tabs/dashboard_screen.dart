import 'dart:math' as math;

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/global_search_screen.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/services/finacial_service.dart';
import 'package:fcode_pos/ui/dashboard/dashboard_components.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late OrderService _orderService;
  late FinacialService _financialService;
  OrderStats? _stats;
  FinancialReport? _financialReport;
  List<FinancialSummary> _monthlySummaries = [];
  bool _isLoading = false;
  bool _isLoadingFinancial = false;
  bool _isLoadingMonthly = false;
  String? _error;
  String? _financialError;
  String? _monthlyError;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _financialService = FinacialService();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _loadStats(),
      _loadFinancialReport(),
      _loadMonthlySummary(),
    ]);
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _orderService.stats(_fromDate, _toDate);
      if (!mounted) return;
      setState(() {
        _stats = response.data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFinancialReport() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFinancial = true;
      _financialError = null;
    });

    try {
      // Lấy ngày đầu và cuối của tháng được chọn
      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final lastDay = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );

      final response = await _financialService.report(
        fromDate: firstDay,
        toDate: lastDay,
      );
      if (!mounted) return;
      setState(() {
        _financialReport = response.data;
        _isLoadingFinancial = false;
      });
    } catch (e) {
      debugPrint('Error loading financial report: $e');
      if (!mounted) return;
      setState(() {
        _financialError = e.toString();
        _isLoadingFinancial = false;
      });
    }
  }

  Future<void> _loadMonthlySummary() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMonthly = true;
      _monthlyError = null;
    });

    try {
      final response = await _financialService.monthly();
      if (!mounted) return;
      final summaries = (response.data ?? [])
          .whereType<FinancialSummary>()
          .toList(growable: false);
      summaries.sort(
        (a, b) => _extractMonthKey(a).compareTo(_extractMonthKey(b)),
      );
      setState(() {
        _monthlySummaries = summaries;
        _isLoadingMonthly = false;
      });
    } catch (e) {
      debugPrint('Error loading monthly financial summary: $e');
      if (!mounted) return;
      setState(() {
        _monthlyError = e.toString();
        _isLoadingMonthly = false;
      });
    }
  }

  List<_StatConfig> _getStatConfigs() {
    if (_stats == null) return [];

    final profitMargin = _stats!.revenue > 0
        ? ((_stats!.totalMoney - _stats!.revenue) / _stats!.revenue * 100)
              .toStringAsFixed(1)
        : '0.0';

    return [
      _StatConfig(
        icon: Icons.attach_money_outlined,
        title: 'Doanh thu',
        value: CurrencyHelper.formatCurrency(_stats!.totalMoney),
        subtitle: 'Tổng doanh thu trong khoảng thời gian',
        color: Colors.amber,
        trendLabel: null,
      ),
      _StatConfig(
        icon: Icons.payments_outlined,
        title: 'Lợi nhuận',
        value: CurrencyHelper.formatCurrency(_stats!.revenue),
        subtitle: 'Biên lợi nhuận $profitMargin%',
        color: Colors.teal,
        trendLabel: null,
      ),
      _StatConfig(
        icon: Icons.shopping_bag_outlined,
        title: 'Đơn hàng',
        value: '${_stats!.totalOrdersCount}',
        subtitle:
            '${_stats!.completeOrderCount} hoàn thành, ${_stats!.newOrderCount} mới',
        color: Colors.indigo,
        trendLabel: null,
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );

    if (result != null && mounted) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
      });
      _loadStats();
    }
  }

  Future<void> _selectMonth() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Chọn tháng',
    );

    if (result != null && mounted) {
      setState(() {
        _selectedMonth = result;
      });
      _loadFinancialReport();
    }
  }

  String _formatMonth(DateTime date) {
    return 'Tháng ${date.month}/${date.year}';
  }

  int _extractMonthKey(FinancialSummary summary) {
    final startDate = DateTime.tryParse(summary.period.start);
    final month = summary.month?.toInt() ?? startDate?.month ?? 1;
    final year = startDate?.year ?? DateTime.now().year;
    return year * 100 + month;
  }

  List<_MonthlyRevenuePoint> _buildMonthlyRevenuePoints() {
    if (_monthlySummaries.isEmpty) return [];
    final now = DateTime.now();

    return _monthlySummaries
        .map((summary) {
          final startDate = DateTime.tryParse(summary.period.start);
          final month = summary.month?.toInt() ?? startDate?.month ?? 1;
          final year = startDate?.year ?? now.year;
          final date = DateTime(year, month);
          return _MonthlyRevenuePoint(
            revenue: summary.revenue.toDouble(),
            isCurrentMonth: date.month == now.month && date.year == now.year,
            month: month,
            year: year,
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalSearchScreen(),
                ),
              );
            },
            tooltip: 'Tìm kiếm',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _stats == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _stats == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Lỗi: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadStats,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Range Display
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: _selectDateRange,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Từ ${_formatDate(_fromDate)} đến ${_formatDate(_toDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final crossAxisCount = maxWidth > 900
                              ? 3
                              : maxWidth > 600
                              ? 2
                              : 1;

                          final spacing = 12.0;
                          final itemWidth = crossAxisCount == 1
                              ? maxWidth
                              : (maxWidth - spacing * (crossAxisCount - 1)) /
                                    crossAxisCount;

                          final statConfigs = _getStatConfigs();

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: statConfigs
                                .map(
                                  (config) => SizedBox(
                                    width: itemWidth,
                                    child: DashboardStatCard(
                                      icon: config.icon,
                                      title: config.title,
                                      value: config.value,
                                      subtitle: config.subtitle,
                                      color: config.color,
                                      trendLabel: config.trendLabel,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      DashboardSection(
                        title: 'Doanh thu theo tháng',
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Làm mới',
                          onPressed: _loadMonthlySummary,
                        ),
                        children: [
                          if (_isLoadingMonthly)
                            const _SectionLoadingCard()
                          else if (_monthlyError != null)
                            _SectionErrorCard(
                              message: _monthlyError!,
                              onRetry: _loadMonthlySummary,
                            )
                          else if (_monthlySummaries.isEmpty)
                            const _SectionEmptyCard(
                              message: 'Chưa có dữ liệu doanh thu theo tháng',
                            )
                          else
                            _MonthlyRevenueChart(
                              data: _buildMonthlyRevenuePoints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // DashboardTrendChart(
                      //   data: _revenueTrend,
                      //   color: Colors.teal,
                      //   title: 'Doanh thu theo tuần',
                      //   subtitle: 'Doanh thu 7 ngày gần nhất (triệu đồng)',
                      // ),
                      // const SizedBox(height: 12),
                      // DashboardTrendChart(
                      //   data: _profitTrend,
                      //   color: Colors.indigo,
                      //   title: 'Lợi nhuận gộp',
                      //   subtitle: 'Lợi nhuận trước thuế (triệu đồng)',
                      // ),
                      // const SizedBox(height: 20),
                      // DashboardSection(
                      //   title: 'Hoạt động gần đây',
                      //   children: _recentActivities
                      //       .map(
                      //         (activity) => Card(
                      //           elevation: 0,
                      //           margin: const EdgeInsets.only(bottom: 8),
                      //           child: ListTile(
                      //             contentPadding: const EdgeInsets.symmetric(
                      //               horizontal: 12,
                      //               vertical: 4,
                      //             ),
                      //             leading: Container(
                      //               padding: const EdgeInsets.all(8),
                      //               decoration: BoxDecoration(
                      //                 color: activity.color.withValues(
                      //                   alpha: 0.12,
                      //                 ),
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               child: Icon(
                      //                 activity.leadingIcon,
                      //                 color: activity.color,
                      //                 size: 20,
                      //               ),
                      //             ),
                      //             title: Text(
                      //               activity.title,
                      //               style: Theme.of(context)
                      //                   .textTheme
                      //                   .bodyMedium
                      //                   ?.copyWith(fontWeight: FontWeight.w600),
                      //             ),
                      //             subtitle: Text(
                      //               activity.subtitle,
                      //               style: Theme.of(
                      //                 context,
                      //               ).textTheme.bodySmall,
                      //             ),
                      //             trailing: Text(
                      //               activity.amount,
                      //               style: Theme.of(context)
                      //                   .textTheme
                      //                   .bodyMedium
                      //                   ?.copyWith(fontWeight: FontWeight.w600),
                      //             ),
                      //           ),
                      //         ),
                      //       )
                      //       .toList(),
                      // ),
                      // const SizedBox(height: 20),
                      // DashboardSection(
                      //   title: 'Nhắc việc',
                      //   trailing: TextButton(
                      //     onPressed: () {},
                      //     child: const Text('Xem tất cả'),
                      //   ),
                      //   children: [
                      //     _ReminderTile(
                      //       icon: Icons.pending_actions_outlined,
                      //       title: '5 đơn hàng đang chờ xác nhận',
                      //       subtitle:
                      //           'Kiểm tra và xác nhận trước 17:00 hôm nay',
                      //     ),
                      //     const SizedBox(height: 8),
                      //     _ReminderTile(
                      //       icon: Icons.warning_amber_outlined,
                      //       title: '2 sản phẩm sắp hết hàng',
                      //       subtitle:
                      //           'Apple Watch Series 9, Apple AirPods Pro – tồn kho < 5',
                      //     ),
                      //     const SizedBox(height: 8),
                      //     _ReminderTile(
                      //       icon: Icons.campaign_outlined,
                      //       title: 'Chiến dịch marketing tuần sau',
                      //       subtitle:
                      //           'Chuẩn bị nội dung và ngân sách cho tuần 42',
                      //     ),
                      //   ],
                      // ),
                      // const SizedBox(height: 20),
                      // Financial Report Section
                      DashboardSection(
                        title: 'Báo cáo tài chính',
                        trailing: TextButton.icon(
                          onPressed: _selectMonth,
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(_formatMonth(_selectedMonth)),
                        ),
                        children: [
                          if (_isLoadingFinancial)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_financialError != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 40,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Lỗi: $_financialError'),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _loadFinancialReport,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_financialReport != null)
                            _FinancialReportContent(report: _financialReport!)
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Không có dữ liệu'),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _FinancialReportContent extends StatelessWidget {
  const _FinancialReportContent({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Summary Card
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan tài chính',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                _FinancialRow(
                  label: 'Doanh thu',
                  value: CurrencyHelper.formatCurrency(
                    report.financialSummary.revenue.toInt(),
                  ),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _FinancialRow(
                  label: 'Chi phí',
                  value: CurrencyHelper.formatCurrency(
                    report.financialSummary.costs.toInt(),
                  ),
                  icon: Icons.trending_down,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                _FinancialRow(
                  label: 'Lợi nhuận gộp',
                  value: CurrencyHelper.formatCurrency(
                    report.financialSummary.grossProfit.toInt(),
                  ),
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _FinancialRow(
                  label: 'Lợi nhuận ròng',
                  value: CurrencyHelper.formatCurrency(
                    report.financialSummary.netProfit.toInt(),
                  ),
                  icon: Icons.savings,
                  color: Colors.teal,
                ),
                const SizedBox(height: 8),
                _FinancialRow(
                  label: 'Tỷ suất lợi nhuận',
                  value:
                      '${report.financialSummary.profitMargin.toStringAsFixed(2)}%',
                  icon: Icons.percent,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Order Statistics Card
        _OrderStatisticsCard(stats: report.orderStatistics),
        const SizedBox(height: 12),

        // Account renewal costs
        if (report.accountRenewalCosts.isNotEmpty) ...[
          Text(
            'Chi phí gia hạn tài khoản',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng ${CurrencyHelper.formatCurrency(report.accountRenewalCosts.fold<int>(0, (sum, item) => sum + item.totalAmount))}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...report.accountRenewalCosts.map(
            (cost) => _AccountRenewalCostTile(cost: cost),
          ),
          const SizedBox(height: 12),
        ],

        // Product Performance
        if (report.productPerformance.isNotEmpty) ...[
          Text(
            'Hiệu suất sản phẩm',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...report.productPerformance.map(
            (product) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  product.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('SKU: ${product.sku}'),
                    Text(
                      'Số đơn: ${product.orderCount} • Số lượng: ${product.totalQuantity}',
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.formatCurrency(
                        double.tryParse(product.totalRevenue)?.toInt() ?? 0,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TB: ${CurrencyHelper.formatCurrency(double.tryParse(product.avgPrice)?.toInt() ?? 0)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FinancialRow extends StatelessWidget {
  const _FinancialRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _StatConfig {
  const _StatConfig({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.trendLabel,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final String? trendLabel;
}

class _OrderStatisticsCard extends StatelessWidget {
  const _OrderStatisticsCard({required this.stats});

  final OrderStatistics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalOrders = stats.totalOrders;
    double rate(int value) =>
        totalOrders == 0 ? 0 : (value / totalOrders * 100);

    final successRate = rate(stats.successfulOrders);
    final completionRate = rate(stats.completedOrders);
    final cancelledRate = rate(stats.cancelledOrders);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thống kê đơn hàng',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$totalOrders đơn trong kỳ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        '${successRate.toStringAsFixed(1)}% thành công',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Hoàn thành ${completionRate.toStringAsFixed(1)}% • Đã hủy ${cancelledRate.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final double tileWidth = constraints.maxWidth >= 480
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _OrderStatTile(
                      width: tileWidth,
                      icon: Icons.shopping_bag_outlined,
                      label: 'Tổng đơn',
                      value: '${stats.totalOrders}',
                      color: Colors.indigo,
                    ),
                    _OrderStatTile(
                      width: tileWidth,
                      icon: Icons.task_alt_outlined,
                      label: 'Hoàn thành',
                      value: '${stats.completedOrders}',
                      color: Colors.green,
                      subtitle:
                          '${completionRate.toStringAsFixed(1)}% tổng đơn',
                    ),
                    _OrderStatTile(
                      width: tileWidth,
                      icon: Icons.verified_outlined,
                      label: 'Thành công',
                      value: '${stats.successfulOrders}',
                      color: Colors.teal,
                      subtitle: '${successRate.toStringAsFixed(1)}% tổng đơn',
                    ),
                    _OrderStatTile(
                      width: tileWidth,
                      icon: Icons.cancel_outlined,
                      label: 'Đã hủy',
                      value: '${stats.cancelledOrders}',
                      color: Colors.red,
                      subtitle: '${cancelledRate.toStringAsFixed(1)}% tổng đơn',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _OrderRevenueHighlight(
              totalValue: CurrencyHelper.formatCurrency(stats.totalRevenue),
              avgValue: CurrencyHelper.formatCurrency(stats.avgOrderValue),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatTile extends StatelessWidget {
  const _OrderStatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          color: color.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRevenueHighlight extends StatelessWidget {
  const _OrderRevenueHighlight({
    required this.totalValue,
    required this.avgValue,
  });

  final String totalValue;
  final String avgValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng doanh thu',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalValue,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giá trị trung bình',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  avgValue,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRenewalCostTile extends StatelessWidget {
  const _AccountRenewalCostTile({required this.cost});

  final AccountRenewalCosts cost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = CurrencyHelper.formatCurrency(cost.totalAmount);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lock_clock_outlined,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cost.serviceType,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${cost.transactions.length} giao dịch',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              total,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        children: cost.transactions.isEmpty
            ? [const Text('Không có giao dịch')]
            : cost.transactions
                .map(
                  (tx) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: const Icon(Icons.receipt_long, size: 18),
                    ),
                    title: Text(
                      tx.description.isNotEmpty
                          ? tx.description
                          : tx.transactionId,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(tx.createdAt)} • ${tx.status}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      CurrencyHelper.formatCurrency(tx.amount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _SectionLoadingCard extends StatelessWidget {
  const _SectionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionEmptyCard extends StatelessWidget {
  const _SectionEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              color: Theme.of(context).colorScheme.outline,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MonthlyRevenueChart extends StatelessWidget {
  const _MonthlyRevenueChart({required this.data});

  final List<_MonthlyRevenuePoint> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRevenue = data.fold<double>(
      0,
      (sum, point) => sum + point.revenue,
    );
    final maxRevenue = data.fold<double>(
      0,
      (value, point) => math.max(value, point.revenue),
    );
    final topPoint = data.reduce((a, b) => a.revenue >= b.revenue ? a : b);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Doanh thu 12 tháng ${data.isNotEmpty ? '${data.first.year}' : ''}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  CurrencyHelper.formatCurrency(totalRevenue.round()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Cao nhất: Tháng ${topPoint.month} (${CurrencyHelper.formatCompactCurrency(topPoint.revenue)})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data
                    .map(
                      (point) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _MonthlyRevenueBar(
                            point: point,
                            heightFactor: maxRevenue == 0
                                ? 0
                                : point.revenue / maxRevenue,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyRevenueBar extends StatelessWidget {
  const _MonthlyRevenueBar({required this.point, required this.heightFactor});

  final _MonthlyRevenuePoint point;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = point.isCurrentMonth
        ? theme.colorScheme.primary
        : theme.colorScheme.primaryContainer;
    final normalizedFactor = heightFactor.isFinite
        ? heightFactor.clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: -math.pi / 4,
              alignment: Alignment.center,
              child: Text(
                CurrencyHelper.formatCompactCurrency(point.revenue),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barHeight = constraints.maxHeight * normalizedFactor;
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: barHeight,
                  width: 16,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          point.month.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: point.isCurrentMonth
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MonthlyRevenuePoint {
  const _MonthlyRevenuePoint({
    required this.revenue,
    required this.isCurrentMonth,
    required this.month,
    required this.year,
  });

  final double revenue;
  final bool isCurrentMonth;
  final int month;
  final int year;
}
