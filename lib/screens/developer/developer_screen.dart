import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:toastr_flutter/toastr.dart'
    show
        ToastrHelper,
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

  void _applyGlobal() {
    ToastrHelper.configure(
      position: _position,
      showMethod: _showMethod,
      hideMethod: _hideMethod,
      duration: _duration,
      showProgressBar: _showProgress,
      showCloseButton: _showClose,
      preventDuplicates: _preventDup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Developer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _sectionLabel('Toast — Loại thông báo', colorScheme),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                  onTap: () =>
                      ToastrHelper.blank('Đây là toast không có icon.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Toast — Cấu hình', colorScheme),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              ],
            ),
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
                    ToastrHelper.custom(
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
          const SizedBox(height: 20),
          _sectionLabel('Toast — Xóa', colorScheme),
          const SizedBox(height: 6),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _actionTile(
                  icon: Icons.clear,
                  label: 'Xóa toast cuối',
                  onTap: ToastrHelper.clearLast,
                ),
                _divider(),
                _actionTile(
                  icon: Icons.clear_all,
                  label: 'Xóa tất cả toast',
                  onTap: ToastrHelper.clearAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label),
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
      leading: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
      title: Text(label),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
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
                      style: const TextStyle(fontSize: 13),
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
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
