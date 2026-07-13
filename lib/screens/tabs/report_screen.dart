import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/financial/financial_report_screen.dart';
import 'package:fcode_pos/screens/order/order_detail_screen.dart';
import 'package:fcode_pos/services/order_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/ui/dashboard/dashboard_components.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late OrderService _orderService;
  OrderStats? _stats;
  bool _isLoading = false;
  String? _error;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _loadStats();
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

  List<_OrderStatConfig> _getOrderStatConfigs() {
    if (_stats == null) return [];

    return [
      _OrderStatConfig(
        icon: Icons.check_circle_outlined,
        title: 'Đã thanh toán',
        count: _stats!.paymentSuccessOrderCount,
        gradient: const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _OrderStatConfig(
        icon: Icons.done_all_outlined,
        title: 'Hoàn thành',
        count: _stats!.completeOrderCount,
        gradient: const LinearGradient(
          colors: [Color(0xFF0cebeb), Color(0xFF20e3b2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _OrderStatConfig(
        icon: Icons.fiber_new_outlined,
        title: 'Đơn mới',
        count: _stats!.newOrderCount,
        gradient: const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _OrderStatConfig(
        icon: Icons.shopping_bag_outlined,
        title: 'Tổng đơn hàng',
        count: _stats!.totalOrdersCount,
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statValueStyle = theme.textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );

    return AppScaffold(
      title: 'Báo cáo',
      actions: [
        IconButton(
          tooltip: 'Báo cáo tài chính',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.bar_chart_outlined),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => const FinancialReportScreen(),
              ),
            );
          },
        ),
      ],
      body: (context, scrollController) =>
          _error != null && _stats == null
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
              : Column(
                  children: [
                    if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadStats,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: _isLoading ? null : _selectDateRange,
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
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Từ ${_formatDate(_fromDate)} đến ${_formatDate(_toDate)}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_isLoading && _stats == null)
                              const _DashboardSkeletonContent()
                            else ...[
                              if (_stats != null)
                                Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: GradientStatCard(
                                        title: 'Doanh thu',
                                        value: Text(
                                          CurrencyHelper.formatCurrency(
                                            _stats!.totalMoney,
                                          ),
                                          style: statValueStyle,
                                        ),
                                        percentage: '',
                                        icon: Icons.attach_money_outlined,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFf093fb),
                                            Color(0xFFf5576c),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: GradientStatCard(
                                        title: 'Lợi nhuận',
                                        value: Text(
                                          CurrencyHelper.formatCurrency(
                                            _stats!.revenue,
                                          ),
                                          style: statValueStyle,
                                        ),
                                        percentage: '',
                                        icon: Icons.payments_outlined,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF11998e),
                                            Color(0xFF38ef7d),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              LayoutBuilder(
                        builder: (context, constraints) {
                          final spacing = 12.0;

                          final orderStatConfigs = _getOrderStatConfigs();

                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: 1.8,
                                ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orderStatConfigs.length,
                            itemBuilder: (context, index) {
                              final config = orderStatConfigs[index];
                              return GradientStatCard(
                                title: config.title,
                                value: Text(
                                  '${config.count}',
                                  style: statValueStyle,
                                ),
                                percentage: '',
                                icon: config.icon,
                                gradient: config.gradient,
                              );
                            },
                          );
                        },
                              ),
                              const SizedBox(height: 20),
                              DashboardSection(
                                title: 'Đơn hàng sắp hết hạn',
                                children: [
                                  if (_stats?.ordersExpiringSoon == null ||
                                      _stats!.ordersExpiringSoon!.count == 0)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Không có đơn hàng sắp hết hạn',
                                        style:
                                            Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    )
                                  else
                                    ..._stats!.ordersExpiringSoon!.orders.map(
                                      (order) => Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailScreen(
                                          orderId: order.orderId.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.access_time,
                                                color: Colors.orange,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '#${order.orderId} - ${order.userName}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    order.userEmail,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                  Text(
                                                    '${order.itemsCount} sản phẩm',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        ...order.items.map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        item.daysRemaining == 0
                                                        ? Colors.red.withValues(
                                                            alpha: 0.15,
                                                          )
                                                        : Colors.orange
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    item.daysRemaining == 0
                                                        ? Icons.warning
                                                        : Icons.schedule,
                                                    size: 16,
                                                    color:
                                                        item.daysRemaining == 0
                                                        ? Colors.red
                                                        : Colors.orange,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item.productName,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                      ),
                                                      Text(
                                                        item.expiredAt != null
                                                            ? 'Hết hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(item.expiredAt!)}'
                                                            : 'Không xác định',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        item.daysRemaining == 0
                                                        ? Colors.red.withValues(
                                                            alpha: 0.15,
                                                          )
                                                        : Colors.orange
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: item.daysRemaining == 0
                                                      ? Text(
                                                          'Hôm nay',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: Colors
                                                                    .red
                                                                    .shade800,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        )
                                                      : Text(
                                                          '${item.daysRemaining} ngày',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                color: Colors
                                                                    .orange
                                                                    .shade800,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _DashboardSkeletonContent extends StatelessWidget {
  const _DashboardSkeletonContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatCardSkeleton(),
        SizedBox(height: 12),
        _StatCardSkeleton(),
        SizedBox(height: 16),
        _StatGridSkeleton(),
        SizedBox(height: 20),
        _SkeletonLine(height: 16, widthFactor: 0.48),
        SizedBox(height: 12),
        _ListTileSkeleton(),
        SizedBox(height: 12),
        _ListTileSkeleton(),
        SizedBox(height: 24),
      ],
    );
  }
}

class _StatGridSkeleton extends StatelessWidget {
  const _StatGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        final itemHeight = itemWidth / 1.8;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            4,
            (_) => SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: const _StatCardSkeleton(),
            ),
          ),
        );
      },
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SkeletonLine(height: 12, widthFactor: 0.42),
          SizedBox(height: 10),
          _SkeletonLine(height: 24, widthFactor: 0.58),
        ],
      ),
    );
  }
}

class _ListTileSkeleton extends StatelessWidget {
  const _ListTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _SkeletonBox(width: 40, height: 40, radius: 10),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(height: 14, widthFactor: 0.62),
                  SizedBox(height: 8),
                  _SkeletonLine(height: 12, widthFactor: 0.45),
                  SizedBox(height: 4),
                  _SkeletonLine(height: 12, widthFactor: 0.35),
                ],
              ),
            ),
            SizedBox(width: 12),
            _SkeletonBox(width: 20, height: 20, radius: 4),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.height, required this.widthFactor});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: _SkeletonBox(height: height),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _OrderStatConfig {
  const _OrderStatConfig({
    required this.icon,
    required this.title,
    required this.count,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final int count;
  final Gradient gradient;
}
