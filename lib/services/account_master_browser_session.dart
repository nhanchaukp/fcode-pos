import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_master_browser_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef AccountMasterBrowserExpandCallback = Future<AccountMaster?> Function(
  BuildContext context,
  AccountMasterBrowserSession session,
);

/// Keeps an in-app browser session alive while minimized (headless WebView).
class AccountMasterBrowserSession {
  AccountMasterBrowserSession._();

  static AccountMasterBrowserSession? _active;

  static AccountMasterBrowserSession? get active => _active;

  static bool get hasActiveSession => _active != null;

  final _browserService = AccountMasterBrowserService();
  final keepAlive = InAppWebViewKeepAlive();

  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? webController;
  OverlayEntry? _bubbleOverlay;
  bool webPageReady = false;

  AccountMasterBrowserExpandCallback? onExpand;

  late AccountMaster accountMaster;
  late String initialUrl;
  String? pageTitle;
  int loadProgress = 0;

  double bubbleRight = 16;
  double bubbleBottom = 120;

  static Future<AccountMasterBrowserSession> start({
    required AccountMaster accountMaster,
  }) async {
    await _active?._disposeSession();
    _active = AccountMasterBrowserSession._();
    await _active!._initialize(accountMaster);
    return _active!;
  }

  Future<void> _initialize(AccountMaster account) async {
    accountMaster = account;
    initialUrl = AccountMasterBrowserService.resolveInitialUrl(
      serviceType: account.serviceType,
      details: account.details,
    );
    await _browserService.clearSession();
    await _runHeadlessAtUrl(initialUrl, injectAccountCookies: true);
  }

  Future<void> _runHeadlessAtUrl(
    String url, {
    required bool injectAccountCookies,
  }) async {
    await _headlessWebView?.dispose();
    _headlessWebView = null;
    webController = null;

    final headless = HeadlessInAppWebView(
      initialSettings: AccountMasterBrowserService.defaultSettings(),
      onWebViewCreated: (controller) async {
        webController = controller;
        if (injectAccountCookies) {
          await _browserService.injectCookies(
            cookies: accountMaster.cookies,
            url: url,
            webViewController: controller,
          );
        }
        await controller.loadUrl(
          urlRequest: URLRequest(url: WebUri(url)),
        );
      },
      onLoadStart: (_, _) => _setLoadProgress(0),
      onProgressChanged: (_, progress) => _setLoadProgress(progress),
      onLoadStop: (_, _) => _markPageReady(),
      onTitleChanged: (_, title) {
        final trimmed = title?.trim() ?? '';
        if (trimmed.isNotEmpty) {
          pageTitle = trimmed;
          _bubbleOverlay?.markNeedsBuild();
        }
      },
      onReceivedServerTrustAuthRequest:
          AccountMasterBrowserService.handleServerTrustAuthRequest,
      onReceivedError: (_, _, _) => _setLoadProgress(100),
    );

    _headlessWebView = headless;
    await headless.run();
  }

  void _setLoadProgress(int progress) {
    loadProgress = progress;
    _bubbleOverlay?.markNeedsBuild();
  }

  void _markPageReady() {
    webPageReady = true;
    loadProgress = 100;
    _bubbleOverlay?.markNeedsBuild();
  }

  void markPageReady() => _markPageReady();

  bool get canAttachWebView => headlessWebView != null || webPageReady;

  HeadlessInAppWebView? get headlessWebView {
    final headless = _headlessWebView;
    if (headless != null && headless.isRunning()) {
      return headless;
    }
    return null;
  }

  void updateAccountMaster(AccountMaster account) {
    accountMaster = account;
    _bubbleOverlay?.markNeedsBuild();
  }

  Future<void> minimize(BuildContext context) async {
    if (!context.mounted) return;
    _showBubble(context);
  }

  void _showBubble(BuildContext context) {
    _hideBubble();
    final overlay = Overlay.of(context);

    _bubbleOverlay = OverlayEntry(
      builder: (overlayContext) {
        final screenSize = MediaQuery.sizeOf(overlayContext);
        final colorScheme = Theme.of(overlayContext).colorScheme;
        final isLoading = loadProgress < 100;

        return Positioned(
          right: bubbleRight,
          bottom: bubbleBottom,
          child: GestureDetector(
            onPanUpdate: (details) {
              bubbleRight = (bubbleRight - details.delta.dx)
                  .clamp(8.0, screenSize.width - 72);
              bubbleBottom = (bubbleBottom - details.delta.dy)
                  .clamp(8.0, screenSize.height - 72);
              _bubbleOverlay?.markNeedsBuild();
            },
            onTap: () => _expandFromBubble(overlayContext),
            child: Material(
              elevation: 6,
              shadowColor: Colors.black45,
              shape: const CircleBorder(),
              color: colorScheme.primary,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.public,
                      color: Colors.white,
                      size: 26,
                    ),
                    if (isLoading)
                      const Positioned(
                        right: 6,
                        top: 6,
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_bubbleOverlay!);
  }

  void _hideBubble() {
    _bubbleOverlay?.remove();
    _bubbleOverlay = null;
  }

  Future<void> _expandFromBubble(BuildContext context) async {
    _hideBubble();
    final expand = onExpand;
    if (expand == null || !context.mounted) return;
    await expand(context, this);
  }

  Future<void> close() async {
    await _disposeSession();
  }

  Future<void> _disposeSession() async {
    _hideBubble();
    await InAppWebViewController.disposeKeepAlive(keepAlive);
    await _headlessWebView?.dispose();
    _headlessWebView = null;
    webController = null;
    webPageReady = false;
    if (_active == this) {
      _active = null;
    }
  }

  static Future<void> closeActive() =>
      _active?._disposeSession() ?? Future.value();
}