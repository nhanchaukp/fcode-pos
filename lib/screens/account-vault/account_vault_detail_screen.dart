import 'dart:async';

import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/screens/account-vault/account_vault_upsert_screen.dart';
import 'package:fcode_pos/services/account_vault_service.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:otp/otp.dart';

class AccountVaultDetailScreen extends StatefulWidget {
  const AccountVaultDetailScreen({super.key, required this.item});

  final AccountVaultItem item;

  @override
  State<AccountVaultDetailScreen> createState() =>
      _AccountVaultDetailScreenState();
}

class _AccountVaultDetailScreenState extends State<AccountVaultDetailScreen> {
  final _service = AccountVaultService();

  AccountVault? _detail;
  bool _loading = true;
  String? _error;

  /// Đánh dấu có thay đổi (sửa/xóa) để list biết mà reload khi quay lại.
  bool _changed = false;

  // OTP state
  String _otpCode = '';
  int _otpRemaining = 30;
  Timer? _otpTimer;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.detail(widget.item.id);
      if (!mounted) return;
      setState(() => _detail = res.data);
      if (_detail?.twoFactorSecret != null) _startOtpTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── OTP ───────────────────────────────────────────────────────────────────

  void _startOtpTimer() {
    _refreshOtp();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = 30 - (DateTime.now().second % 30);
      setState(() => _otpRemaining = remaining);
      if (remaining == 30) _refreshOtp();
    });
  }

  void _refreshOtp() {
    final secret = _detail?.twoFactorSecret;
    if (secret == null || secret.isEmpty) return;
    try {
      final code = OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (mounted) setState(() => _otpCode = code);
    } catch (_) {
      if (mounted) setState(() => _otpCode = '------');
    }
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  Future<void> _navigateToEdit() async {
    if (_detail == null) return;
    List<String> providers = [];
    try {
      final res = await _service.providers();
      providers = res.data ?? [];
    } catch (_) {}

    if (!mounted) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountVaultUpsertScreen(
          vault: _detail,
          providers: providers,
        ),
      ),
    );
    if (result == true && mounted) {
      _changed = true;
      _fetchDetail();
    }
  }

  Future<void> _delete() async {
    final vault = _detail;
    if (vault == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa vault "${vault.email}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.delete(vault.id);
      if (!mounted) return;
      Toastr.success('Đã xóa vault', context: context);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Toastr.error('Xóa thất bại', context: context);
    }
  }

  // ── Copy ──────────────────────────────────────────────────────────────────

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    Toastr.success('Đã sao chép $label', context: context);
  }

  void _copyAccountInfo() {
    final vault = _detail;
    if (vault == null) return;
    final text =
        'Tài khoản: ${vault.email}\nMật khẩu: ${vault.password ?? ''}';
    Clipboard.setData(ClipboardData(text: text));
    Toastr.success('Đã sao chép thông tin tài khoản', context: context);
  }

  // ── Mail reading ──────────────────────────────────────────────────────────

  Future<void> _readMail({required bool useGraphApi}) async {
    final vault = _detail;
    if (vault == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MailSheet(
        vault: vault,
        useGraphApi: useGraphApi,
        service: _service,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.provider != null)
                Text(
                  widget.item.provider!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              Text(
                widget.item.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_detail != null)
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Sao chép tài khoản',
                onPressed: _copyAccountInfo,
              ),
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn',
              onSelected: (v) {
                switch (v) {
                  case 'reload':
                    _fetchDetail();
                  case 'edit':
                    _navigateToEdit();
                  case 'delete':
                    _delete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'reload',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 12),
                      Text('Tải lại'),
                    ],
                  ),
                ),
                if (_detail != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                if (_detail != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _fetchDetail, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final vault = _detail!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Credentials (kèm tên tài khoản)
        _buildCredentialsSection(vault),

        // OTP
        if (vault.twoFactorSecret != null) ...[
          const SizedBox(height: 16),
          _buildOtpSection(),
        ],

        // Mail reading
        if (vault.canReadMail) ...[
          const SizedBox(height: 16),
          _buildMailSection(vault),
        ],

        // Notes
        if (vault.notes != null && vault.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildNotesSection(vault.notes!),
        ],
      ],
    );
  }

  Widget _buildCredentialsSection(AccountVault vault) {
    final cs = Theme.of(context).colorScheme;
    final children = <Widget>[
      ListTile(
        dense: true,
        leading: Icon(Icons.person_outline, size: 20, color: cs.primary),
        title: const Text(
          'Tài khoản',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          vault.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: cs.onSurface),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () => _copy(vault.email, 'Tài khoản'),
          tooltip: 'Sao chép',
        ),
      ),
      ListTile(
        dense: true,
        leading: Icon(Icons.toggle_on_outlined, size: 20, color: cs.primary),
        title: const Text(
          'Trạng thái',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        trailing: _StatusChip(isActive: vault.isActive),
      ),
      ListTile(
        dense: true,
        leading: Icon(Icons.storefront_outlined, size: 20, color: cs.primary),
        title: const Text(
          'Provider',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          (vault.provider == null || vault.provider!.isEmpty)
              ? '-'
              : vault.provider!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: cs.onSurface),
        ),
      ),
    ];

    if (vault.password != null) {
      children.add(_buildCredTile(_CredRow(
        icon: Icons.lock_outline,
        label: 'Password',
        value: vault.password!,
        obscure: true,
      )));
    }
    if (vault.clientId != null) {
      children.add(_buildCredTile(_CredRow(
        icon: Icons.vpn_key_outlined,
        label: 'Client ID',
        value: vault.clientId!,
      )));
    }
    if (vault.refreshToken != null) {
      children.add(_buildCredTile(_CredRow(
        icon: Icons.refresh,
        label: 'Refresh Token',
        value: vault.refreshToken!,
        monospace: true,
      )));
    }

    return _SectionCard(
      title: 'Thông tin đăng nhập',
      children: children,
    );
  }

  Widget _buildCredTile(_CredRow row) {
    return _CredentialTile(
      icon: row.icon,
      label: row.label,
      value: row.value,
      obscure: row.obscure,
      monospace: row.monospace,
      onCopy: () => _copy(row.value, row.label),
    );
  }

  Widget _buildOtpSection() {
    return _SectionCard(
      title: 'OTP (TOTP 2FA)',
      children: [
        _OtpTile(
          code: _otpCode,
          remaining: _otpRemaining,
          onCopy: () => _copy(_otpCode, 'OTP'),
        ),
      ],
    );
  }

  Widget _buildMailSection(AccountVault vault) {
    return _SectionCard(
      title: 'Đọc hộp thư',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text('Graph API'),
                  onPressed: () => _readMail(useGraphApi: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.mail_outlined, size: 18),
                  label: const Text('OAuth2'),
                  onPressed: () => _readMail(useGraphApi: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(String notes) {
    final cs = Theme.of(context).colorScheme;
    return _SectionCard(
      title: 'Ghi chú',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Text(
            notes,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: cs.surfaceContainerLowest,
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Credential Tile ───────────────────────────────────────────────────────────

class _CredRow {
  const _CredRow({
    required this.icon,
    required this.label,
    required this.value,
    this.obscure = false,
    this.monospace = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool obscure;
  final bool monospace;
}

class _CredentialTile extends StatefulWidget {
  const _CredentialTile({
    required this.icon,
    required this.label,
    required this.value,
    this.obscure = false,
    this.monospace = false,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool obscure;
  final bool monospace;
  final VoidCallback onCopy;

  @override
  State<_CredentialTile> createState() => _CredentialTileState();
}

class _CredentialTileState extends State<_CredentialTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showValue = !widget.obscure || _revealed;
    final displayText = showValue
        ? widget.value
        : '•' * widget.value.length.clamp(8, 20);

    return ListTile(
      dense: true,
      leading: Icon(widget.icon, size: 20, color: cs.primary),
      title: Text(
        widget.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        displayText,
        maxLines: showValue ? 3 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontFamily: widget.monospace ? 'monospace' : null,
          color: cs.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.obscure)
            IconButton(
              icon: Icon(
                _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: () => setState(() => _revealed = !_revealed),
            ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: widget.onCopy,
            tooltip: 'Sao chép',
          ),
        ],
      ),
    );
  }
}

// ── OTP Tile ──────────────────────────────────────────────────────────────────

class _OtpTile extends StatelessWidget {
  const _OtpTile({
    required this.code,
    required this.remaining,
    required this.onCopy,
  });

  final String code;
  final int remaining;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUrgent = remaining <= 5;
    final color = isUrgent ? cs.error : cs.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Code — tap để copy
          Expanded(
            child: GestureDetector(
              onTap: onCopy,
              child: Text(
                code.isEmpty ? '------' : code,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 8,
                  color: color,
                ),
              ),
            ),
          ),
          // Countdown circle
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: remaining / 30,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
                Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Đang dùng' : 'Vô hiệu',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Mail Sheet ────────────────────────────────────────────────────────────────

class _MailSheet extends StatefulWidget {
  const _MailSheet({
    required this.vault,
    required this.useGraphApi,
    required this.service,
  });

  final AccountVault vault;
  final bool useGraphApi;
  final AccountVaultService service;

  @override
  State<_MailSheet> createState() => _MailSheetState();
}

class _MailSheetState extends State<_MailSheet> {
  List<VaultMailMessage>? _messages;
  bool _loading = true;
  String? _error;
  bool _listAll = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vault = widget.vault;
      final msgs = widget.useGraphApi
          ? await widget.service.readMailGraphApi(
              email: vault.email,
              refreshToken: vault.refreshToken!,
              clientId: vault.clientId!,
              listAll: _listAll,
            )
          : await widget.service.readMailOAuth2(
              email: vault.email,
              refreshToken: vault.refreshToken!,
              clientId: vault.clientId!,
              listAll: _listAll,
            );
      if (!mounted) return;
      setState(() => _messages = msgs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = widget.useGraphApi ? 'Graph API Mail' : 'OAuth2 Mail';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.mail_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.vault.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List all toggle
                  FilterChip(
                    label: const Text('Tất cả', style: TextStyle(fontSize: 12)),
                    selected: _listAll,
                    onSelected: (v) {
                      setState(() => _listAll = v);
                      _fetch();
                    },
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetch,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(child: _buildBody(scrollController)),
          ],
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _fetch, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final msgs = _messages ?? [];

    if (msgs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không có email nào'),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: msgs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _MailCard(message: msgs[i]),
    );
  }
}

// ── Mail Card ─────────────────────────────────────────────────────────────────

class _MailCard extends StatelessWidget {
  const _MailCard({required this.message});
  final VaultMailMessage message;

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr)?.toLocal();
    if (dt == null) return dateStr;
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final msg = message;
    final hasCode = msg.code.isNotEmpty;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender + date
            Row(
              children: [
                Expanded(
                  child: Text(
                    msg.senderName.isNotEmpty
                        ? msg.senderName
                        : msg.senderAddress,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(msg.date),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Subject
            Text(
              msg.subject,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),

            // Code badge — tap to copy
            if (hasCode) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.code));
                  Toastr.success(
                    'Đã sao chép mã ${msg.code}',
                    context: context,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.code,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5,
                          fontFamily: 'monospace',
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.copy, size: 16, color: cs.onPrimaryContainer),
                    ],
                  ),
                ),
              ),
            ],

            // Footer actions
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (msg.hasContent)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Xem nội dung', style: TextStyle(fontSize: 12)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _MailContentScreen(message: msg),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mail Content Screen ───────────────────────────────────────────────────────

class _MailContentScreen extends StatefulWidget {
  const _MailContentScreen({required this.message});
  final VaultMailMessage message;

  @override
  State<_MailContentScreen> createState() => _MailContentScreenState();
}

class _MailContentScreenState extends State<_MailContentScreen> {
  bool _loading = true;

  String get _wrappedHtml {
    final html = widget.message.htmlContent;
    // Wrap bare HTML bodies with a responsive meta tag and base font
    if (html.toLowerCase().contains('<html')) return html;
    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, sans-serif; font-size: 14px;
           margin: 12px; color: #222; word-break: break-word; }
    img  { max-width: 100%; height: auto; }
    a    { color: #1a73e8; }
  </style>
</head>
<body>$html</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.senderName.isNotEmpty ? msg.senderName : msg.senderAddress,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              msg.subject,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (msg.code.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.code));
                  Toastr.success(
                    'Đã sao chép mã ${msg.code}',
                    context: context,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg.code,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialData: InAppWebViewInitialData(data: _wrappedHtml),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: false,
              disableContextMenu: true,
              supportZoom: true,
              useWideViewPort: true,
              loadWithOverviewMode: true,
            ),
            onLoadStop: (_, __) {
              if (mounted) setState(() => _loading = false);
            },
          ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
