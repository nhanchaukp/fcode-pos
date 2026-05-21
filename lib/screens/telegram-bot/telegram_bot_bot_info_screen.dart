import 'dart:convert';

import 'package:fcode_pos/screens/telegram-bot/telegram_bot_api_client.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class TelegramBotInfoScreen extends StatefulWidget {
  const TelegramBotInfoScreen({super.key, required this.token});

  final String token;

  @override
  State<TelegramBotInfoScreen> createState() => _TelegramBotInfoScreenState();
}

class _TelegramBotInfoScreenState extends State<TelegramBotInfoScreen> {
  late final TelegramBotApiClient _api;
  bool _isLoading = true;
  String? _error;
  JsonMap _data = const {};

  @override
  void initState() {
    super.initState();
    _api = TelegramBotApiClient(token: widget.token);
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getBotInfo();
      if (!mounted) {
        return;
      }
      setState(() => _data = data);
    } on TelegramBotApiException catch (error) {
      _error = error.message;
      Toastr.error(error.message);
    } catch (_) {
      _error = 'Không thể tải thông tin bot';
      Toastr.error(_error!);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Bot • Bot info'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loadInfo,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data.isEmpty
          ? _ErrorView(message: _error!, onRetry: _loadInfo)
          : RefreshIndicator(
              onRefresh: _loadInfo,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _buildQuickInfoCard(),
                  const SizedBox(height: 12),
                  _buildJsonCard('Bot (getMe)', _data['bot']),
                  const SizedBox(height: 12),
                  _buildJsonCard('Webhook info', _data['webhookInfo']),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickInfoCard() {
    final cs = Theme.of(context).colorScheme;
    final tokenConfigured = _data['tokenConfigured'] == true;
    final webhookPath = (_data['webhookPath'] ?? '-').toString();
    final detectedWebhookUrl = (_data['detectedWebhookUrl'] ?? '-').toString();
    final fetchError = (_data['fetchError'] ?? '').toString();

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin chính',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    tokenConfigured ? 'Token: configured' : 'Token: missing',
                  ),
                ),
                Chip(label: Text('Webhook path: $webhookPath')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Detected URL: $detectedWebhookUrl'),
            if (fetchError.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'fetchError: $fetchError',
                style: TextStyle(color: cs.error),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'Commands text',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText((_data['commandsText'] ?? '').toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonCard(String title, dynamic value) {
    final cs = Theme.of(context).colorScheme;
    const encoder = JsonEncoder.withIndent('  ');
    String pretty;

    try {
      pretty = encoder.convert(value);
    } catch (_) {
      pretty = '$value';
    }

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(pretty),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
