import 'package:fcode_pos/enums.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/mail/mail_log_detail_screen.dart';
import 'package:fcode_pos/services/mail_log_service.dart';
import 'package:fcode_pos/ui/components/enum_badge.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:flutter/material.dart';

class MailLogScreen extends StatefulWidget {
  const MailLogScreen({super.key});

  @override
  State<MailLogScreen> createState() => _MailLogScreenState();
}

class _MailLogScreenState extends State<MailLogScreen> {
  // Filter state
  MailLogStatus? _selectedStatus;
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
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _mailLogs.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _MailLogCard(
                mailLog: _mailLogs[index],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MailLogDetailScreen(mailLogId: _mailLogs[index].id),
                    ),
                  );
                },
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
          DropdownButtonFormField<MailLogStatus>(
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
            ),
            initialValue: _selectedStatus,
            items: const [
              DropdownMenuItem<MailLogStatus>(
                value: null,
                child: Text('Tất cả'),
              ),
              DropdownMenuItem<MailLogStatus>(
                value: MailLogStatus.sent,
                child: Text('Đã gửi'),
              ),
              DropdownMenuItem<MailLogStatus>(
                value: MailLogStatus.pending,
                child: Text('Đang chờ'),
              ),
              DropdownMenuItem<MailLogStatus>(
                value: MailLogStatus.failed,
                child: Text('Thất bại'),
              ),
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

class _MailLogCard extends StatelessWidget {
  const _MailLogCard({required this.mailLog, this.onTap});

  final MailLog mailLog;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sentAtLabel = mailLog.sentAt != null
        ? DateHelper.formatDateTime(mailLog.sentAt!)
        : (mailLog.createdAt != null
              ? DateHelper.formatDateTime(mailLog.createdAt!)
              : '—');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mailLog.subject,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gửi đến: ${mailLog.firstRecipient}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MailStatusBadge(status: mailLog.status),
                ],
              ),
              const SizedBox(height: 10),
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
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
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

class _MailStatusBadge extends StatelessWidget {
  const _MailStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return EnumBadge(
      value: MailLogStatus.fromValue(status),
      fallbackLabel: status,
      fontSize: 11,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      borderRadius: 12,
    );
  }
}
