import 'package:fcode_pos/enums.dart' as enums;
import 'package:fcode_pos/models/dto/account_master_data.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_master_browser_service.dart';
import 'package:fcode_pos/services/account_master_browser_session.dart';
import 'package:fcode_pos/services/account_master_service.dart';
import 'package:fcode_pos/ui/components/in_app_browser.dart' as app_browser;
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';

class _BrowserConsoleLog {
  final String message;
  final ConsoleMessageLevel level;
  final DateTime timestamp;

  const _BrowserConsoleLog({
    required this.message,
    required this.level,
    required this.timestamp,
  });
}

class AccountMasterBrowserScreen extends StatefulWidget {
  final AccountMasterBrowserSession session;

  const AccountMasterBrowserScreen({super.key, required this.session});

  @override
  State<AccountMasterBrowserScreen> createState() =>
      _AccountMasterBrowserScreenState();
}

class _AccountMasterBrowserScreenState
    extends State<AccountMasterBrowserScreen> {
  final _browserService = AccountMasterBrowserService();
  final _accountMasterService = AccountMasterService();

  InAppWebViewController? _webController;
  Widget? _webViewWidget;
  bool _webViewAttached = false;

  late AccountMaster _accountMaster;
  late String _initialUrl;
  String? _pageTitle;
  int _loadProgress = 0;
  bool _isSaving = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  double _headerDragDelta = 0;
  bool _isEditingAddress = false;
  late final TextEditingController _addressController;
  late final FocusNode _addressFocusNode;
  final List<_BrowserConsoleLog> _consoleLogs = [];

  AccountMasterBrowserSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _accountMaster = _session.accountMaster;
    _initialUrl = _session.initialUrl;
    _pageTitle = _session.pageTitle;
    _loadProgress = _session.webPageReady ? 100 : _session.loadProgress;
    _webController = _session.webController;
    _addressController = TextEditingController(text: _initialUrl);
    _addressFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _addressFocusNode.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    _webController = controller;
    _session.webController = controller;

    final isRestoredSession = _session.webPageReady;
    if (mounted) {
      setState(() {
        _webViewAttached = true;
        _loadProgress = isRestoredSession ? 100 : _session.loadProgress;
      });
    }
    final currentUrl = await controller.getUrl();
    _syncAddressBar(currentUrl);
    await _updateNavigationState();
  }

  void _onLoadStart(InAppWebViewController _, WebUri? url) {
    if (!mounted) return;
    _session.loadProgress = 0;
    setState(() => _loadProgress = 0);
  }

  void _onProgressChanged(InAppWebViewController _, int progress) {
    if (!mounted) return;
    _session.loadProgress = progress;
    setState(() => _loadProgress = progress);
  }

  void _onLoadStop(InAppWebViewController _, WebUri? url) {
    if (!mounted) return;
    _session.markPageReady();
    _syncAddressBar(url);
    setState(() => _loadProgress = 100);
    _updateNavigationState();
  }

  void _syncAddressBar(WebUri? url) {
    final value = url?.toString() ?? _initialUrl;
    if (_addressController.text != value) {
      _addressController.text = value;
    }
  }

  Future<void> _showAddressEditor() async {
    final currentUrl = await _webController?.getUrl();
    _syncAddressBar(currentUrl);
    if (!mounted) return;

    setState(() => _isEditingAddress = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _addressFocusNode.requestFocus();
      _addressController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _addressController.text.length,
      );
    });
  }

  Future<void> _hideAddressEditor() async {
    if (!_isEditingAddress) return;
    _addressFocusNode.unfocus();
    _syncAddressBar(await _webController?.getUrl());
    if (!mounted) return;
    setState(() => _isEditingAddress = false);
  }

  Future<void> _navigateToAddress(String input) async {
    final url = AccountMasterBrowserService.normalizeUrl(input);
    if (url == null) {
      Toastr.error('Địa chỉ web không hợp lệ', context: context);
      return;
    }

    await _hideAddressEditor();
    await _webController?.clearFocus();
    FocusManager.instance.primaryFocus?.unfocus();
    await _webController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void _onTitleChanged(InAppWebViewController _, String? title) {
    if (!mounted) return;

    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) return;

    _session.pageTitle = trimmed;
    setState(() => _pageTitle = trimmed);
  }

  Future<void> _updateNavigationState() async {
    final controller = _webController;
    if (controller == null || !mounted) return;

    final canGoBack = await controller.canGoBack();
    final canGoForward = await controller.canGoForward();
    if (!mounted) return;

    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _goBack() async {
    if (!_canGoBack) return;
    await _webController?.goBack();
    await _updateNavigationState();
  }

  Future<void> _goForward() async {
    if (!_canGoForward) return;
    await _webController?.goForward();
    await _updateNavigationState();
  }

  Future<void> _exitBrowser() async {
    await AccountMasterBrowserSession.closeActive();
    if (!mounted) return;
    Navigator.of(context).pop(_accountMaster);
  }

  Future<void> _minimizeBrowser() async {
    await _session.minimize(context);
    if (!mounted) return;
    Navigator.of(context).pop(_accountMaster);
  }

  void _onHeaderDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy <= 0) return;
    _headerDragDelta += details.delta.dy;
  }

  void _onHeaderDragEnd(DragEndDetails details) {
    final shouldMinimize =
        _headerDragDelta > 56 || details.velocity.pixelsPerSecond.dy > 700;
    _headerDragDelta = 0;

    if (shouldMinimize) {
      _minimizeBrowser();
    }
  }

  void _onConsoleMessage(InAppWebViewController _, ConsoleMessage message) {
    if (!mounted) return;
    setState(() {
      _consoleLogs.insert(
        0,
        _BrowserConsoleLog(
          message: message.message,
          level: message.messageLevel,
          timestamp: DateTime.now(),
        ),
      );
      if (_consoleLogs.length > 500) {
        _consoleLogs.removeRange(500, _consoleLogs.length);
      }
    });
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'account_info':
        _showAccountInfo();
      case 'get_all_code':
        _showGetAllCodeBottomSheet();
      case 'save_cookie':
        _saveCookies();
      case 'macro_scripts':
        _showMacroSheet();
      case 'reload':
        _webController?.reload();
      case 'minimize':
        _minimizeBrowser();
      case 'console_log':
        _showConsoleLog();
      case 'exit':
        _exitBrowser();
    }
  }

  Future<void> _saveCookies() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final currentUrl = await _webController?.getUrl();
      final cookies = await _browserService.captureCookiesAsString(
        relatedUrl: currentUrl?.toString() ?? _initialUrl,
      );
      if (cookies.isEmpty) {
        throw Exception('Không tìm thấy cookie trong phiên hiện tại.');
      }

      final account = _accountMaster;
      final data = AccountMasterData(
        name: account.name,
        username: account.username,
        password: account.password,
        serviceType: account.serviceType,
        maxSlots: account.maxSlots,
        notes: account.notes,
        paymentDate: account.paymentDate,
        monthlyCost: account.monthlyCost,
        costNotes: account.costNotes,
        isActive: account.isActive,
        showPassword: account.showPassword,
        cookies: cookies,
        details: account.details,
        supplyId: account.supply?.id,
      );

      final response = await _accountMasterService.update(account.id, data);
      if (!mounted) return;

      final updated =
          response.data ??
          AccountMaster(
            id: account.id,
            name: account.name,
            username: account.username,
            password: account.password,
            serviceType: account.serviceType,
            maxSlots: account.maxSlots,
            notes: account.notes,
            paymentDate: account.paymentDate,
            monthlyCost: account.monthlyCost,
            costNotes: account.costNotes,
            isActive: account.isActive,
            showPassword: account.showPassword,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt,
            cookies: cookies,
            details: account.details,
            slots: account.slots,
            slotsCount: account.slotsCount,
            externalSrc: account.externalSrc,
            externalConfig: account.externalConfig,
            supply: account.supply,
          );
      setState(() => _accountMaster = updated);
      _session.updateAccountMaster(updated);
      Toastr.success('Đã lưu cookie cho tài khoản', context: context);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: $e', context: context);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showConsoleLog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Console log',
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_consoleLogs.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            final text = _consoleLogs
                                .map(
                                  (log) =>
                                      '[${_formatLogTime(log.timestamp)}] '
                                      '${_levelLabel(log.level)}: ${log.message}',
                                )
                                .join('\n');
                            Clipboard.setData(ClipboardData(text: text));
                            Toastr.success(
                              'Đã sao chép console log',
                              context: sheetContext,
                            );
                          },
                          child: const Text('Sao chép'),
                        ),
                      TextButton(
                        onPressed: _consoleLogs.isEmpty
                            ? null
                            : () {
                                setState(() => _consoleLogs.clear());
                                Navigator.of(sheetContext).pop();
                              },
                        child: const Text('Xóa'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _consoleLogs.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có log từ trang web',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _consoleLogs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final log = _consoleLogs[index];
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _levelColor(
                                    log.level,
                                    colorScheme,
                                  ).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _levelColor(
                                            log.level,
                                            colorScheme,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _levelLabel(log.level),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _levelColor(
                                              log.level,
                                              colorScheme,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatLogTime(log.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    log.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatLogTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  String _levelLabel(ConsoleMessageLevel level) {
    if (level == ConsoleMessageLevel.ERROR) return 'ERROR';
    if (level == ConsoleMessageLevel.WARNING) return 'WARN';
    if (level == ConsoleMessageLevel.DEBUG) return 'DEBUG';
    if (level == ConsoleMessageLevel.TIP) return 'TIP';
    return 'LOG';
  }

  Color _levelColor(ConsoleMessageLevel level, ColorScheme colorScheme) {
    if (level == ConsoleMessageLevel.ERROR) return colorScheme.error;
    if (level == ConsoleMessageLevel.WARNING) return Colors.orange;
    if (level == ConsoleMessageLevel.DEBUG) return colorScheme.outline;
    return colorScheme.primary;
  }

  Future<void> _showAccountInfo() async {
    await _webController?.clearFocus();
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;

    final account = _accountMaster;
    final serviceTypeLabel = enums.AccountMasterServiceType.values
        .firstWhere(
          (type) => type.value == account.serviceType,
          orElse: () => enums.AccountMasterServiceType.values.first,
        )
        .label;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Thông tin tài khoản master',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCopyableInfoRow(
                  sheetContext,
                  label: 'Username',
                  value: account.username,
                ),
                _buildCopyableInfoRow(
                  sheetContext,
                  label: 'Password',
                  value: account.password,
                ),
                if (account.twoFactorSecret != null &&
                    account.twoFactorSecret!.isNotEmpty)
                  _buildCopyableInfoRow(
                    sheetContext,
                    label: '2FA Secret',
                    value: account.twoFactorSecret!,
                  ),
                _buildInfoRow('Loại dịch vụ', serviceTypeLabel),
                _buildInfoRow(
                  'Trạng thái',
                  account.isActive ? 'Đang hoạt động' : 'Không hoạt động',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    Toastr.success('Đã sao chép $label', context: context);
  }

  Widget _buildCopyableInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: 'Sao chép $label',
            visualDensity: VisualDensity.compact,
            onPressed: () => _copyToClipboard(context, label, value),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showMacroSheet() {
    final account = _accountMaster;
    final serviceType = account.serviceType;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Macro Scripts',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Chọn kịch bản tự động hóa cho trang web',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (serviceType == 'netflix') ...[
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: const Text('Netflix: Đăng xuất thiết bị theo Profile'),
                  subtitle: const Text(
                    'Tự động tải danh sách và đăng xuất thiết bị của Profile chỉ định',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _runNetflixLogoutDevicesMacro();
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Xóa Session Storage & Tải lại'),
                subtitle: const Text(
                  'Xóa LocalStorage, SessionStorage và tải lại trang',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _webController?.evaluateJavascript(
                    source: '''
                      localStorage.clear();
                      sessionStorage.clear();
                      location.reload();
                    ''',
                  );
                  if (mounted) {
                    Toastr.success(
                      'Đã xóa Session Storage & tải lại trang',
                      context: context,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runNetflixLogoutDevicesMacro() async {
    final slots = _accountMaster.slots ?? [];
    final slotNames = slots
        .map((s) => s.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final textController = TextEditingController(
      text: slotNames.isNotEmpty ? slotNames.first : '1',
    );

    final selectedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Đăng xuất thiết bị Netflix'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập tên Profile (Hồ sơ) cần đăng xuất các thiết bị khỏi tài khoản Netflix:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Tên Profile',
                      hintText: 'Ví dụ: 1, 2, Profile A...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (slotNames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Gợi ý từ danh sách Slot:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: slotNames.map((name) {
                        return ActionChip(
                          label: Text(name),
                          onPressed: () {
                            textController.text = name;
                            setDialogState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Chạy Macro'),
                  onPressed: () {
                    final value = textController.text.trim();
                    if (value.isNotEmpty) {
                      Navigator.of(dialogContext).pop(value);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedName == null || selectedName.isEmpty || !mounted) return;

    Toastr.info(
      'Đang chạy Macro đăng xuất hồ sơ "$selectedName"...',
      context: context,
    );

    final script =
        '''
      (async function(profileName) {
        if (!profileName || !profileName.trim()) {
          console.error("[Macro] Vui lòng nhập tên hồ sơ!");
          return { success: false, message: "Chưa nhập tên hồ sơ" };
        }
        
        if (!location.href.includes('/manageaccountaccess')) {
          console.log("[Macro] Đang chuyển hướng tới trang Quản lý thiết bị Netflix...");
          location.href = 'https://www.netflix.com/manageaccountaccess';
          return { success: false, message: "Đã chuyển hướng trang. Hãy đợi trang tải xong và bấm chạy lại macro." };
        }

        console.log(`[Macro] Bắt đầu tìm và đăng xuất thiết bị của hồ sơ: "\${profileName}"...`);
        const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

        let expandCount = 0;
        while (expandCount < 30) {
          const showMoreBtn = document.querySelector('button[data-uia\$="show-more-button"]');

          if (showMoreBtn && !showMoreBtn.disabled && showMoreBtn.offsetHeight > 0) {
            showMoreBtn.click();
            expandCount++;
            await sleep(1200);
          } else {
            break;
          }
        }

        const expandButtons = document.querySelectorAll('button[data-uia^="device-list"]');
        for (const btn of expandButtons) {
          btn.click();
          await sleep(150);
        }

        const deviceItems = document.querySelectorAll('li[data-uia^="device-list+"]');
        let signedOutCount = 0;
        const targetNameLower = profileName.trim().toLowerCase();

        for (const li of deviceItems) {
          const profileEl = li.querySelector('p[data-uia\$="profile-name"]');
          const profileText = (profileEl?.textContent || '').trim().toLowerCase();

          if (profileText.includes(targetNameLower)) {
            const deviceName = li.querySelector('h3[data-uia\$="title"]')?.textContent?.trim() || 'Thiết bị';
            const signOutBtn = li.querySelector('button[data-uia\$="sign-out-button"]');
            
            if (signOutBtn) {
              li.scrollIntoView({ behavior: 'smooth', block: 'center' });
              signOutBtn.click();
              signedOutCount++;
              console.log(`[Macro] Đã đăng xuất hồ sơ "\${profileName}" khỏi: \${deviceName}`);
              await sleep(500);
            }
          }
        }

        console.log(`[Macro] Hoàn tất! Đã đăng xuất \${signedOutCount} thiết bị của hồ sơ "\${profileName}".`);
        return { success: true, count: signedOutCount };
      })('${selectedName.replaceAll("'", "\\'")}');
    ''';

    try {
      await _webController?.evaluateJavascript(source: script);
      if (mounted) {
        Toastr.success(
          'Đã gửi kịch bản đăng xuất đến trình duyệt. Mở Console Log để xem chi tiết.',
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        Toastr.error('Lỗi khi chạy kịch bản: $e', context: context);
      }
    }
  }

  PreferredSizeWidget _buildBrowserAppBar() {
    final account = _accountMaster;
    final colorScheme = Theme.of(context).colorScheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(_headerHeight),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: _onHeaderDragUpdate,
        onVerticalDragEnd: _onHeaderDragEnd,
        child: Material(
          color: colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AppBar(
                  automaticallyImplyLeading: false,
                  leadingWidth: _isEditingAddress ? 40 : 0,
                  leading: _isEditingAddress
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: 'Hủy nhập địa chỉ',
                          onPressed: _hideAddressEditor,
                        )
                      : null,
                  title: _isEditingAddress
                      ? TextField(
                          controller: _addressController,
                          focusNode: _addressFocusNode,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: 'Nhập địa chỉ web...',
                            prefixIcon: Icon(
                              Icons.public,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                          ),
                          onSubmitted: _navigateToAddress,
                        )
                      : GestureDetector(
                          onTap: _showAddressEditor,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _pageTitle ?? _initialUrl,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                  actions: _buildAppBarActions(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_isSaving)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'account_info',
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 12),
                Text('Thông tin tài khoản'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'save_cookie',
            enabled: !_isSaving,
            child: const Row(
              children: [
                Icon(Icons.save_outlined, size: 18),
                SizedBox(width: 12),
                Text('Lưu cookie'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'macro_scripts',
            child: Row(
              children: [
                Icon(Icons.play_circle_outline, size: 18),
                SizedBox(width: 12),
                Text('Macro Scripts'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'minimize',
            child: Row(
              children: [
                Icon(Icons.picture_in_picture_alt, size: 18),
                SizedBox(width: 12),
                Text('Thu nhỏ'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'reload',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 12),
                Text('Tải lại'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'console_log',
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 18),
                const SizedBox(width: 12),
                const Text('Console log'),
                if (_consoleLogs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_consoleLogs.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'exit',
            child: Row(
              children: [
                Icon(Icons.close, size: 18),
                SizedBox(width: 12),
                Text('Thoát'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static const _headerHeight = kToolbarHeight + 10;
  static const _toolbarHeight = _headerHeight;

  double _webViewTop(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final progressHeight = _loadProgress < 100 ? 2.0 : 0.0;
    return topInset + _toolbarHeight + progressHeight;
  }

  bool get _canShowWebView => _webViewAttached || _session.canAttachWebView;

  bool get _isNetflix =>
      _accountMaster.serviceType ==
          enums.AccountMasterServiceType.netflix.value ||
      _accountMaster.serviceType == 'netflix';

  void _showGetAllCodeBottomSheet() {
    showGetAllCodeBottomSheet(
      context,
      accountMaster: _accountMaster,
      accountMasterService: _accountMasterService,
      webController: _webController,
    );
  }

  double _bottomBarHeight(BuildContext context) {
    return 56.0 + MediaQuery.paddingOf(context).bottom;
  }

  Widget _buildBottomBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: _bottomBarHeight(context),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Quay lại',
            onPressed: _canGoBack ? _goBack : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Tiến tới',
            onPressed: _canGoForward ? _goForward : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại trang',
            onPressed: () => _webController?.reload(),
          ),
          if (_isNetflix)
            FilledButton.icon(
              onPressed: _showGetAllCodeBottomSheet,
              icon: const Icon(Icons.key, size: 18),
              label: const Text('Lấy mã'),
            ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Macro Scripts',
            onPressed: _showMacroSheet,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Thông tin tài khoản',
            onPressed: _showAccountInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildInAppWebView() {
    if (_webViewWidget != null) {
      return _webViewWidget!;
    }

    if (!_session.canAttachWebView) {
      return const SizedBox.shrink();
    }

    _webViewWidget = InAppWebView(
      keepAlive: _session.keepAlive,
      headlessWebView: _session.headlessWebView,
      initialSettings: AccountMasterBrowserService.defaultSettings(),
      onWebViewCreated: _onWebViewCreated,
      onLoadStart: _onLoadStart,
      onProgressChanged: _onProgressChanged,
      onLoadStop: _onLoadStop,
      onTitleChanged: _onTitleChanged,
      onUpdateVisitedHistory: (controller, url, _) {
        _syncAddressBar(url);
        _updateNavigationState();
      },
      onReceivedServerTrustAuthRequest:
          AccountMasterBrowserService.handleServerTrustAuthRequest,
      onConsoleMessage: _onConsoleMessage,
      onReceivedError: (_, _, _) {
        if (mounted) setState(() => _loadProgress = 100);
      },
    );
    return _webViewWidget!;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final webViewTop = _webViewTop(context);
    final canShowWebView = _canShowWebView;
    final bottomBarHeight = _bottomBarHeight(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isEditingAddress) {
          await _hideAddressEditor();
          return;
        }
        if (_canGoBack) {
          await _goBack();
        } else {
          await _exitBrowser();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: colorScheme.surface,
            child: Scaffold(
              appBar: _buildBrowserAppBar(),
              body: !canShowWebView
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang chuẩn bị trình duyệt...'),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        if (_loadProgress < 100)
                          LinearProgressIndicator(
                            minHeight: 2,
                            value: _loadProgress > 0
                                ? _loadProgress / 100
                                : null,
                          ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
              bottomNavigationBar: _buildBottomBar(context),
            ),
          ),
          if (canShowWebView)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomBarHeight,
              top: webViewTop,
              child: _buildInAppWebView(),
            ),
        ],
      ),
    );
  }
}

void showGetAllCodeBottomSheet(
  BuildContext context, {
  required AccountMaster accountMaster,
  AccountMasterService? accountMasterService,
  InAppWebViewController? webController,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return GetAllCodeBottomSheet(
        accountMaster: accountMaster,
        accountMasterService: accountMasterService ?? AccountMasterService(),
        webController: webController,
      );
    },
  );
}

class GetAllCodeBottomSheet extends StatefulWidget {
  final AccountMaster accountMaster;
  final AccountMasterService accountMasterService;
  final InAppWebViewController? webController;

  const GetAllCodeBottomSheet({
    super.key,
    required this.accountMaster,
    required this.accountMasterService,
    this.webController,
  });

  @override
  State<GetAllCodeBottomSheet> createState() => _GetAllCodeBottomSheetState();
}

class _GetAllCodeBottomSheetState extends State<GetAllCodeBottomSheet> {
  bool _isLoading = true;
  String? _error;
  List<AccountMasterCodeItem>? _items;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.accountMasterService.getAllCode(
        widget.accountMaster.id,
      );
      if (!mounted) return;

      if (response.success) {
        setState(() {
          _items = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Không thể lấy danh sách mã';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Toastr.success('Đã sao chép $label', context: context);
  }

  String? _formatItemTime(AccountMasterCodeItem item) {
    if (item.createdAt != null) {
      return DateFormat('HH:mm dd/MM/yyyy').format(item.createdAt!.toLocal());
    }
    return item.rawCreatedAt;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (sheetContext, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.vpn_key_outlined,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã & Link xác minh',
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.accountMaster.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Tải lại mã',
                    onPressed: _isLoading ? null : _fetchData,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildBody(sheetContext, scrollController, colorScheme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScrollController scrollController,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang gọi API lấy mã...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _items;
    if (items == null || items.isEmpty) {
      return const Center(child: Text('Không tìm thấy mã hoặc link nào'));
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return _buildCodeCard(ctx, colorScheme, item, index: index + 1);
      },
    );
  }

  Widget _buildCodeCard(
    BuildContext context,
    ColorScheme colorScheme,
    AccountMasterCodeItem item, {
    required int index,
  }) {
    final hasCode = item.code != null && item.code!.trim().isNotEmpty;
    final hasLink = item.link != null && item.link!.trim().isNotEmpty;
    final hasMessage = item.message != null && item.message!.trim().isNotEmpty;
    final formattedTime = _formatItemTime(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header - Badge index & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mã #$index',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (formattedTime != null && formattedTime.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Message / Title line
            if (hasMessage) ...[
              const SizedBox(height: 8),
              Text(
                item.message!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],

            // Verification Code Block
            if (hasCode) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _copyToClipboard(context, item.code!, 'mã'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          item.code!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Sao chép mã',
                        onPressed: () =>
                            _copyToClipboard(context, item.code!, 'mã'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Clickable Link Block
            if (hasLink) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  if (widget.webController != null) {
                    Navigator.of(context).pop();
                    widget.webController?.loadUrl(
                      urlRequest: URLRequest(url: WebUri(item.link!)),
                    );
                  } else {
                    app_browser.InAppBrowser.open(
                      context,
                      url: item.link!,
                      title: 'Link xác minh',
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.link!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.tertiary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: colorScheme.tertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
