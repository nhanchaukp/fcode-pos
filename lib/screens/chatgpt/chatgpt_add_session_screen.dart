import 'package:fcode_pos/services/chatgpt_session_service.dart';
import 'package:fcode_pos/storage/chatgpt_session_storage.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ChatGptAddSessionScreen extends StatefulWidget {
  const ChatGptAddSessionScreen({super.key});

  @override
  State<ChatGptAddSessionScreen> createState() =>
      _ChatGptAddSessionScreenState();
}

class _ChatGptAddSessionScreenState extends State<ChatGptAddSessionScreen> {
  final _service = ChatGptSessionService();
  InAppWebViewController? _webController;

  bool _isLoggedIn = false;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _cookiesCleared = false;
  String? _currentUrl;

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

  @override
  void dispose() {
    super.dispose();
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    if (url == null) return;
    final urlStr = url.toString();
    setState(() {
      _currentUrl = urlStr;
      _isLoading = false;
      // Phát hiện đăng nhập thành công: URL về root và không phải trang login
      _isLoggedIn = _detectLoggedIn(urlStr);
    });
  }

  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    if (url == null) return;
    setState(() {
      _isLoading = true;
      _currentUrl = url.toString();
      if (!_detectLoggedIn(url.toString())) {
        _isLoggedIn = false;
      }
    });
  }

  bool _detectLoggedIn(String url) {
    return (url == _chatgptHome || url.startsWith('https://chatgpt.com/?') || url.startsWith('https://chatgpt.com/#')) &&
        !url.contains('/auth/') &&
        !url.contains('/login');
  }

  Future<void> _saveSession() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final session = await _service.captureSession();
      await ChatGptSessionStorage.save(session);

      if (!mounted) return;
      Toastr.success('Đã lưu session cho ${session.email}', context: context);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đăng nhập ChatGPT'),
            if (_currentUrl != null)
              Text(
                _currentUrl!.length > 40
                    ? '${_currentUrl!.substring(0, 40)}...'
                    : _currentUrl!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
          ],
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          if (_isLoggedIn)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _saveSession,
                    icon: const Icon(Icons.save, color: Colors.white, size: 18),
                    label: const Text(
                      'Lưu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                  initialUrlRequest: URLRequest(
                    url: WebUri(_chatgptHome),
                  ),
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
                  onWebViewCreated: (controller) {
                    _webController = controller;
                  },
                  onLoadStart: _onLoadStart,
                  onLoadStop: _onLoadStop,
                  onReceivedError: (controller, request, error) {
                    if (mounted) setState(() => _isLoading = false);
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
