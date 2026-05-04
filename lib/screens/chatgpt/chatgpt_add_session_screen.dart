import 'package:fcode_pos/services/chatgpt_session_service.dart';
import 'package:fcode_pos/storage/chatgpt_session_storage.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// ── Browser Login ─────────────────────────────────────────────────────────────

class ChatGptBrowserLoginScreen extends StatefulWidget {
  const ChatGptBrowserLoginScreen({super.key});

  @override
  State<ChatGptBrowserLoginScreen> createState() =>
      _ChatGptBrowserLoginScreenState();
}

class _ChatGptBrowserLoginScreenState
    extends State<ChatGptBrowserLoginScreen> {
  final _service = ChatGptSessionService();
  InAppWebViewController? _webController;

  bool _isLoggedIn = false;
  bool _isSaving = false;
  bool _isPageLoading = true;
  bool _cookiesCleared = false;

  static const _chatgptHome = 'https://chatgpt.com/';

  @override
  void initState() {
    super.initState();
    _clearAndPrepare();
  }

  Future<void> _clearAndPrepare() async {
    await _service.clearAllWebViewData();
    if (mounted) setState(() => _cookiesCleared = true);
  }

  void _onLoadStart(InAppWebViewController _, WebUri? url) {
    if (url == null) return;
    setState(() {
      _isPageLoading = true;
      if (!_detectLoggedIn(url.toString())) _isLoggedIn = false;
    });
  }

  void _onLoadStop(InAppWebViewController _, WebUri? url) {
    if (url == null) return;
    setState(() {
      _isPageLoading = false;
      _isLoggedIn = _detectLoggedIn(url.toString());
    });
  }

  bool _detectLoggedIn(String url) =>
      (url == _chatgptHome ||
          url.startsWith('https://chatgpt.com/?') ||
          url.startsWith('https://chatgpt.com/#')) &&
      !url.contains('/auth/') &&
      !url.contains('/login');

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final session = await _service.captureSession();
      await ChatGptSessionStorage.save(session);
      if (!mounted) return;
      Toastr.success('Đã lưu session: ${session.email}', context: context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Toastr.error('Lỗi: $e', context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập ChatGPT'),
        actions: [
          if (_isPageLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
          if (_isLoggedIn)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save, color: Colors.white, size: 18),
                    label: const Text(
                      'Lưu',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => _webController?.reload(),
          ),
        ],
      ),
      body: !_cookiesCleared
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang chuẩn bị phiên đăng nhập mới...'),
                ],
              ),
            )
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_chatgptHome)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    useShouldOverrideUrlLoading: false,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    userAgent:
                        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
                        'Mobile/15E148 Safari/604.1',
                  ),
                  onWebViewCreated: (c) => _webController = c,
                  onLoadStart: _onLoadStart,
                  onLoadStop: _onLoadStop,
                  onReceivedError: (_, __, ___) {
                    if (mounted) setState(() => _isPageLoading = false);
                  },
                ),
                if (!_isLoggedIn)
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Đăng nhập xong, nhấn "Lưu" trên thanh tiêu đề',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Manual JSON Input ─────────────────────────────────────────────────────────

class ChatGptManualJsonScreen extends StatefulWidget {
  const ChatGptManualJsonScreen({super.key});

  @override
  State<ChatGptManualJsonScreen> createState() =>
      _ChatGptManualJsonScreenState();
}

class _ChatGptManualJsonScreenState extends State<ChatGptManualJsonScreen> {
  final _service = ChatGptSessionService();
  final _jsonController = TextEditingController();
  bool _isSaving = false;
  String? _jsonError;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) {
      setState(() => _jsonError = 'Vui lòng nhập JSON session.');
      return;
    }
    setState(() {
      _isSaving = true;
      _jsonError = null;
    });
    try {
      final session = await _service.createFromJson(raw);
      await ChatGptSessionStorage.save(session);
      if (!mounted) return;
      Toastr.success('Đã lưu session: ${session.email}', context: context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _jsonError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhập JSON thủ công')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Hướng dẫn',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Truy cập chatgpt.com/api/auth/session trong trình duyệt\n'
                      '2. Copy toàn bộ JSON trả về\n'
                      '3. Paste vào ô bên dưới và nhấn Lưu\n\n'
                      'JSON cần có trường "accessToken" để xác thực.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jsonController,
              maxLines: 14,
              minLines: 8,
              decoration: InputDecoration(
                hintText:
                    '{\n  "accessToken": "...",\n  "expires": "...",\n  ...\n}',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                errorText: _jsonError,
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              onChanged: (_) {
                if (_jsonError != null) setState(() => _jsonError = null);
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Đang xác thực...' : 'Lưu session'),
            ),
          ],
        ),
      ),
    );
  }
}
