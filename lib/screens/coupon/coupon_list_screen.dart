import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/coupon/coupon_detail_screen.dart';
import 'package:fcode_pos/screens/coupon/coupon_upsert_screen.dart';
import 'package:fcode_pos/services/coupon_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/badge/enum_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  final _couponService = CouponService();
  final _searchController = TextEditingController();

  PaginatedData<Coupon>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 15;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _couponService.list(
        search: _searchController.text.trim(),
        page: page,
        perPage: _perPage,
      );

      if (!mounted) return;
      setState(() => _page = response.data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _page = null;
      });
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Load coupons error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách mã giảm giá.';
        _page = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToDetail(Coupon coupon) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CouponDetailScreen(couponId: coupon.id),
      ),
    );
    if (result == true) _loadCoupons(page: _currentPage);
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CouponUpsertScreen()),
    );
    if (result == true) _loadCoupons(page: 1);
  }

  Future<void> _toggleCoupon(Coupon coupon) async {
    try {
      await _couponService.toggle(coupon.id);
      if (!mounted) return;
      Toastr.success(
        coupon.isEnabled ? 'Đã tắt mã giảm giá' : 'Đã bật mã giảm giá',
      );
      _loadCoupons(page: _currentPage);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Không thể thay đổi trạng thái');
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupons = _page?.items ?? const <Coupon>[];
    final pagination = _page?.pagination;

    return AppScaffold(
      title: 'Mã giảm giá',
      enableSearch: true,
      searchHint: 'Tìm mã giảm giá',
      searchController: _searchController,
      onSearchChanged: (_) => _loadCoupons(page: 1),
      onSearchSubmitted: (_) => _loadCoupons(page: 1),
      actions: [
        IconButton(
          tooltip: 'Thêm mã giảm giá',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add),
          onPressed: _navigateToCreate,
        ),
      ],
      body: (context, scrollController) => Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent(coupons, scrollController)),
          _buildPaginationControls(pagination),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<Coupon> coupons,
    ScrollController scrollController,
  ) {
    if (_isLoading && _page == null && _error == null) {
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
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _loadCoupons(page: _currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (coupons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text('Không tìm thấy mã giảm giá'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCoupons(page: _currentPage),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return _CouponTile(
            coupon: coupon,
            onTap: () => _navigateToDetail(coupon),
            onToggle: () => _toggleCoupon(coupon),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(Pagination? pagination) {
    if (pagination == null || pagination.lastPage <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Text(
            'Trang ${pagination.currentPage}/${pagination.lastPage}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: !_isLoading && pagination.currentPage > 1
                ? () => _loadCoupons(page: pagination.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed:
                !_isLoading && pagination.currentPage < pagination.lastPage
                ? () => _loadCoupons(page: pagination.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.coupon,
    required this.onTap,
    required this.onToggle,
  });

  final Coupon coupon;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final couponType = coupon.couponType;
    final isExpired =
        coupon.expiresAt != null && coupon.expiresAt!.isBefore(DateTime.now());

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          coupon.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        isEnabled: coupon.isEnabled,
                        isExpired: isExpired,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (couponType != null) ...[
                        EnumBadge(
                          value: couponType,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatValue(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${coupon.usageCount}${coupon.quantity != null ? '/${coupon.quantity}' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: isExpired
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        coupon.expiresAt != null
                            ? 'HSD: ${DateHelper.formatDate(coupon.expiresAt)}'
                            : 'Không giới hạn',
                        style: TextStyle(
                          fontSize: 11,
                          color: isExpired
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (coupon.limit != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Tối đa ${coupon.limit}/user',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  coupon.isEnabled
                      ? Icons.toggle_on
                      : Icons.toggle_off_outlined,
                  size: 28,
                  color: coupon.isEnabled
                      ? Colors.green
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue() {
    final type = coupon.couponType;
    if (type == CouponType.percentage) {
      return '${coupon.value}%';
    }
    final intValue = int.tryParse(coupon.value) ?? 0;
    return CurrencyHelper.formatCurrency(intValue);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isEnabled, required this.isExpired});

  final bool isEnabled;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (!isEnabled) {
      color = Colors.grey;
      label = 'Tắt';
    } else if (isExpired) {
      color = Colors.red;
      label = 'Hết hạn';
    } else {
      color = Colors.green;
      label = 'Hoạt động';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
