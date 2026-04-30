import 'package:fcode_pos/models/chatgpt_models.dart';
import 'package:fcode_pos/services/chatgpt_session_service.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Mở chatgpt.com với cookies đã lưu được inject vào WebView.
class ChatGptBrowserScreen extends StatefulWidget {
  const ChatGptBrowserScreen({super.key, required this.session});

  final ChatGptSession session;

  @override
  State<ChatGptBrowserScreen> createState() => _ChatGptBrowserScreenState();
}

class _ChatGptBrowserScreenState extends State<ChatGptBrowserScreen> {
  final _service = ChatGptSessionService();
  InAppWebViewController? _webController;

  bool _isLoading = true;
  bool _cookiesInjected = false;
  String? _currentUrl;

  static const _chatgptHome = 'https://chatgpt.com/';

  @override
  void initState() {
    super.initState();
    _injectCookiesAndLoad();
  }

  Future<void> _injectCookiesAndLoad() async {
    try {
      await _service.injectCookies(widget.session);
      setState(() => _cookiesInjected = true);
    } catch (e) {
      debugPrint('[ChatGptBrowser] inject cookies error: $e');
      if (mounted) {
        Toastr.error('Lỗi inject cookies: $e', context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.session.name),
            if (_currentUrl != null)
              Text(
                _currentUrl!.length > 40
                    ? '${_currentUrl!.substring(0, 40)}...'
                    : _currentUrl!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white70),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => _webController?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            tooltip: 'Quay lại',
            onPressed: () async {
              if (await _webController?.canGoBack() == true) {
                _webController?.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: 'Tiến',
            onPressed: () async {
              if (await _webController?.canGoForward() == true) {
                _webController?.goForward();
              }
            },
          ),
        ],
      ),
      body: _cookiesInjected
          ? InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_chatgptHome)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
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
              onLoadStart: (controller, url) {
                setState(() {
                  _isLoading = true;
                  _currentUrl = url?.toString();
                });
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                  _currentUrl = url?.toString();
                });
              },
              onReceivedError: (controller, request, error) {
                if (mounted) setState(() => _isLoading = false);
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang inject cookies...'),
                ],
              ),
            ),
    );
  }
}
