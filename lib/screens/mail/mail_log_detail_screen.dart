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
    final htmlTags = [
      '<html', '<head', '<body', '<div', '<span', '<p', '<br', '<img',
      '<a', '<table', '<tr', '<td', '<th', '<ul', '<li',
      '<h1', '<h2', '<h3', '<h4', '<h5', '<h6',
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadMailLog,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_mailLog == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text('Không tìm thấy email', style: textTheme.bodyMedium),
          ],
        ),
      );
    }

    final mail = _mailLog!;
    final hasHtmlContent = mail.html?.isNotEmpty == true;

    return RefreshIndicator(
      onRefresh: _loadMailLog,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MailStatusBadge(status: mail.status),
            const SizedBox(height: 12),
            Text(
              mail.subject,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _MailInfoCard(mailLog: mail),
            const SizedBox(height: 16),
            if (hasHtmlContent)
              Card(
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: _isHtmlContent
                    ? Html(
                        data: mail.html!,
                        onLinkTap: (url, attributes, element) {
                          if (url == null) return;
                          launchUrlString(
                            url,
                            mode: LaunchMode.inAppBrowserView,
                          );
                        },
                        style: {
                          'body': Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.all(12),
                            fontSize: FontSize(15),
                            color: Colors.black87,
                            backgroundColor: Colors.white,
                          ),
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          mail.html!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                          ),
                        ),
                      ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Không có nội dung',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MailInfoCard extends StatelessWidget {
  const _MailInfoCard({required this.mailLog});

  final MailLog mailLog;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Từ',
              value: mailLog.from ?? 'N/A',
            ),
            _divider(colorScheme),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Gửi đến',
              value: mailLog.recipientsString,
            ),
            if (mailLog.cc != null && mailLog.cc!.isNotEmpty) ...[
              _divider(colorScheme),
              _InfoRow(
                icon: Icons.copy_outlined,
                label: 'CC',
                value: mailLog.cc!.keys.join(', '),
              ),
            ],
            if (mailLog.bcc != null && mailLog.bcc!.isNotEmpty) ...[
              _divider(colorScheme),
              _InfoRow(
                icon: Icons.shield_outlined,
                label: 'BCC',
                value: mailLog.bcc!.keys.join(', '),
              ),
            ],
            _divider(colorScheme),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Ngày tạo',
              value: mailLog.createdAt != null
                  ? DateHelper.formatDateTime(mailLog.createdAt!)
                  : 'N/A',
            ),
            if (mailLog.sentAt != null) ...[
              _divider(colorScheme),
              _InfoRow(
                icon: Icons.send_outlined,
                label: 'Ngày gửi',
                value: DateHelper.formatDateTime(mailLog.sentAt!),
              ),
            ],
            if (mailLog.error != null && mailLog.error!.isNotEmpty) ...[
              _divider(colorScheme),
              _InfoRow(
                icon: Icons.error_outline,
                label: 'Lỗi',
                value: mailLog.error!,
                isError: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isError = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = isError ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isError ? colorScheme.error : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MailStatusBadge extends StatelessWidget {
  const _MailStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (Color bg, Color fg, IconData icon, String label) =
        switch (status.toLowerCase()) {
      'sent' => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
        Icons.check_circle_outline,
        'Đã gửi',
      ),
      'pending' => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
        Icons.hourglass_empty,
        'Đang chờ',
      ),
      'failed' => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.error_outline,
        'Thất bại',
      ),
      _ => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
        Icons.help_outline,
        status,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
