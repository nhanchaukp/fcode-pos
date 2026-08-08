import 'dart:convert';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:fcode_pos/services/fcm_token_service.dart';
import 'package:fcode_pos/services/notification_service.dart';
import 'package:fcode_pos/ui/components/app_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastr_flutter/toastr.dart'
    show
        Toastr,
        ToastrOptions,
        ToastrPosition,
        ToastrShowMethod,
        ToastrHideMethod,
        ToastrConfig,
        ToastrType;

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  ToastrPosition _position = ToastrPosition.topCenter;
  ToastrShowMethod _showMethod = ToastrShowMethod.slideDown;
  ToastrHideMethod _hideMethod = ToastrHideMethod.slideUp;
  bool _showProgress = false;
  bool _showClose = false;
  bool _preventDup = false;
  Duration _duration = const Duration(seconds: 3);

  // FCM Debug State
  String? _fcmToken;
  String? _apnsToken;
  bool _isLoadingFcm = false;
  String? _lastApiResult;

  @override
  void initState() {
    super.initState();
    _fetchFcmTokens();
  }

  Future<void> _fetchFcmTokens() async {
    setState(() => _isLoadingFcm = true);
    try {
      final fcm = await NotificationService.instance.getFCMToken();
      final apns = await NotificationService.instance.getAPNsToken();
      if (mounted) {
        setState(() {
          _fcmToken = fcm;
          _apnsToken = apns;
          _isLoadingFcm = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFcm = false);
      }
    }
  }

  Future<void> _registerFcmTokenManual() async {
    setState(() => _isLoadingFcm = true);
    try {
      final token = _fcmToken ?? await NotificationService.instance.getFCMToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoadingFcm = false);
        _showMockTokenDialog();
        return;
      }

      final res = await FcmTokenService().registerToken(token);
      if (mounted) {
        setState(() {
          _isLoadingFcm = false;
          _lastApiResult = 'POST /api/fcm-token: success=${res.success}, msg=${res.message}, data=${res.data}';
        });
      }

      if (res.success) {
        Toastr.success('Đã gọi API POST /fcm-token thành công!');
      } else {
        Toastr.error('API POST /fcm-token thất bại: ${res.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFcm = false;
          _lastApiResult = 'Lỗi POST /api/fcm-token: $e';
        });
      }
      Toastr.error('Lỗi khi gọi API đăng ký FCM: $e');
    }
  }

  Future<void> _deleteFcmTokenManual() async {
    setState(() => _isLoadingFcm = true);
    try {
      final token = _fcmToken ?? await NotificationService.instance.getFCMToken();
      final res = await FcmTokenService().deleteToken(fcmToken: token);
      if (mounted) {
        setState(() {
          _isLoadingFcm = false;
          _lastApiResult = 'DELETE /api/fcm-token: success=${res.success}, msg=${res.message}';
        });
      }

      if (res.success) {
        Toastr.success('Đã gọi API DELETE /fcm-token thành công!');
      } else {
        Toastr.error('API DELETE /fcm-token thất bại: ${res.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFcm = false;
          _lastApiResult = 'Lỗi DELETE /api/fcm-token: $e';
        });
      }
      Toastr.error('Lỗi khi gọi API xóa FCM: $e');
    }
  }

  void _showMockTokenDialog() {
    final controller = TextEditingController(
      text: 'mock_fcm_token_pos_${DateTime.now().millisecondsSinceEpoch}',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng ký FCM Token Thử nghiệm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thiết bị/Simulator hiện tại chưa lấy được FCM Token từ Firebase SDK. '
              'Bạn có thể gửi Token giả lập để kiểm tra API POST /api/fcm-token:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'Mock FCM Token',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final mockToken = controller.text.trim();
              if (mockToken.isEmpty) return;

              Toastr.info('Đang gửi mock token lên server...');
              try {
                final res = await FcmTokenService().registerToken(mockToken);
                if (mounted) {
                  setState(() {
                    _lastApiResult = 'POST /api/fcm-token (Mock): success=${res.success}, msg=${res.message}, data=${res.data}';
                  });
                }
                if (res.success) {
                  Toastr.success('Thành công! Server: ${res.message}');
                } else {
                  Toastr.error('Thất bại: ${res.message}');
                }
              } catch (e) {
                Toastr.error('Lỗi API: $e');
              }
            },
            child: const Text('Gửi API Server'),
          ),
        ],
      ),
    );
  }

  // ── LOCAL NOTIFICATION TEST HELPERS ────────────────────────────────────────

  void _testNewOrderLocalNotification() {
    final payload = jsonEncode({
      'order_id': '81',
      'order_code': '#DH81',
      'type': 'order_notification',
      'event': 'payment_success',
      'click_action': 'fcode://order/81',
    });
    NotificationService.instance.showLocalNotification(
      title: '🎉 Đơn hàng mới #DH81',
      body: 'Khách hàng: Nguyễn Văn A | Tổng tiền: 250.000đ',
      payload: payload,
    );
    Toastr.success('Đã phát Local Notification đơn hàng mới #DH81');
  }

  void _testStatusUpdateLocalNotification() {
    final payload = jsonEncode({
      'order_id': '81',
      'order_code': '#DH81',
      'type': 'order_notification',
      'event': 'status_updated',
      'click_action': 'fcode://order/81',
    });
    NotificationService.instance.showLocalNotification(
      title: '📦 Cập nhật đơn hàng #DH81 (Hoàn thành)',
      body: 'Đơn hàng #DH81 đã chuyển sang trạng thái Hoàn thành',
      payload: payload,
    );
    Toastr.info('Đã phát Local Notification cập nhật đơn hàng #DH81');
  }

  void _testDelayedLocalNotification() {
    Toastr.info('Sẽ phát thông báo sau 3 giây nữa...');
    final payload = jsonEncode({
      'order_id': '81',
      'click_action': 'fcode://order/81',
    });
    NotificationService.instance.showLocalNotification(
      title: '⏰ Thông báo hẹn giờ (3s)',
      body: 'Bấm vào đây để mở chi tiết đơn hàng #DH81',
      payload: payload,
      delay: const Duration(seconds: 3),
    );
  }

  void _showCustomLocalNotificationDialog() {
    final titleController = TextEditingController(text: '🔔 Thông báo thử nghiệm');
    final bodyController = TextEditingController(text: 'Nội dung thông báo tùy chỉnh từ Developer screen');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bắn Local Notification tùy chỉnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề (Title)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Nội dung (Body)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              NotificationService.instance.showLocalNotification(
                title: titleController.text,
                body: bodyController.text,
              );
              Toastr.success('Đã gửi thông báo local!');
            },
            child: const Text('Phát thông báo ngay'),
          ),
        ],
      ),
    );
  }

  void _applyGlobal() {
    Toastr.configure(
      position: _position,
      showMethod: _showMethod,
      hideMethod: _hideMethod,
      duration: _duration,
      showProgressBar: _showProgress,
      showCloseButton: _showClose,
      preventDuplicates: _preventDup,
    );
  }

  // ── Demos sử dụng trực tiếp Toastr gốc từ package:toastr_flutter ────────────

  void _demoRawLoading() async {
    final id = Toastr.loading('Đang xử lý (toastr gốc)...');
    await Future.delayed(const Duration(seconds: 2));
    Toastr.dismiss(id);
  }

  void _demoRawOptions() {
    Toastr.success(
      'Thành công với duration 6s',
      options: const ToastrOptions(duration: Duration(seconds: 6)),
    );
  }

  void _demoRawWithTitle() {
    Toastr.info(
      'Nội dung thông báo',
      title: 'Tiêu đề',
      options: const ToastrOptions(
        duration: Duration(seconds: 4),
        showProgressBar: true,
      ),
    );
  }

  Future<void> _demoRawPromise() async {
    final result = await Toastr.promise<String>(
      Future.delayed(const Duration(seconds: 2), () => 'kết quả từ raw promise'),
      loading: 'Đang xử lý promise gốc...',
      successBuilder: (data) => 'Thành công: $data',
      errorBuilder: (e) => 'Lỗi: $e',
    );
    Toastr.info('Trả về: $result');
  }

  Future<void> _demoRawPromiseError() async {
    try {
      await Toastr.promise<String>(
        Future.delayed(const Duration(seconds: 2), () => throw Exception('Lỗi mạng mô phỏng')),
        loading: 'Đang thử promise lỗi...',
        success: 'Không nên thấy cái này',
        errorBuilder: (e) => 'Đã bắt lỗi: ${e.toString()}',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deviceType = FcmTokenService.resolveDeviceType();

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── SECTION 1: FIREBASE FCM DEBUG (Collapsible) ─────────────────────
          _buildCollapsibleSection(
            title: 'FIREBASE FCM PUSH NOTIFICATION',
            icon: Icons.cloud_upload_outlined,
            iconColor: colorScheme.primary,
            initiallyExpanded: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.devices, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Device Type: $deviceType',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_isLoadingFcm)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Lấy lại FCM Token',
                        onPressed: _fetchFcmTokens,
                      ),
                  ],
                ),
                const Divider(),
                Text(
                  'FCM Token:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  _fcmToken ?? '(Chưa lấy được Token hoặc đang dùng Simulator)',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: _fcmToken != null ? colorScheme.primary : colorScheme.error,
                  ),
                ),
                if (_fcmToken != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Sao chép FCM Token', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _fcmToken!));
                        Toastr.success('Đã sao chép FCM Token');
                      },
                    ),
                  ),
                if (_apnsToken != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'APNs Token (iOS):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SelectableText(
                    _apnsToken!,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
                if (_lastApiResult != null) ...[
                  const Divider(),
                  Text(
                    'KẾT QUẢ GỌI API GẦN NHẤT:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    _lastApiResult!,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
                const Divider(),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.cloud_upload, size: 16),
                      label: const Text('Đăng ký API POST /fcm-token', style: TextStyle(fontSize: 12)),
                      onPressed: _isLoadingFcm ? null : _registerFcmTokenManual,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: const Text('Gửi Mock Token', style: TextStyle(fontSize: 12)),
                      onPressed: _showMockTokenDialog,
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Xóa API DELETE /fcm-token', style: TextStyle(fontSize: 12)),
                      onPressed: _isLoadingFcm ? null : _deleteFcmTokenManual,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── SECTION 2: LOCAL NOTIFICATION & DEEP LINK TEST (Collapsible) ───
          _buildCollapsibleSection(
            title: 'LOCAL NOTIFICATION & DEEP LINK',
            icon: Icons.notifications_active_outlined,
            iconColor: Colors.orange,
            initiallyExpanded: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
                  icon: const Icon(Icons.shopping_bag, size: 16),
                  label: const Text('Bắn thông báo đơn hàng mới (#DH81)', style: TextStyle(fontSize: 12)),
                  onPressed: _testNewOrderLocalNotification,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync_alt, size: 16),
                  label: const Text('Bắn cập nhật đơn hàng (#DH81)', style: TextStyle(fontSize: 12)),
                  onPressed: _testStatusUpdateLocalNotification,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.timer, size: 16),
                  label: const Text('Hẹn giờ thông báo (3s)', style: TextStyle(fontSize: 12)),
                  onPressed: _testDelayedLocalNotification,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Tùy chỉnh thông báo...', style: TextStyle(fontSize: 12)),
                  onPressed: _showCustomLocalNotificationDialog,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Test Deep Link fcode://order/81', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    DeepLinkService.handleDeepLink('fcode://order/81');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── SECTION 3: TOAST DEMOS (Collapsible) ──────────────────────────
          _buildCollapsibleSection(
            title: 'TOAST NOTIFICATION DEMOS',
            icon: Icons.forum_outlined,
            iconColor: Colors.green,
            initiallyExpanded: false,
            child: Column(
              children: [
                _toastTile(
                  icon: Icons.check_circle_outline,
                  label: 'Success',
                  color: Colors.green,
                  onTap: () => Toastr.success('Thao tác thành công!'),
                ),
                _divider(),
                _toastTile(
                  icon: Icons.info_outline,
                  label: 'Info',
                  color: Colors.blue,
                  onTap: () => Toastr.info('Đây là thông báo thông tin.'),
                ),
                _divider(),
                _toastTile(
                  icon: Icons.warning_amber_outlined,
                  label: 'Warning',
                  color: Colors.orange,
                  onTap: () => Toastr.warning('Cẩn thận! Kiểm tra lại.'),
                ),
                _divider(),
                _toastTile(
                  icon: Icons.error_outline,
                  label: 'Error',
                  color: Colors.red,
                  onTap: () => Toastr.error('Đã xảy ra lỗi!'),
                ),
                _divider(),
                _toastTile(
                  icon: Icons.hourglass_empty,
                  label: 'Promise',
                  color: colorScheme.primary,
                  onTap: () {
                    Toastr.promise(
                      Future.delayed(const Duration(seconds: 2), () => true),
                      loading: 'Đang xử lý...',
                      success: 'Xử lý xong!',
                      error: 'Xử lý thất bại!',
                    );
                  },
                ),
                _divider(),
                _toastTile(
                  icon: Icons.text_fields,
                  label: 'Blank',
                  color: colorScheme.onSurfaceVariant,
                  onTap: () => Toastr.blank('Đây là toast không có icon.'),
                ),
                _divider(),
                _toastTile(
                  icon: Icons.hourglass_top,
                  label: 'Loading + Dismiss thủ công',
                  color: colorScheme.primary,
                  onTap: _demoRawLoading,
                ),
                _divider(),
                _toastTile(
                  icon: Icons.tune,
                  label: 'Success với ToastrOptions',
                  color: Colors.green,
                  onTap: _demoRawOptions,
                ),
                _divider(),
                _toastTile(
                  icon: Icons.title,
                  label: 'Info có title + options',
                  color: Colors.blue,
                  onTap: _demoRawWithTitle,
                ),
                _divider(),
                _toastTile(
                  icon: Icons.auto_awesome,
                  label: 'Promise với builder (gốc)',
                  color: colorScheme.primary,
                  onTap: _demoRawPromise,
                ),
                _divider(),
                _toastTile(
                  icon: Icons.error_outline,
                  label: 'Promise lỗi (errorBuilder)',
                  color: Colors.red,
                  onTap: _demoRawPromiseError,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── SECTION 4: TOAST CONFIGURATION (Collapsible) ─────────────────
          _buildCollapsibleSection(
            title: 'TOASTR GLOBAL CONFIGURATION',
            icon: Icons.settings_outlined,
            iconColor: Colors.purple,
            initiallyExpanded: false,
            child: Column(
              children: [
                _dropdownTile<ToastrPosition>(
                  label: 'Vị trí',
                  value: _position,
                  items: ToastrPosition.values,
                  itemLabel: (p) => p.name,
                  onChanged: (v) => setState(() => _position = v),
                ),
                _divider(),
                _dropdownTile<ToastrShowMethod>(
                  label: 'Hiệu ứng hiện',
                  value: _showMethod,
                  items: ToastrShowMethod.values,
                  itemLabel: (p) => p.name,
                  onChanged: (v) => setState(() => _showMethod = v),
                ),
                _divider(),
                _dropdownTile<ToastrHideMethod>(
                  label: 'Hiệu ứng ẩn',
                  value: _hideMethod,
                  items: ToastrHideMethod.values,
                  itemLabel: (p) => p.name,
                  onChanged: (v) => setState(() => _hideMethod = v),
                ),
                _divider(),
                _dropdownTile<Duration>(
                  label: 'Thời gian hiển thị',
                  value: _duration,
                  items: const [
                    Duration(seconds: 2),
                    Duration(seconds: 3),
                    Duration(seconds: 5),
                    Duration(seconds: 10),
                  ],
                  itemLabel: (d) => '${d.inSeconds}s',
                  onChanged: (v) => setState(() => _duration = v),
                ),
                _divider(),
                _switchTile(
                  label: 'Progress bar',
                  value: _showProgress,
                  onChanged: (v) => setState(() => _showProgress = v),
                ),
                _divider(),
                _switchTile(
                  label: 'Nút đóng',
                  value: _showClose,
                  onChanged: (v) => setState(() => _showClose = v),
                ),
                _divider(),
                _switchTile(
                  label: 'Ngăn trùng lặp',
                  value: _preventDup,
                  onChanged: (v) => setState(() => _preventDup = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _applyGlobal();
                          Toastr.info('Đã áp dụng cấu hình global');
                        },
                        icon: const Icon(Icons.tune),
                        label: const Text('Áp dụng global'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Toastr.custom(
                            ToastrConfig(
                              type: ToastrType.success,
                              message: 'Preview với config hiện tại',
                              position: _position,
                              showMethod: _showMethod,
                              hideMethod: _hideMethod,
                              duration: _duration,
                              showProgressBar: _showProgress,
                              showCloseButton: _showClose,
                              preventDuplicates: _preventDup,
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Preview'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── SECTION 5: TOAST ACTION & CLEANUP (Collapsible) ───────────────
          _buildCollapsibleSection(
            title: 'TOASTR ACTIONS & CLEANUP',
            icon: Icons.cleaning_services_outlined,
            iconColor: Colors.teal,
            initiallyExpanded: false,
            child: Column(
              children: [
                _actionTile(
                  icon: Icons.clear,
                  label: 'Xóa toast cuối',
                  onTap: Toastr.clearLast,
                ),
                _divider(),
                _actionTile(
                  icon: Icons.clear_all,
                  label: 'Xóa tất cả toast',
                  onTap: Toastr.clearAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool initiallyExpanded,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: colorScheme.onSurface,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [child],
        ),
      ),
    );
  }

  Divider _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _toastTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }

  Widget _dropdownTile<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          DropdownButton<T>(
            value: value,
            isDense: true,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(10),
            items: items
                .map(
                  (e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      itemLabel(e),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AppSwitchTile(title: label, value: value, onChanged: onChanged);
  }
}
