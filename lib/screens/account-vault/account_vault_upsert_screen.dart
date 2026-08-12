import 'package:fcode_pos/api/api_response.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/services/account_vault_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/app_switch_tile.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Màn hình tạo mới hoặc cập nhật một Account Vault.
///
/// Truyền [vault] để chỉnh sửa, để `null` để tạo mới.
class AccountVaultUpsertScreen extends StatefulWidget {
  const AccountVaultUpsertScreen({super.key, this.vault, this.providers});

  final AccountVault? vault;

  /// Danh sách provider gợi ý từ API.
  final List<String>? providers;

  @override
  State<AccountVaultUpsertScreen> createState() =>
      _AccountVaultUpsertScreenState();
}

class _AccountVaultUpsertScreenState extends State<AccountVaultUpsertScreen> {
  final _service = AccountVaultService();
  final _formKey = GlobalKey<FormState>();
  final _dongvanfbController = TextEditingController();

  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _clientId;
  late final TextEditingController _provider;
  late final TextEditingController _refreshToken;
  late final TextEditingController _twoFactorSecret;
  late final TextEditingController _notes;
  late bool _isActive;

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  bool get _isEdit => widget.vault != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vault;
    _email = TextEditingController(text: v?.email ?? '');
    _password = TextEditingController(text: v?.password ?? '');
    _clientId = TextEditingController(text: v?.clientId ?? '');
    _provider = TextEditingController(text: v?.provider ?? '');
    _refreshToken = TextEditingController(text: v?.refreshToken ?? '');
    _twoFactorSecret = TextEditingController(text: v?.twoFactorSecret ?? '');
    _notes = TextEditingController(text: v?.notes ?? '');
    _isActive = v?.isActive ?? true;

