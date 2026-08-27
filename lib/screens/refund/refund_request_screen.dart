import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/refund/refund_detail_screen.dart';
import 'package:fcode_pos/services/refund_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/badge/refund_reason_badge.dart';
import 'package:fcode_pos/ui/components/badge/refund_status_badge.dart';
import 'package:fcode_pos/ui/components/badge/refund_type_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RefundRequestScreen extends ConsumerStatefulWidget {
  const RefundRequestScreen({super.key});

  @override
  ConsumerState<RefundRequestScreen> createState() =>
      _RefundRequestScreenState();
}

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  // Filter state
  String? _selectedStatus;
  String? _selectedType;
  String? _selectedReason;
  String _searchText = '';

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;

  // Refunds state
  List<Refund> _refunds = [];
  bool _isLoading = false;
  String? _error;
  final Set<int> _actioningIds = <int>{};

  late RefundService _refundService;

  @override
  void initState() {
    super.initState();
    _refundService = RefundService();
    _loadRefunds();
  }

  Future<void> _loadRefunds({int? page}) async {
    final targetPage = page ?? _currentPage;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _refundService.list(
        status: _selectedStatus,
        type: _selectedType,
        reason: _selectedReason,
        search: _searchText.isNotEmpty ? _searchText : null,
        page: targetPage,
        perPage: 20,
      );

      if (mounted) {
        final pagination = response.data?.pagination;
        setState(() {
          _refunds = response.data?.items ?? [];
          _currentPage = pagination?.currentPage ?? 1;
          _totalPages = pagination?.lastPage ?? 1;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Error loading refunds: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadRefunds(page: 1);
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedType = null;
      _selectedReason = null;
      _searchText = '';
    });
    _loadRefunds(page: 1);
  }

  bool get _hasFilters =>
      _selectedStatus != null ||
      _selectedType != null ||
      _selectedReason != null ||
      _searchText.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Yêu cầu hoàn tiền',
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Bộ lọc',
          icon: Badge(
            isLabelVisible: _hasFilters,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: () => _showFilterBottomSheet(context),
        ),
        if (_hasFilters)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Xóa bộ lọc',
            icon: const Icon(Icons.clear),
            onPressed: _resetFilters,
          ),
      ],
      body: (context, scrollController) => Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAll,
              child: _buildBody(context, scrollController),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ScrollController scrollController) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _refunds.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Lỗi: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadRefunds(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_refunds.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Không có yêu cầu hoàn tiền',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _refunds.length,
            itemBuilder: (context, index) {
              final refund = _refunds[index];
              return _RefundTile(
                refund: refund,
                isActioning: _actioningIds.contains(refund.id),
                onTap: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => RefundDetailScreen(refund: refund),
                    ),
                  );
                  if (updated == true && mounted) {
                    _loadRefunds(page: _currentPage);
                  }
                },
                onApprove: () => _onApprove(refund),
                onReject: () => _onReject(refund),
              );
            },
          ),
        ),
        _buildPaginationControls(context, colorScheme),
      ],
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    if (_totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Text('Trang $_currentPage/$_totalPages', style: textStyle),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: _currentPage > 1
                ? () => _loadRefunds(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _currentPage < _totalPages
                ? () => _loadRefunds(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),

          // Search field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm kiếm',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            controller: TextEditingController(text: _searchText),
            onChanged: (value) {
              setState(() => _searchText = value);
            },
          ),
          const SizedBox(height: 16),

          // Status dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedStatus,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
              DropdownMenuItem(value: 'processing', child: Text('Đang xử lý')),
              DropdownMenuItem(value: 'completed', child: Text('Hoàn thành')),
              DropdownMenuItem(value: 'rejected', child: Text('Từ chối')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value);
            },
          ),
          const SizedBox(height: 16),

          // Type dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Loại hoàn tiền',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedType,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(value: 'item', child: Text('Hoàn sản phẩm')),
              DropdownMenuItem(value: 'order', child: Text('Hoàn đơn hàng')),
            ],
            onChanged: (value) {
              setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 16),

          // Reason dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Lý do',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedReason,
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(
                value: 'customer_request',
                child: Text('Yêu cầu khách hàng'),
              ),
              DropdownMenuItem(
                value: 'defective_product',
                child: Text('Sản phẩm lỗi'),
              ),
              DropdownMenuItem(
                value: 'wrong_product',
                child: Text('Sai sản phẩm'),
              ),
              DropdownMenuItem(
                value: 'not_as_described',
                child: Text('Không đúng mô tả'),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedReason = value);
            },
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _resetFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Đặt lại'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    _loadRefunds(page: 1);
                    Navigator.pop(context);
                  },
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _onApprove(Refund refund) async {
    final note = await _showTextInputDialog(
      title: 'Duyệt hoàn tiền',
      label: 'Ghi chú (tùy chọn)',
      hintText: 'Nhập ghi chú xử lý...',
      confirmText: 'Duyệt',
    );
    if (!mounted) return;
    if (note == null) return; // cancelled

    setState(() => _actioningIds.add(refund.id));
    try {
      final res = await _refundService.approve(refund.id, adminNotes: note);
      final updated = res.data;
      if (!mounted) return;
      if (updated != null) {
        setState(() {
          final idx = _refunds.indexWhere((e) => e.id == refund.id);
          if (idx != -1) _refunds[idx] = updated;
          _actioningIds.remove(refund.id);
        });
        Toastr.success('Đã duyệt hoàn tiền.');
        _loadRefunds(page: _currentPage);
      } else {
        setState(() => _actioningIds.remove(refund.id));
        _loadRefunds(page: _currentPage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _actioningIds.remove(refund.id));
      Toastr.error('Lỗi duyệt hoàn tiền: $e');
    }
  }

  Future<void> _onReject(Refund refund) async {
    final reason = await _showTextInputDialog(
      title: 'Từ chối hoàn tiền',
      label: 'Lý do',
      hintText: 'Nhập lý do từ chối...',
      confirmText: 'Từ chối',
    );
    if (!mounted) return;
    if (reason == null || reason.trim().isEmpty) return; // require reason

    setState(() => _actioningIds.add(refund.id));
    try {
      final res = await _refundService.reject(refund.id, reason: reason);
      final updated = res.data;
      if (!mounted) return;
      if (updated != null) {
        setState(() {
          final idx = _refunds.indexWhere((e) => e.id == refund.id);
          if (idx != -1) _refunds[idx] = updated;
          _actioningIds.remove(refund.id);
        });
        Toastr.success('Đã từ chối hoàn tiền.');
        _loadRefunds(page: _currentPage);
      } else {
        setState(() => _actioningIds.remove(refund.id));
        _loadRefunds(page: _currentPage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _actioningIds.remove(refund.id));
      Toastr.error('Lỗi từ chối hoàn tiền: $e');
    }
  }

  Future<String?> _showTextInputDialog({
    required String title,
    required String label,
    String? hintText,
    String confirmText = 'Xác nhận',
  }) async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}

class _RefundTile extends StatelessWidget {
  const _RefundTile({
    required this.refund,
    required this.isActioning,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  final Refund refund;
  final bool isActioning;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customerName = refund.user?.name ?? 'Khách hàng';
    final createdAtLabel = refund.createdAt != null
        ? DateHelper.formatDateTime(refund.createdAt!)
        : '—';
    final amountFormatted = CurrencyHelper.formatCurrency(
      refund.finalAmount.round(),
    );
    final isPending = refund.status.toLowerCase() == 'pending';

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
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RefundStatusBadge(status: refund.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Đơn hàng #${refund.shopOrderId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      RefundTypeBadge(type: refund.type),
                      RefundReasonBadge(reason: refund.reason),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          createdAtLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        amountFormatted,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Spacer(),
                        if (isActioning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else ...[
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: colorScheme.error,
                            ),
                            tooltip: 'Từ chối',
                            onPressed: onReject,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.check_circle,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            tooltip: 'Duyệt',
                            onPressed: onApprove,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
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
}
