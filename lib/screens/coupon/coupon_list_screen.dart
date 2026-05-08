import 'dart:async';

import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/coupon/coupon_detail_screen.dart';
import 'package:fcode_pos/screens/coupon/coupon_upsert_screen.dart';
import 'package:fcode_pos/services/coupon_service.dart';
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
  Timer? _searchDebounce;
  String _lastSearchValue = '';

  PaginatedData<Coupon>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  static const int _perPage = 15;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCoupons();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final currentValue = _searchController.text.trim();
    if (currentValue == _lastSearchValue) return;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _lastSearchValue = currentValue;
      _loadCoupons(page: 1);
    });

    if (mounted) setState(() {});
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        title: SearchBar(
          controller: _searchController,
          hintText: 'Tìm mã giảm giá',
          leading: IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: [
            if (_searchController.text.isEmpty)
              IconButton(
                tooltip: 'Thêm mã giảm giá',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add),
                onPressed: _navigateToCreate,
              )
            else
              IconButton(
                tooltip: 'Xóa',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  _loadCoupons(page: 1);
                },
              ),
          ],
          onSubmitted: (_) => _loadCoupons(page: 1),
          textInputAction: TextInputAction.search,
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent(coupons)),
          _buildPaginationControls(pagination),
        ],
      ),
    );
  }

  Widget _buildContent(List<Coupon> coupons) {
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
            Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không tìm thấy mã giảm giá'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCoupons(page: _currentPage),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: coupons.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          return _CouponCard(
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
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

class _CouponCard extends StatelessWidget {
  const _CouponCard({
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
    final isExpired = coupon.expiresAt != null &&
        coupon.expiresAt!.isBefore(DateTime.now());

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      coupon.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(context, isExpired),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (couponType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: couponType.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        couponType.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: couponType.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _formatValue(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${coupon.usageCount}${coupon.quantity != null ? '/${coupon.quantity}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 13,
                    color: isExpired
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
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
                    Icon(Icons.repeat, size: 13, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Tối đa ${coupon.limit}/user',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isExpired) {
    final Color color;
    final String label;

    if (!coupon.isEnabled) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
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