    _dongvanfbController.addListener(_onDongvanfbChanged);
  }

  @override
  void dispose() {
    _dongvanfbController.removeListener(_onDongvanfbChanged);
    _dongvanfbController.dispose();
    _email.dispose();
    _password.dispose();
    _clientId.dispose();
    _provider.dispose();
    _refreshToken.dispose();
    _twoFactorSecret.dispose();
    _notes.dispose();
    super.dispose();
  }

  // ── Dongvanfb parser ──────────────────────────────────────────────────────

  /// Parse format: email|password|refresh_token|client_id
  void _onDongvanfbChanged() {
    final raw = _dongvanfbController.text;
    if (!raw.contains('|')) return;

    final parts = raw.split('|');
    if (parts.length < 2) return;

    setState(() {
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        _email.text = parts[0].trim();
      }
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        _password.text = parts[1].trim();
      }
      if (parts.length > 2 && parts[2].trim().isNotEmpty) {
        _refreshToken.text = parts[2].trim();
      }
      if (parts.length > 3 && parts[3].trim().isNotEmpty) {
        _clientId.text = parts[3].trim();
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final ApiResponse<AccountVault> response;
      if (_isEdit) {
        response = await _service.update(
          widget.vault!.id,
          email: _email.text.trim(),
          password:
              _password.text.trim().isEmpty ? null : _password.text.trim(),
          clientId:
              _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
          provider:
              _provider.text.trim().isEmpty ? null : _provider.text.trim(),
          refreshToken: _refreshToken.text.trim().isEmpty
              ? null
              : _refreshToken.text.trim(),
          twoFactorSecret: _twoFactorSecret.text.trim().isEmpty
              ? null
              : _twoFactorSecret.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          isActive: _isActive,
        );
      } else {
        response = await _service.create(
          email: _email.text.trim(),
          password:
              _password.text.trim().isEmpty ? null : _password.text.trim(),
          clientId:
              _clientId.text.trim().isEmpty ? null : _clientId.text.trim(),
          provider:
              _provider.text.trim().isEmpty ? null : _provider.text.trim(),
          refreshToken: _refreshToken.text.trim().isEmpty
              ? null
              : _refreshToken.text.trim(),
          twoFactorSecret: _twoFactorSecret.text.trim().isEmpty
              ? null
              : _twoFactorSecret.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          isActive: _isActive,
        );
      }

      if (!mounted) return;
      if (response.success && response.data != null) {
        Toastr.success(
          _isEdit ? 'Cập nhật thành công' : 'Tạo vault thành công',
          context: context,
        );
        Navigator.of(context).pop(true);
      } else {
        Toastr.error(
          response.message ??
              (_isEdit ? 'Cập nhật thất bại' : 'Tạo thất bại'),
          context: context,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Lỗi: $e', context: context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Chỉnh sửa vault' : 'Tạo vault mới',
      actions: [
        TextButton.icon(
          onPressed: _isSubmitting ? null : _handleSubmit,
          icon: LoadingIcon(
            icon: _isEdit ? Icons.check : Icons.add,
            loading: _isSubmitting,
          ),
          label: Text(_isEdit ? 'Lưu' : 'Tạo'),
        ),
      ],
      body: (context, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Dongvanfb quick-fill ──────────────────────────────────────
            _buildSectionLabel('Điền nhanh'),
            _buildField(
              controller: _dongvanfbController,
              label: 'Dongvanfb format',
              hint: 'email|password|refresh_token|client_id',
              icon: Icons.bolt_outlined,
              maxLines: 2,
              helperText: 'Dán vào để tự động điền các trường bên dưới',
            ),
            const SizedBox(height: 20),

            // ── Thông tin cơ bản ──────────────────────────────────────────
            _buildSectionLabel('Thông tin cơ bản'),
            _buildField(
              controller: _email,
              label: 'Email *',
              hint: 'ops@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập email'
                  : null,
            ),
            const SizedBox(height: 12),
            _ProviderField(
              controller: _provider,
              providers: widget.providers ?? [],
            ),
            const SizedBox(height: 12),
            AppSwitchTile(
              icon: _isActive
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
              title: 'Kích hoạt',
              subtitle: _isActive ? 'Vault đang hoạt động' : 'Vault tạm dừng',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 20),

            // ── Credentials ───────────────────────────────────────────────
            _buildSectionLabel('Credentials'),
            _buildField(
              controller: _password,
              label: 'Password',
              hint: 'Để trống nếu không đổi',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                tooltip: _obscurePassword ? 'Hiển thị mật khẩu' : 'Ẩn mật khẩu',
              ),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _clientId,
              label: 'Client ID',
              hint: 'xxx.apps.googleusercontent.com',
              icon: Icons.vpn_key_outlined,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _refreshToken,
              label: 'Refresh Token',
              hint: '1//0g...',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _twoFactorSecret,
              decoration: InputDecoration(
                labelText: 'Two-Factor Secret (BASE32)',
                hintText: 'JBSWY3DPEHPK3PXP',
                prefixIcon: const Icon(Icons.security),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
            ),
            const SizedBox(height: 20),

            // ── Ghi chú ───────────────────────────────────────────────────
            _buildSectionLabel('Ghi chú'),
            _buildField(
              controller: _notes,
              label: 'Ghi chú',
              hint: 'Mô tả ngắn về vault này',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: LoadingIcon(
                icon: _isEdit
                    ? Icons.save_outlined
                    : Icons.add_circle_outline,
                loading: _isSubmitting,
              ),
              label: Text(
                _isSubmitting
                    ? (_isEdit ? 'Đang lưu...' : 'Đang tạo...')
                    : (_isEdit ? 'Lưu thay đổi' : 'Tạo vault'),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool obscure = false,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }
}

// ── Provider Field với gợi ý ──────────────────────────────────────────────────

class _ProviderField extends StatelessWidget {
  const _ProviderField({
    required this.controller,
    required this.providers,
  });

  final TextEditingController controller;
  final List<String> providers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Provider',
            hintText: 'google, microsoft, apple...',
            prefixIcon: const Icon(Icons.cloud_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        if (providers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: providers.map((p) {
              return ActionChip(
                label: Text(p, style: const TextStyle(fontSize: 12)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => controller.text = p,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
