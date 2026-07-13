import 'dart:math' as math;

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/finacial_service.dart';
import 'package:fcode_pos/ui/components/animated_stat_text.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/dashboard/dashboard_components.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

enum _ReportPeriodType {
  currentMonth,
  quarter1,
  quarter2,
  quarter3,
  quarter4,
  fullYear,
  custom,
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  late FinacialService _financialService;
  FinancialReport? _financialReport;
  List<FinancialSummary> _monthlySummaries = [];
  bool _isLoadingFinancial = false;
  bool _isLoadingMonthly = false;
  String? _financialError;
  String? _monthlyError;
  _ReportRange _selectedRange = _ReportRange.currentMonth();
  _ReportPeriodType _selectedPeriodType = _ReportPeriodType.currentMonth;

  @override
  void initState() {
    super.initState();
    _financialService = FinacialService();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadFinancialReport(), _loadMonthlySummary()]);
  }

  Future<void> _loadFinancialReport() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFinancial = true;
      _financialError = null;
    });

    try {
      final response = await _financialService.report(
        fromDate: _selectedRange.startDate,
        toDate: _selectedRange.endDate,
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

  Future<void> _selectReportPeriod() async {
    final now = DateTime.now();
    final year = now.year;
    final initialPresetRange = _buildPresetRange(_selectedPeriodType, year);
    var selectedType = _selectedPeriodType;
    var startDate = initialPresetRange?.startDate ?? _selectedRange.startDate;
    var endDate = initialPresetRange?.endDate ?? _selectedRange.endDate;

    final selection = await showDialog<_ReportPeriodSelection>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isCustom = selectedType == _ReportPeriodType.custom;
            return AlertDialog(
              title: const Text('Chọn kỳ báo cáo'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PeriodRadioTile(
                        title: 'Tháng hiện tại',
                        value: _ReportPeriodType.currentMonth,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value == null) return;
                          final range = _buildPresetRange(value, year);
                          if (range == null) return;
                          setDialogState(() {
                            selectedType = value;
                            startDate = range.startDate;
                            endDate = range.endDate;
                          });
                        },
                      ),
                      _PeriodRadioTile(
                        title: 'Quý 1',
                        value: _ReportPeriodType.quarter1,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value == null) return;
                          final range = _buildPresetRange(value, year);
                          if (range == null) return;
                          setDialogState(() {
                            selectedType = value;
                            startDate = range.startDate;
                            endDate = range.endDate;
                          });
                        },
                      ),
                      _PeriodRadioTile(
                        title: 'Quý 2',
                        value: _ReportPeriodType.quarter2,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value == null) return;
                          final range = _buildPresetRange(value, year);
                          if (range == null) return;
                          setDialogState(() {
                            selectedType = value;
                            startDate = range.startDate;
                            endDate = range.endDate;
                          });
                        },
                      ),
                      _PeriodRadioTile(
                        title: 'Quý 3',
                        value: _ReportPeriodType.quarter3,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value == null) return;
                          final range = _buildPresetRange(value, year);
                          if (range == null) return;
                          setDialogState(() {
                            selectedType = value;
                            startDate = range.startDate;
                            endDate = range.endDate;
                          });
                        },
                      ),
                      _PeriodRadioTile(
                        title: 'Quý 4',
                        value: _ReportPeriodType.quarter4,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value == null) return;
                          final range = _buildPresetRange(value, year);
                          if (range == null) return;
                          setDialogState(() {
                            selectedType = value;
                            startDate = range.startDate;
                            endDate = range.endDate;
                          });
                        },
                      ),
                      _PeriodRadioTile(
                        title: 'Cả năm',
                        value: _ReportPeriodType.fullYear,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value == null) return;
                          final range = _buildPresetRange(value, year);
                          if (range == null) return;
                          setDialogState(() {
                            selectedType = value;
                            startDate = range.startDate;
                            endDate = range.endDate;
                          });
                        },
                      ),
                      _PeriodRadioTile(
                        title: 'Tùy chỉnh',
                        value: _ReportPeriodType.custom,
                        groupValue: selectedType,
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedType = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      _DateInputTile(
                        label: 'Start date',
                        value: startDate,
                        enabled: isCustom,
                        onTap: () async {
                          final picked = await _pickDate(startDate);
                          if (picked == null) return;
                          setDialogState(() {
                            startDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _DateInputTile(
                        label: 'End date',
                        value: endDate,
                        enabled: isCustom,
                        onTap: () async {
                          final picked = await _pickDate(endDate);
                          if (picked == null) return;
                          setDialogState(() {
                            endDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              23,
                              59,
                              59,
                            );
                            if (endDate.isBefore(startDate)) {
                              startDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    final range = _ReportRange(
                      label: selectedType == _ReportPeriodType.custom
                          ? _buildCustomLabel(startDate, endDate)
                          : (_buildPresetRange(selectedType, year)?.label ??
                                _buildCustomLabel(startDate, endDate)),
                      startDate: startDate,
                      endDate: endDate,
                    );
                    Navigator.pop(
                      context,
                      _ReportPeriodSelection(type: selectedType, range: range),
                    );
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selection == null || !mounted) return;

    setState(() {
      _selectedPeriodType = selection.type;
      _selectedRange = selection.range;
    });
    _loadFinancialReport();
  }

  _ReportRange? _buildPresetRange(_ReportPeriodType type, int year) {
    switch (type) {
      case _ReportPeriodType.currentMonth:
        return _ReportRange.currentMonth();
      case _ReportPeriodType.quarter1:
        return _ReportRange.forQuarter(year, 1);
      case _ReportPeriodType.quarter2:
        return _ReportRange.forQuarter(year, 2);
      case _ReportPeriodType.quarter3:
        return _ReportRange.forQuarter(year, 3);
      case _ReportPeriodType.quarter4:
        return _ReportRange.forQuarter(year, 4);
      case _ReportPeriodType.fullYear:
        return _ReportRange.fullYear(year);
      case _ReportPeriodType.custom:
        return null;
    }
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày',
    );
  }

  String _buildCustomLabel(DateTime startDate, DateTime endDate) {
    final formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }

  String _formatSelectedRange() => _selectedRange.label;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Báo cáo tài chính',
      subtitle: _formatSelectedRange(),
      actions: [
        IconButton(
          tooltip: 'Chọn kỳ báo cáo',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.calendar_month),
          onPressed: _selectReportPeriod,
        ),
      ],
      body: (context, scrollController) => RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Revenue Chart Section
              DashboardSection(
                title: 'Doanh thu theo tháng',
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Làm mới',
                  onPressed: _loadMonthlySummary,
                ),
                children: [
                  if (_isLoadingMonthly)
                    const _MonthlyRevenueChartSkeleton()
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
                    _MonthlyRevenueChart(data: _buildMonthlyRevenuePoints()),
                ],
              ),
              const SizedBox(height: 24),

              // Financial Report Detail Section
              DashboardSection(
                title: 'Báo cáo chi tiết',
                children: [
                  if (_isLoadingFinancial)
                    const _FinancialReportSkeleton()
                  else if (_financialError != null)
                    _SectionErrorCard(
                      message: _financialError!,
                      onRetry: _loadFinancialReport,
                    )
                  else if (_financialReport != null)
                    _FinancialReportContent(report: _financialReport!)
                  else
                    const _SectionEmptyCard(message: 'Không có dữ liệu'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Classes

class _FinancialReportContent extends StatelessWidget {
  const _FinancialReportContent({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = report.financialSummary;
    final revenue = summary.revenue.toDouble();
    final costs = summary.costs.toDouble();
    final refunds = summary.refunds.toDouble();
    final grossProfit = summary.grossProfit.toDouble();
    final netProfit = summary.netProfit.toDouble();
    final profitMargin = summary.profitMargin.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FinancialOverviewCard(
          revenue: revenue,
          costs: costs,
          refunds: refunds,
          grossProfit: grossProfit,
          netProfit: netProfit,
          profitMargin: profitMargin,
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
          Row(
            children: [
              Text(
                'Tổng ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AnimatedCurrencyText(
                value: report.accountRenewalCosts.fold<int>(
                  0,
                  (sum, item) => sum + item.totalAmount,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                delay: kNumberAnimStagger * 4,
              ),
            ],
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
                    AnimatedCurrencyText(
                      value:
                          double.tryParse(product.totalRevenue)?.toInt() ?? 0,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      delay: kNumberAnimStagger * 5,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('TB: ', style: theme.textTheme.bodySmall),
                        AnimatedCurrencyText(
                          value:
                              double.tryParse(product.avgPrice)?.toInt() ?? 0,
                          style: theme.textTheme.bodySmall,
                          delay: kNumberAnimStagger * 6,
                        ),
                      ],
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

class _FinancialOverviewCard extends StatelessWidget {
  const _FinancialOverviewCard({
    required this.revenue,
    required this.costs,
    required this.refunds,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
  });

  final double revenue;
  final double costs;
  final double refunds;
  final double grossProfit;
  final double netProfit;
  final double profitMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeRevenue = revenue <= 0 ? 1.0 : revenue;
    final costRate = (costs / safeRevenue).clamp(0.0, 1.0);
    final refundRate = (refunds / safeRevenue).clamp(0.0, 1.0);
    final netRate = (netProfit / safeRevenue).clamp(-1.0, 1.0);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tổng quan tài chính',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (netProfit >= 0 ? Colors.teal : Colors.red)
                        .applyOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: AnimatedPercentText(
                    value: profitMargin,
                    decimals: 2,
                    delay: kNumberAnimStagger,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: netProfit >= 0 ? Colors.teal.shade800 : Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = constraints.maxWidth >= 560
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _OverviewStatTile(
                      width: tileWidth,
                      label: 'Doanh thu',
                      amount: revenue.round(),
                      icon: Icons.trending_up,
                      color: Colors.green,
                      animationDelay: Duration.zero,
                    ),
                    _OverviewStatTile(
                      width: tileWidth,
                      label: 'Lợi nhuận ròng',
                      amount: netProfit.round(),
                      icon: Icons.savings_outlined,
                      color: netProfit >= 0 ? Colors.teal : Colors.red,
                      animationDelay: kNumberAnimStagger,
                    ),
                    _OverviewStatTile(
                      width: tileWidth,
                      label: 'Chi phí',
                      amount: costs.round(),
                      icon: Icons.money_off_csred_outlined,
                      color: Colors.orange,
                      animationDelay: kNumberAnimStagger * 2,
                    ),
                    _OverviewStatTile(
                      width: tileWidth,
                      label: 'Hoàn tiền',
                      amount: refunds.round(),
                      icon: Icons.replay_outlined,
                      color: Colors.red,
                      animationDelay: kNumberAnimStagger * 3,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _BreakdownBar(
              label: 'Tỷ lệ chi phí',
              rate: costRate,
              color: Colors.orange,
              animationDelay: kNumberAnimStagger * 4,
            ),
            const SizedBox(height: 8),
            _BreakdownBar(
              label: 'Tỷ lệ hoàn tiền',
              rate: refundRate,
              color: Colors.red,
              animationDelay: kNumberAnimStagger * 5,
            ),
            const SizedBox(height: 8),
            _BreakdownBar(
              label: 'Tỷ lệ lợi nhuận ròng',
              rate: netRate.abs(),
              color: netProfit >= 0 ? Colors.teal : Colors.red.shade700,
              animationDelay: kNumberAnimStagger * 6,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Lợi nhuận gộp: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AnimatedCurrencyText(
                  value: grossProfit.round(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  delay: kNumberAnimStagger * 7,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatTile extends StatelessWidget {
  const _OverviewStatTile({
    required this.width,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.animationDelay = Duration.zero,
  });

  final double width;
  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.applyOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
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
                  AnimatedCurrencyText(
                    value: amount,
                    delay: animationDelay,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.label,
    required this.rate,
    required this.color,
    this.animationDelay = Duration.zero,
  });

  final String label;
  final double rate;
  final Color color;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    return AnimatedStatText(
      value: (rate * 100).clamp(0, 100).toDouble(),
      delay: animationDelay,
      builder: (context, animatedPercent) {
        final percent = animatedPercent.clamp(0, 100).toDouble();
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 8,
                backgroundColor: color.applyOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
    );
  }
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

    final completionRate = rate(stats.completedOrders);
    final cancelledRate = rate(stats.cancelledOrders);
    final refundedRate = rate(stats.refundedOrders);

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
                    AnimatedIntText(
                      value: totalOrders,
                      suffix: ' đơn trong kỳ',
                      delay: Duration.zero,
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
                    color: Colors.teal.applyOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      AnimatedPercentText(
                        value: completionRate,
                        suffix: '% thành công',
                        delay: kNumberAnimStagger,
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
                      icon: Icons.task_alt_outlined,
                      label: 'Thành công',
                      count: stats.completedOrders,
                      color: Colors.green,
                      percent: completionRate,
                      animationDelay: kNumberAnimStagger * 2,
                    ),
                    _OrderStatTile(
                      width: tileWidth,
                      icon: Icons.verified_outlined,
                      label: 'Hoàn tiền',
                      count: stats.refundedOrders,
                      color: Colors.orange,
                      percent: refundedRate,
                      animationDelay: kNumberAnimStagger * 3,
                    ),
                    _OrderStatTile(
                      width: tileWidth,
                      icon: Icons.cancel_outlined,
                      label: 'Đã hủy',
                      count: stats.cancelledOrders,
                      color: Colors.red,
                      percent: cancelledRate,
                      animationDelay: kNumberAnimStagger * 4,
                    ),
                  ],
                );
              },
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
    required this.count,
    required this.color,
    required this.percent,
    this.animationDelay = Duration.zero,
  });

  final double width;
  final IconData icon;
  final String label;
  final int count;
  final double percent;
  final Color color;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.applyOpacity(0.2)),
          color: color.applyOpacity(0.06),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.applyOpacity(0.2),
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
                  AnimatedIntText(
                    value: count,
                    delay: animationDelay,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedPercentText(
                    value: percent,
                    suffix: '% tổng đơn',
                    delay: animationDelay + const Duration(milliseconds: 120),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: PageStorageKey('account-renewal-${cost.serviceType}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.applyOpacity(0.12),
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
            AnimatedCurrencyText(
              value: cost.totalAmount,
              delay: kNumberAnimStagger * 5,
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
                        backgroundColor: theme.colorScheme.primary.applyOpacity(
                          0.15,
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
                      trailing: AnimatedCurrencyText(
                        value: tx.amount,
                        delay: kNumberAnimStagger * 6,
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

class _MonthlyRevenueChartSkeleton extends StatelessWidget {
  const _MonthlyRevenueChartSkeleton();

  static const _barHeightFactors = [
    0.35,
    0.55,
    0.42,
    0.68,
    0.5,
    0.72,
    0.48,
    0.61,
    0.38,
    0.66,
    0.52,
    0.58,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(child: _SkeletonLine(height: 16, widthFactor: 0.5)),
                SizedBox(width: 12),
                _SkeletonBox(width: 88, height: 16, radius: 4),
              ],
            ),
            const SizedBox(height: 8),
            const _SkeletonLine(height: 12, widthFactor: 0.65),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final factor in _barHeightFactors)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _SkeletonBox(
                              width: 16,
                              height: 200 * factor,
                              radius: 6,
                            ),
                            const SizedBox(height: 8),
                            const _SkeletonBox(width: 10, height: 10, radius: 2),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialReportSkeleton extends StatelessWidget {
  const _FinancialReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _FinancialOverviewCardSkeleton(),
        SizedBox(height: 12),
        _OrderStatisticsCardSkeleton(),
        SizedBox(height: 12),
        _SkeletonLine(height: 16, widthFactor: 0.42),
        SizedBox(height: 12),
        _ListTileSkeleton(),
        SizedBox(height: 8),
        _ListTileSkeleton(),
      ],
    );
  }
}

class _FinancialOverviewCardSkeleton extends StatelessWidget {
  const _FinancialOverviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                _SkeletonBox(width: 20, height: 20, radius: 4),
                SizedBox(width: 8),
                Expanded(child: _SkeletonLine(height: 16, widthFactor: 0.45)),
                _SkeletonBox(width: 56, height: 24, radius: 999),
              ],
            ),
            SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTileSkeleton(),
                _StatTileSkeleton(),
                _StatTileSkeleton(),
                _StatTileSkeleton(),
              ],
            ),
            SizedBox(height: 16),
            _BreakdownBarSkeleton(),
            SizedBox(height: 8),
            _BreakdownBarSkeleton(),
            SizedBox(height: 8),
            _BreakdownBarSkeleton(),
            SizedBox(height: 8),
            _SkeletonLine(height: 12, widthFactor: 0.38),
          ],
        ),
      ),
    );
  }
}

class _OrderStatisticsCardSkeleton extends StatelessWidget {
  const _OrderStatisticsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonLine(height: 16, widthFactor: 0.55),
                      SizedBox(height: 6),
                      _SkeletonLine(height: 12, widthFactor: 0.35),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                _SkeletonBox(width: 120, height: 28, radius: 999),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTileSkeleton(compact: true),
                _StatTileSkeleton(compact: true),
                _StatTileSkeleton(compact: true),
                _StatTileSkeleton(compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTileSkeleton extends StatelessWidget {
  const _StatTileSkeleton({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = screenWidth >= 512
        ? (screenWidth - 32 - 12) / 2
        : screenWidth - 32;

    return SizedBox(
      width: tileWidth,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            _SkeletonBox(width: 18, height: 18, radius: 4),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(height: 11, widthFactor: 0.55),
                  SizedBox(height: 6),
                  _SkeletonLine(height: 14, widthFactor: 0.72),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownBarSkeleton extends StatelessWidget {
  const _BreakdownBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _SkeletonLine(height: 12, widthFactor: 0.4)),
            SizedBox(width: 12),
            _SkeletonBox(width: 36, height: 12, radius: 4),
          ],
        ),
        SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: _SkeletonBox(height: 8, radius: 999),
        ),
      ],
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(height: 14, widthFactor: 0.62),
                  SizedBox(height: 8),
                  _SkeletonLine(height: 12, widthFactor: 0.35),
                  SizedBox(height: 4),
                  _SkeletonLine(height: 12, widthFactor: 0.48),
                ],
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SkeletonBox(width: 72, height: 14, radius: 4),
                SizedBox(height: 8),
                _SkeletonBox(width: 56, height: 12, radius: 4),
              ],
            ),
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

class _PeriodRadioTile extends StatelessWidget {
  const _PeriodRadioTile({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final _ReportPeriodType value;
  final _ReportPeriodType groupValue;
  final ValueChanged<_ReportPeriodType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(title),
          onTap: () => onChanged(value),
        ),
      ),
    );
  }
}

class _DateInputTile extends StatelessWidget {
  const _DateInputTile({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          enabled: enabled,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          formatter.format(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ReportPeriodSelection {
  const _ReportPeriodSelection({required this.type, required this.range});

  final _ReportPeriodType type;
  final _ReportRange range;
}

class _ReportRange {
  const _ReportRange({
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  factory _ReportRange.currentMonth() {
    final now = DateTime.now();
    return _ReportRange(
      label: 'Tháng hiện tại',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  factory _ReportRange.forQuarter(int year, int quarter) {
    final startMonth = ((quarter - 1) * 3) + 1;
    return _ReportRange(
      label: 'Quý $quarter/$year',
      startDate: DateTime(year, startMonth),
      endDate: DateTime(year, startMonth + 3, 0, 23, 59, 59),
    );
  }

  factory _ReportRange.fullYear(int year) {
    return _ReportRange(
      label: 'Cả năm $year',
      startDate: DateTime(year),
      endDate: DateTime(year, 12, 31, 23, 59, 59),
    );
  }

  final String label;
  final DateTime startDate;
  final DateTime endDate;
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
