import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/mail/mail_log_detail_screen.dart';
import 'package:fcode_pos/services/mail_log_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:flutter/material.dart';

class MailLogScreen extends StatefulWidget {
  const MailLogScreen({super.key});

  @override
  State<MailLogScreen> createState() => _MailLogScreenState();
}

class _MailLogScreenState extends State<MailLogScreen> {
  // Filter state
  String? _selectedStatus;
  String _recipientSearch = '';
  String _subjectSearch = '';

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;

  // Mail logs state
  List<MailLog> _mailLogs = [];
  bool _isLoading = false;
  String? _error;

  late MailLogService _mailLogService;

  @override
  void initState() {
    super.initState();
    _mailLogService = MailLogService();
    _loadMailLogs();
  }

  Future<void> _loadMailLogs({int? page}) async {
    final targetPage = page ?? _currentPage;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _mailLogService.list(
        status: _selectedStatus,
        recipient: _recipientSearch.isNotEmpty ? _recipientSearch : null,
        subject: _subjectSearch.isNotEmpty ? _subjectSearch : null,
        page: targetPage,
        perPage: 15,
      );

      if (mounted) {
        final pagination = response.data?.pagination;
        setState(() {
          _mailLogs = response.data?.items ?? [];
          _currentPage = pagination?.currentPage ?? 1;
          _totalPages = pagination?.lastPage ?? 1;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Error loading mail logs: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    await _loadMailLogs(page: 1);
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _recipientSearch = '';
      _subjectSearch = '';
    });
    _loadMailLogs(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký email'),
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

    if (_isLoading && _mailLogs.isEmpty) {
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
              onPressed: () => _loadMailLogs(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_mailLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Không có nhật ký email',
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
            itemCount: _mailLogs.length,
            itemBuilder: (context, index) {
              final mailLog = _mailLogs[index];
              return _buildMailLogCard(mailLog, colorScheme);
            },
          ),
        ),
        _buildPaginationControls(context, colorScheme),
      ],
    );
  }

  Widget _buildMailLogCard(MailLog mailLog, ColorScheme colorScheme) {
    final sentAtLabel = mailLog.sentAt != null
        ? DateHelper.formatDateTime(mailLog.sentAt!)
        : (mailLog.createdAt != null
              ? DateHelper.formatDateTime(mailLog.createdAt!)
              : '—');

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
              builder: (_) => MailLogDetailScreen(mailLogId: mailLog.id),
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
              // Row 1: Status badge and recipient
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mailLog.subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gửi đến: ${mailLog.firstRecipient}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant.applyOpacity(
                              0.7,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(mailLog.status, colorScheme),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.7,
                color: colorScheme.outlineVariant.applyOpacity(0.6),
              ),
              const SizedBox(height: 12),
              // Row 2: Date sent
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sentAtLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
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

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'sent':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Đã gửi';
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Đang chờ';
        break;
      case 'failed':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Thất bại';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
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
                ? () => _loadMailLogs(page: _currentPage - 1)
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
                ? () => _loadMailLogs(page: _currentPage + 1)
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

          // Recipient search field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email người nhận',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            controller: TextEditingController(text: _recipientSearch),
            onChanged: (value) {
              setState(() => _recipientSearch = value);
            },
          ),
          const SizedBox(height: 16),

          // Subject search field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm kiếm tiêu đề',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            controller: TextEditingController(text: _subjectSearch),
            onChanged: (value) {
              setState(() => _subjectSearch = value);
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
              DropdownMenuItem(value: 'sent', child: Text('Đã gửi')),
              DropdownMenuItem(value: 'pending', child: Text('Đang chờ')),
              DropdownMenuItem(value: 'failed', child: Text('Thất bại')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value);
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
                    _loadMailLogs(page: 1);
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
}
