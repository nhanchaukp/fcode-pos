import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/mail_log_service.dart';
import 'package:fcode_pos/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MailLogDetailScreen extends StatefulWidget {
  const MailLogDetailScreen({super.key, required this.mailLogId});

  final int mailLogId;

  @override
  State<MailLogDetailScreen> createState() => _MailLogDetailScreenState();
}

class _MailLogDetailScreenState extends State<MailLogDetailScreen> {
  MailLog? _mailLog;
  bool _isLoading = false;
  String? _error;
  bool _isHtmlContent = false;

  bool _isHtmlString(String text) {
    // Kiểm tra xem text có chứa các thẻ HTML cơ bản không
    final htmlTags = [
      '<html',
      '<head',
      '<body',
      '<div',
      '<span',
      '<p',
      '<br',
      '<img',
      '<a',
      '<table',
      '<tr',
      '<td',
      '<th',
      '<ul',
      '<li',
      '<h1',
      '<h2',
      '<h3',
      '<h4',
      '<h5',
      '<h6',
    ];

    return htmlTags.any((tag) => text.toLowerCase().contains(tag));
  }

  late MailLogService _mailLogService;

  @override
  void initState() {
    super.initState();
    _mailLogService = MailLogService();
    _loadMailLog();
  }

  Future<void> _loadMailLog() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _mailLogService.show(widget.mailLogId);

      setState(() {
        _mailLog = response.data;
        _isLoading = false;
        _isHtmlContent = _isHtmlString(_mailLog?.html ?? '');
      });
    } catch (e, st) {
      debugPrintStack(stackTrace: st, label: 'Error loading mail log: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết email')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
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
              onPressed: () => _loadMailLog(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_mailLog == null) {
      return const Center(child: Text('Không tìm thấy email'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final hasHtmlContent = _mailLog!.html?.isNotEmpty == true;
    final infoSection = _buildMailInfo(context, colorScheme);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoSection,
          const SizedBox(height: 24),
          if (hasHtmlContent)
            _isHtmlContent
                ? Html(
                    data: _mailLog!.html!,
                    onLinkTap: (url, attributes, element) {
                      if (url == null) {
                        return;
                      }
                      launchUrlString(url, mode: LaunchMode.inAppBrowserView);
                    },
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(16),
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    },
                  )
                : SelectableText(
                    _mailLog!.html!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Không có nội dung',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMailInfo(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBadge(_mailLog!.status, colorScheme),
        const SizedBox(height: 16),
        Text(
          _mailLog!.subject,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Từ',
                  _mailLog!.from ?? 'N/A',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Gửi đến',
                  _mailLog!.recipientsString,
                  icon: Icons.email_outlined,
                ),
                if (_mailLog!.cc != null && _mailLog!.cc!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'CC',
                    _mailLog!.cc!.keys.join(', '),
                    icon: Icons.copy_outlined,
                  ),
                ],
                if (_mailLog!.bcc != null && _mailLog!.bcc!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'BCC',
                    _mailLog!.bcc!.keys.join(', '),
                    icon: Icons.shield_outlined,
                  ),
                ],
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Ngày tạo',
                  _mailLog!.createdAt != null
                      ? DateHelper.formatDateTime(_mailLog!.createdAt!)
                      : 'N/A',
                  icon: Icons.calendar_today_outlined,
                ),
                if (_mailLog!.sentAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Ngày gửi',
                    DateHelper.formatDateTime(_mailLog!.sentAt!),
                    icon: Icons.send_outlined,
                  ),
                ],
                if (_mailLog!.error != null && _mailLog!.error!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Lỗi',
                    _mailLog!.error!,
                    icon: Icons.error_outline,
                    isError: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'sent':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        label = 'Đã gửi';
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_empty;
        label = 'Đang chờ';
        break;
      case 'failed':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.error_outline;
        label = 'Thất bại';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    bool isError = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: isError ? Colors.red : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
