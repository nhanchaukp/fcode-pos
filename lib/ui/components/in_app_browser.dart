import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// Màn hình trình duyệt in-app dùng lại được, dựa trên [AppScaffold].
class InAppBrowser extends StatefulWidget {
  const InAppBrowser({
    super.key,
    required this.url,
    this.title,
  });

  final String url;
  final String? title;

  /// Mở trình duyệt in-app bằng [Navigator.push].
  static Future<T?> open<T>(
    BuildContext context, {
    required String url,
    String? title,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => InAppBrowser(url: url, title: title),
      ),
    );
  }

  @override
  State<InAppBrowser> createState() => _InAppBrowserState();
}

class _InAppBrowserState extends State<InAppBrowser> {
  InAppWebViewController? _controller;
  double _progress = 0;
  late String _currentUrl;
  String? _pageTitle;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _pageTitle = widget.title;
  }

  Future<void> _refreshNavState() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final canBack = await controller.canGoBack();
    final canForward = await controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = canBack;
      _canGoForward = canForward;
    });
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(_currentUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      Toastr.error('Không thể mở liên kết', context: context);
    }
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _currentUrl));
    Toastr.success('Đã sao chép URL', context: context);
  }

  @override
  Widget build(BuildContext context) {
    final title = (_pageTitle?.trim().isNotEmpty ?? false)
        ? _pageTitle!
        : 'Trình duyệt';

    return AppScaffold(
      title: title,
      subtitle: _currentUrl,
      actions: [
        IconButton(
          tooltip: 'Quay lại',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: _canGoBack ? () => _controller?.goBack() : null,
        ),
        IconButton(
          tooltip: 'Tiến tới',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: _canGoForward ? () => _controller?.goForward() : null,
        ),
        IconButton(
          tooltip: 'Tải lại',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => _controller?.reload(),
        ),
        PopupMenuButton<_BrowserAction>(
          tooltip: 'Thêm',
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (action) {
            switch (action) {
              case _BrowserAction.copyUrl:
                _copyUrl();
              case _BrowserAction.openExternal:
                _openExternal();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _BrowserAction.copyUrl,
              child: Text('Sao chép URL'),
            ),
            PopupMenuItem(
              value: _BrowserAction.openExternal,
              child: Text('Mở bằng trình duyệt'),
            ),
          ],
        ),
      ],
      body: (context, _) => Column(
        children: [
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(value: _progress, minHeight: 2),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useShouldOverrideUrlLoading: false,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                supportZoom: true,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onLoadStart: (_, url) {
                if (!mounted) return;
                setState(() {
                  _progress = 0.05;
                  if (url != null) _currentUrl = url.toString();
                });
              },
              onProgressChanged: (_, progress) {
                if (!mounted) return;
                setState(() => _progress = progress / 100);
              },
              onLoadStop: (_, url) async {
                if (!mounted) return;
                setState(() {
                  _progress = 1;
                  if (url != null) _currentUrl = url.toString();
                });
                await _refreshNavState();
              },
              onTitleChanged: (_, title) {
                if (!mounted || title == null || title.isEmpty) return;
                if (widget.title != null && widget.title!.trim().isNotEmpty) {
                  return;
                }
                setState(() => _pageTitle = title);
              },
              onReceivedError: (_, _, _) {
                if (mounted) setState(() => _progress = 1);
              },
              onUpdateVisitedHistory: (_, url, _) {
                if (url != null && mounted) {
                  setState(() => _currentUrl = url.toString());
                }
                _refreshNavState();
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _BrowserAction { copyUrl, openExternal }
