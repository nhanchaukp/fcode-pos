import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/coupon/coupon_upsert_screen.dart';
import 'package:fcode_pos/services/coupon_service.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponDetailScreen extends StatefulWidget {
  const CouponDetailScreen({super.key, required this.couponId});

  final int couponId;

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen>
    with SingleTickerProviderStateMixin {
  final _couponService = CouponService();
  late TabController _tabController;

  Coupon? _coupon;
  bool _isLoading = false;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  Future<void> _loadDetail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _couponService.detail(widget.couponId);
      if (!mounted) return;
      setState(() => _coupon = response.data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Load coupon detail: $e');
      if (!mounted) return;
      setState(() => _error = 'Không thể tải thông tin mã giảm giá.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CouponUpsertScreen(couponId: widget.couponId),
      ),
    );
    if (result == true) {
      _changed = true;
      _loadDetail();
    }
  }

  Future<void> _toggleCoupon() async {
    if (_coupon == null) return;
    try {
      final response = await _couponService.toggle(_coupon!.id);
      if (!mounted) return;
      _changed = true;
      if (response.data != null) {
        setState(() => _coupon = response.data);
      } else {
        _loadDetail();
      }
      Toastr.success(
        _coupon!.isEnabled ? 'Đã bật mã giảm giá' : 'Đã tắt mã giảm giá',
      );
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Không thể thay đổi trạng thái');
    }
  }

  Future<void> _deleteCoupon() async {
    if (_coupon == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa mã giảm giá?'),
        content: Text('Bạn có chắc muốn xóa "${_coupon!.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _couponService.delete(_coupon!.id);
      if (!mounted) return;
      Toastr.success('Đã xóa mã giảm giá');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Không thể xóa mã giảm giá');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _changed) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_coupon?.code ?? 'Chi tiết'),
          actions: [
            if (_coupon != null) ...[
              IconButton(
                icon: Icon(
                  _coupon!.isEnabled
                      ? Icons.toggle_on
                      : Icons.toggle_off_outlined,
                  color: _coupon!.isEnabled ? Colors.green : null,
                ),
                tooltip: _coupon!.isEnabled ? 'Tắt' : 'Bật',
                onPressed: _toggleCoupon,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Chỉnh sửa',
                onPressed: _navigateToEdit,
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _deleteCoupon();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Xóa', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Thông tin'),
              Tab(text: 'Lịch sử sử dụng'),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _coupon == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _coupon == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadDetail,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_coupon == null) {
      return const Center(child: Text('Không tìm thấy mã giảm giá'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _InfoTab(coupon: _coupon!, onRefresh: _loadDetail),
        _UsageTab(couponId: widget.couponId),
      ],
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.coupon, required this.onRefresh});

  final Coupon coupon;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final couponType = coupon.couponType;
    final isExpired = coupon.expiresAt != null &&
        coupon.expiresAt!.isBefore(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLowest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: coupon.code));
                      Toastr.success('Đã copy mã ${coupon.code}');
                    },
                    child: Text(
                      coupon.code,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (couponType != null) ...[
                        _chip(couponType.label, couponType.color),
                        const SizedBox(width: 8),
                      ],
                      _chip(
                        coupon.isEnabled ? 'Hoạt động' : 'Tắt',
                        coupon.isEnabled ? Colors.green : Colors.grey,
                      ),
                      if (isExpired) ...[
                        const SizedBox(width: 8),
                        _chip('Hết hạn', Colors.red),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatValue(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLowest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Loại', couponType?.label ?? coupon.type),
                  _infoRow('Giá trị', _formatValue()),
                  if (coupon.maxDiscount != null)
                    _infoRow(
                      'Giảm tối đa',
                      CurrencyHelper.formatCurrency(coupon.maxDiscount!),
                    ),
                  _infoRow(
                    'Hạn sử dụng',
                    coupon.expiresAt != null
                        ? DateHelper.formatDateTime(coupon.expiresAt)
                        : 'Không giới hạn',
                  ),
                  _infoRow(
                    'Số lượng',
                    coupon.quantity?.toString() ?? 'Không giới hạn',
                  ),
                  _infoRow(
                    'Giới hạn/user',
                    coupon.limit?.toString() ?? 'Không giới hạn',
                  ),
                  _infoRow('Đã sử dụng', '${coupon.usageCount} lần'),
                  if (coupon.createdAt != null)
                    _infoRow(
                      'Ngày tạo',
                      DateHelper.formatDateTime(coupon.createdAt),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatValue() {
    if (coupon.couponType == CouponType.percentage) {
      return '${coupon.value}%';
    }
    final intValue = int.tryParse(coupon.value) ?? 0;
    return CurrencyHelper.formatCurrency(intValue);
  }
}

class _UsageTab extends StatefulWidget {
  const _UsageTab({required this.couponId});

  final int couponId;

  @override
  State<_UsageTab> createState() => _UsageTabState();
}

class _UsageTabState extends State<_UsageTab>
    with AutomaticKeepAliveClientMixin {
  final _couponService = CouponService();

  PaginatedData<CouponUsage>? _page;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage({int page = 1}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = page;
    });

    try {
      final response = await _couponService.usage(
        widget.couponId,
        page: page,
      );
      if (!mounted) return;
      setState(() => _page = response.data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _page = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải lịch sử sử dụng.';
        _page = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _page?.items ?? const <CouponUsage>[];
    final pagination = _page?.pagination;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _page == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _page == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _loadUsage(page: _currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có lịch sử sử dụng'),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadUsage(page: _currentPage),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final usage = items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ĐH #${usage.orderId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              usage.user?.name ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (usage.redeemedAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                DateHelper.formatDateTime(usage.redeemedAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyHelper.formatCurrency(usage.orderTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            usage.orderStatus,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (pagination != null && pagination.lastPage > 1)
          Padding(
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
                      ? () => _loadUsage(page: pagination.currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Trước'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: !_isLoading &&
                          pagination.currentPage < pagination.lastPage
                      ? () => _loadUsage(page: pagination.currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Sau'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
