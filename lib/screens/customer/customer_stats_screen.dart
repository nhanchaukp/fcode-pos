import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/customer/customer_detail_screen.dart';
import 'package:fcode_pos/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerStatsScreen extends StatefulWidget {
  const CustomerStatsScreen({super.key});

  @override
  State<CustomerStatsScreen> createState() => _CustomerStatsScreenState();
}

class _CustomerStatsScreenState extends State<CustomerStatsScreen> {
  final _customerService = CustomerService();
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern();
  CustomerStats? _stats;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _customerService.stats();

      if (!mounted) return;
      setState(() {
        _stats = response.data;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } catch (e, stackTrace) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: 'Load customer stats error: $e',
      );
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải thống kê khách hàng.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê khách hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadStats, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assessment_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không có dữ liệu thống kê'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildStatsCard(
            title: 'Tổng số khách hàng',
            value: _formatNumber(_stats!.totalUsers),
            icon: Icons.people,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatsCard(
            title: 'Khách hàng mới (30 ngày)',
            value: _formatNumber(_stats!.newUsersLast30Days),
            icon: Icons.person_add,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatsCard(
            title: 'Khách hàng có đơn hàng',
            value: _formatNumber(_stats!.customersWithOrders),
            icon: Icons.shopping_bag,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            'Top 10 khách hàng (năm nay)',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_stats!.top10CustomersThisYear.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Chưa có dữ liệu'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stats!.top10CustomersThisYear.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = _stats!.top10CustomersThisYear[index];
                return _buildTopCustomerCard(
                  customer,
                  index + 1,
                  onTap: () => _navigateToCustomerDetail(customer),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToCustomerDetail(TopCustomer customer) async {
    try {
      final response = await _customerService.detail(customer.id);
      if (response.success && response.data != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(user: response.data!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông tin khách hàng: $e')),
        );
      }
    }
  }

  String _formatNumber(int value) => _numberFormatter.format(value);

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildTopCustomerCard(
    TopCustomer customer,
    int rank, {
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = customer.name.isNotEmpty
        ? customer.name
        : customer.email;
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    Color getRankColor(int rank) {
      switch (rank) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.grey;
        case 3:
          return Colors.orange;
        default:
          return colorScheme.primary;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: getRankColor(rank).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: getRankColor(rank),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(radius: 18, child: Text(initial)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (customer.phone != null &&
                        customer.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.phone!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${customer.ordersCount} đơn',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
