import 'package:fcode_pos/ui/dashboard/dashboard_components.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final _statConfigs = [
    _StatConfig(
      icon: Icons.payments_outlined,
      title: 'Doanh thu',
      value: '₫128.5M',
      subtitle: 'Tăng 12% so với tuần trước',
      color: Colors.teal,
      trendLabel: '+12%',
    ),
    _StatConfig(
      icon: Icons.attach_money_outlined,
      title: 'Lợi nhuận',
      value: '₫38.2M',
      subtitle: 'Biên lợi nhuận 29,7%',
      color: Colors.amber,
      trendLabel: '+6%',
    ),
    _StatConfig(
      icon: Icons.shopping_bag_outlined,
      title: 'Đơn hàng',
      value: '423',
      subtitle: '32 đơn hàng mới hôm nay',
      color: Colors.indigo,
      trendLabel: '+18',
    ),
  ];

  static final _revenueTrend = [
    62.0,
    85.0,
    80.0,
    94.0,
    105.0,
    98.0,
    120.0,
  ];

  static final _profitTrend = [
    24.0,
    30.0,
    28.0,
    34.0,
    37.0,
    32.0,
    40.0,
  ];

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
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final crossAxisCount = maxWidth > 900
                      ? 3
                      : maxWidth > 600
                          ? 2
                          : 1;

                  final spacing = 16.0;
                  final itemWidth = crossAxisCount == 1
                      ? maxWidth
                      : (maxWidth - spacing * (crossAxisCount - 1)) /
                          crossAxisCount;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _statConfigs
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
              const SizedBox(height: 24),
              DashboardTrendChart(
                data: _revenueTrend,
                color: Colors.teal,
                title: 'Doanh thu theo tuần',
                subtitle: 'Doanh thu 7 ngày gần nhất (triệu đồng)',
              ),
              const SizedBox(height: 16),
              DashboardTrendChart(
                data: _profitTrend,
                color: Colors.indigo,
                title: 'Lợi nhuận gộp',
                subtitle: 'Lợi nhuận trước thuế (triệu đồng)',
              ),
              const SizedBox(height: 24),
              DashboardSection(
                title: 'Hoạt động gần đây',
                children: _recentActivities
                    .map(
                      (activity) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                activity.color.withValues(alpha: 0.12),
                            foregroundColor: activity.color,
                            child: Icon(activity.leadingIcon),
                          ),
                          title: Text(activity.title),
                          subtitle: Text(activity.subtitle),
                          trailing: Text(
                            activity.amount,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              DashboardSection(
                title: 'Nhắc việc',
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('Xem tất cả'),
                ),
                children: [
                  _ReminderTile(
                    icon: Icons.pending_actions_outlined,
                    title: '5 đơn hàng đang chờ xác nhận',
                    subtitle: 'Kiểm tra và xác nhận trước 17:00 hôm nay',
                  ),
                  const SizedBox(height: 12),
                  _ReminderTile(
                    icon: Icons.warning_amber_outlined,
                    title: '2 sản phẩm sắp hết hàng',
                    subtitle:
                        'Apple Watch Series 9, Apple AirPods Pro – tồn kho < 5',
                  ),
                  const SizedBox(height: 12),
                  _ReminderTile(
                    icon: Icons.campaign_outlined,
                    title: 'Chiến dịch marketing tuần sau',
                    subtitle: 'Chuẩn bị nội dung và ngân sách cho tuần 42',
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
