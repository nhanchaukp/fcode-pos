import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/refund/refund_detail_screen.dart';
import 'package:fcode_pos/services/refund_service.dart';
import 'package:fcode_pos/ui/components/refund_reason_badge.dart';
import 'package:fcode_pos/ui/components/refund_status_badge.dart';
import 'package:fcode_pos/ui/components/refund_type_badge.dart';
import 'package:fcode_pos/utils/currency_helper.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu hoàn tiền'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Bộ lọc',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _refunds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRefunds(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_refunds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Không có yêu cầu hoàn tiền',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _refunds.length,
            itemBuilder: (context, index) {
              final refund = _refunds[index];
              return _buildRefundCard(refund, colorScheme);
            },
          ),
        ),
        _buildPaginationControls(context, colorScheme),
      ],
    );
  }

  Widget _buildRefundCard(Refund refund, ColorScheme colorScheme) {
    final customerName = refund.user?.name ?? 'Khách hàng';
    final createdAtLabel = refund.createdAt != null
        ? DateHelper.formatDateTime(refund.createdAt!)
        : '—';
    final amountFormatted = CurrencyHelper.formatCurrency(
      refund.finalAmount.round(),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.applyOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RefundDetailScreen(refund: refund),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: colorScheme.primary.applyOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Mã đơn hàng | Tên khách hàng | Trạng thái
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng #${refund.shopOrderId}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant.applyOpacity(
                              0.7,
                            ),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  RefundStatusBadge(status: refund.status),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.7,
                color: colorScheme.outlineVariant.applyOpacity(0.6),
              ),
              const SizedBox(height: 12),
              // Row 2: Loại | Lý do (same line)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RefundTypeBadge(type: refund.type),
                  RefundReasonBadge(reason: refund.reason),
                ],
              ),
              const SizedBox(height: 12),
              // Row 3: Ngày tạo yêu cầu
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.schedule_outlined,
                      createdAtLabel,
                      colorScheme.onSurfaceVariant,
                      context,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 3: Số tiền hoàn
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Số tiền hoàn',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.applyOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountFormatted,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions: Approve | Reject when pending
              if (refund.status.toLowerCase() == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _actioningIds.contains(refund.id)
                            ? null
                            : () => _onReject(refund),
                        icon: const Icon(Icons.close),
                        label: _actioningIds.contains(refund.id)
                            ? const Text('Đang xử lý...')
                            : const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _actioningIds.contains(refund.id)
                            ? null
                            : () => _onApprove(refund),
                        icon: const Icon(Icons.check),
                        label: _actioningIds.contains(refund.id)
                            ? const Text('Đang xử lý...')
                            : const Text('Duyệt'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color iconColor,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
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
            value: _selectedStatus,
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
            value: _selectedType,
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
            value: _selectedReason,
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
