import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/global_search_screen.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/services/finacial_service.dart';
import 'package:fcode_pos/ui/dashboard/dashboard_components.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:flutter/material.dart';

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
  bool _isLoading = false;
  bool _isLoadingFinancial = false;
  String? _error;
  String? _financialError;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _financialService = FinacialService();
    _loadStats();
    _loadFinancialReport();
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

  List<_StatConfig> _getStatConfigs() {
    if (_stats == null) return [];

    final profitMargin = _stats!.revenue > 0
        ? ((_stats!.revenue - _stats!.totalMoney) / _stats!.revenue * 100)
              .toStringAsFixed(1)
        : '0.0';

    return [
      _StatConfig(
        icon: Icons.payments_outlined,
        title: 'Doanh thu',
        value: CurrencyHelper.formatCurrency(_stats!.revenue),
        subtitle: 'Tổng doanh thu trong khoảng thời gian',
        color: Colors.teal,
        trendLabel: null,
      ),
      _StatConfig(
        icon: Icons.attach_money_outlined,
        title: 'Tổng tiền',
        value: CurrencyHelper.formatCurrency(_stats!.totalMoney),
        subtitle: 'Biên lợi nhuận $profitMargin%',
        color: Colors.amber,
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

  static final _revenueTrend = [62.0, 85.0, 80.0, 94.0, 105.0, 98.0, 120.0];

  static final _profitTrend = [24.0, 30.0, 28.0, 34.0, 37.0, 32.0, 40.0];

  static final _recentActivities = [
    _Activity(
      title: 'Đơn hàng #FC-1024',
      subtitle: 'Nguyễn Văn A • 2 sản phẩm',
      amount: '₫4.200.000',
      leadingIcon: Icons.receipt_long_outlined,
      color: Colors.teal,
    ),
    _Activity(
      title: 'Nhập hàng từ Nhà cung cấp FutureTech',
      subtitle: '15 sản phẩm • Kho chính',
      amount: '₫12.450.000',
      leadingIcon: Icons.inventory_2_outlined,
      color: Colors.indigo,
    ),
    _Activity(
      title: 'Khách hàng mới: Lê Minh Tuấn',
      subtitle: 'Đăng ký từ Landing Page',
      amount: 'Gói Premium',
      leadingIcon: Icons.person_add_alt_1_outlined,
      color: Colors.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
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
                onRefresh: _loadStats,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê đơn hàng',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Tổng đơn',
                    value: '${report.orderStatistics.totalOrders}',
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.check_circle_outline,
                    label: 'Hoàn thành',
                    value: '${report.orderStatistics.completedOrders}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.verified_outlined,
                    label: 'Thành công',
                    value: '${report.orderStatistics.successfulOrders}',
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatisticCard(
                    icon: Icons.cancel_outlined,
                    label: 'Đã hủy',
                    value: '${report.orderStatistics.cancelledOrders}',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.amber.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giá trị trung bình/đơn',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyHelper.formatCurrency(
                              double.tryParse(
                                    report.orderStatistics.avgOrderValue,
                                  )?.toInt() ??
                                  0,
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
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

class _Activity {
  const _Activity({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.leadingIcon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData leadingIcon;
  final Color color;
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
