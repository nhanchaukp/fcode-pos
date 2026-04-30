import 'dart:convert';

import 'package:fcode_pos/models/chatgpt_models.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatGptSessionDetailScreen extends StatefulWidget {
  const ChatGptSessionDetailScreen({
    super.key,
    required this.session,
  });

  final ChatGptSession session;

  @override
  State<ChatGptSessionDetailScreen> createState() =>
      _ChatGptSessionDetailScreenState();
}

class _ChatGptSessionDetailScreenState
    extends State<ChatGptSessionDetailScreen> {
  late String _formattedJson;
  late Map<String, dynamic> _parsedJson;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _parseJson();
  }

  void _parseJson() {
    try {
      _parsedJson = jsonDecode(widget.session.sessionJson) as Map<String, dynamic>;
      _formattedJson = const JsonEncoder.withIndent('  ').convert(_parsedJson);
    } catch (_) {
      _parsedJson = {};
      _formattedJson = widget.session.sessionJson;
    }
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _formattedJson));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = widget.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session JSON'),
        actions: [
          IconButton(
            icon: Icon(_copied ? Icons.check : Icons.copy),
            tooltip: 'Copy tất cả',
            onPressed: _copyAll,
            color: _copied ? Colors.green : null,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SessionHeader(session: session, colorScheme: colorScheme),
          ),
          SliverToBoxAdapter(
            child: _InfoSection(parsedJson: _parsedJson, colorScheme: colorScheme),
          ),
          SliverToBoxAdapter(
            child: _RawJsonSection(
              formattedJson: _formattedJson,
              onCopy: _copyAll,
              copied: _copied,
              colorScheme: colorScheme,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.session, required this.colorScheme});

  final ChatGptSession session;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage:
                session.image != null ? NetworkImage(session.image!) : null,
            child: session.image == null
                ? Text(
                    session.name.isNotEmpty
                        ? session.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontSize: 24, color: colorScheme.onPrimaryContainer),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                _PlanBadge(session: session, colorScheme: colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.session, required this.colorScheme});

  final ChatGptSession session;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isPro = session.isPro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPro ? Colors.amber.withValues(alpha: 0.2) : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPro ? Colors.amber : colorScheme.outline,
          width: 1,
        ),
      ),
      child: Text(
        session.planType?.toUpperCase() ?? 'FREE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPro ? Colors.amber.shade700 : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Info Section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.parsedJson, required this.colorScheme});

  final Map<String, dynamic> parsedJson;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final user = parsedJson['user'] as Map<String, dynamic>? ?? {};
    final account = parsedJson['account'] as Map<String, dynamic>? ?? {};
    final expires = parsedJson['expires'] as String?;
    final authProvider = parsedJson['authProvider'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Thông tin tài khoản', colorScheme: colorScheme),
          _InfoCard(
            colorScheme: colorScheme,
            entries: [
              _InfoEntry('ID người dùng', user['id']?.toString()),
              _InfoEntry('Nhà cung cấp xác thực', authProvider),
              _InfoEntry('IDP', user['idp']?.toString()),
              _InfoEntry('MFA', user['mfa'] == true ? 'Bật' : 'Tắt'),
              _InfoEntry('Hết hạn', expires),
            ],
          ),
          const SizedBox(height: 12),
          _SectionTitle(title: 'Gói dịch vụ', colorScheme: colorScheme),
          _InfoCard(
            colorScheme: colorScheme,
            entries: [
              _InfoEntry('ID tài khoản', account['id']?.toString()),
              _InfoEntry('Loại gói', account['planType']?.toString()),
              _InfoEntry('Cấu trúc', account['structure']?.toString()),
              _InfoEntry('Khu vực', account['residencyRegion']?.toString()),
              _InfoEntry('Quá hạn thanh toán',
                  account['isDelinquent'] == true ? 'Có' : 'Không'),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.colorScheme});

  final String title;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.entries, required this.colorScheme});

  final List<_InfoEntry> entries;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final visible = entries.where((e) => e.value != null).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              _InfoRow(entry: visible[i], colorScheme: colorScheme),
              if (i < visible.length - 1)
                Divider(height: 1, color: colorScheme.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.entry, required this.colorScheme});

  final _InfoEntry entry;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              entry.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: () => _copyValue(context),
              child: Text(
                entry.value ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyValue(BuildContext context) {
    if (entry.value == null) return;
    Clipboard.setData(ClipboardData(text: entry.value!));
    Toastr.show(
      'Đã copy: ${entry.label}',
      context: context,
      duration: const Duration(seconds: 1),
    );
  }
}

class _InfoEntry {
  const _InfoEntry(this.label, this.value);

  final String label;
  final String? value;
}

// ── Raw JSON Section ──────────────────────────────────────────────────────────

class _RawJsonSection extends StatelessWidget {
  const _RawJsonSection({
    required this.formattedJson,
    required this.onCopy,
    required this.copied,
    required this.colorScheme,
  });

  final String formattedJson;
  final VoidCallback onCopy;
  final bool copied;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Raw JSON',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: onCopy,
                icon: Icon(
                  copied ? Icons.check : Icons.copy,
                  size: 16,
                  color: copied ? Colors.green : null,
                ),
                label: Text(
                  copied ? 'Đã copy' : 'Copy All',
                  style: TextStyle(color: copied ? Colors.green : null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SelectableText(
              formattedJson,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
