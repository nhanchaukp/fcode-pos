import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/data/models/status.dart';
import 'package:fcode_pos/providers/auth_provider.dart';
import 'package:fcode_pos/screens/tabs/main_shell.dart';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:fcode_pos/utils/safe_state.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  static const _overlapHeight = 32.0;
  static const _sheetTopRadius = 32.0;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _recoveryController = TextEditingController();
  final _pinFocusNode = FocusNode();
  Status _status = Status.idle;
  bool _useRecoveryCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    _recoveryController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _cancelAndPop() async {
    await ref.read(authProvider.notifier).cancelTwoFactorChallenge();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleVerify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    safeSetState(() => _status = Status.loading);

    try {
      final user = await ref.read(authProvider.notifier).verifyTwoFactor(
        code: _useRecoveryCode ? null : _codeController.text.trim(),
        recoveryCode: _useRecoveryCode
            ? _recoveryController.text.trim()
            : null,
      );

      if (user != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkService.processPendingNavigation();
        });
      }
    } on ApiException catch (e) {
      safeSetState(() => _status = Status.error);
      Toastr.error(
        e.fieldError(_useRecoveryCode ? 'recovery_code' : 'code') ??
            e.firstFieldError ??
            e.message,
      );
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      safeSetState(() => _status = Status.error);
      Toastr.error('Xác thực 2FA thất bại. Vui lòng thử lại.');
    } finally {
      safeSetState(() => _status = Status.idle);
    }
  }

  void _toggleRecoveryMode() {
    if (_status == Status.loading) return;
    setState(() {
      _useRecoveryCode = !_useRecoveryCode;
      _codeController.clear();
      _recoveryController.clear();
    });
    if (_useRecoveryCode) {
      _pinFocusNode.unfocus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pinFocusNode.requestFocus();
      });
    }
  }

  PinTheme _bottomCursorPinTheme({
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return PinTheme(
      width: 48,
      height: 56,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      decoration: const BoxDecoration(),
    );
  }

  Widget _bottomCursorLine(Color color, {double width = 48}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildPinInput({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isLoading,
  }) {
    final pinTheme = _bottomCursorPinTheme(
      colorScheme: colorScheme,
      theme: theme,
    );
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Pinput(
      length: 6,
      controller: _codeController,
      focusNode: _pinFocusNode,
      autofocus: true,
      enabled: !isLoading,
      pinAnimationType: PinAnimationType.slide,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofillHints: const [AutofillHints.oneTimeCode],
      defaultPinTheme: pinTheme,
      focusedPinTheme: pinTheme,
      submittedPinTheme: pinTheme,
      followingPinTheme: pinTheme,
      showCursor: true,
      cursor: _bottomCursorLine(activeColor),
      preFilledWidget: _bottomCursorLine(inactiveColor),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      validator: (value) {
        if (_useRecoveryCode) return null;
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập mã xác thực';
        }
        if (value.length != 6) return 'Mã phải có 6 chữ số';
        return null;
      },
      onCompleted: (_) => _handleVerify(),
    );
  }

  InputDecoration _recoveryInputDecoration(ColorScheme colorScheme) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      labelText: 'Recovery code',
      hintText: 'xxxx-xxxx-xxxx',
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      prefixIcon: Icon(Icons.key_outlined, color: colorScheme.onSurfaceVariant),
      enabledBorder: border(
        colorScheme.outlineVariant.withValues(alpha: 0.6),
        1,
      ),
      focusedBorder: border(colorScheme.primary, 1.8),
      errorBorder: border(colorScheme.error, 1),
      focusedErrorBorder: border(colorScheme.error, 1.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = _status == Status.loading;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSectionHeight = screenHeight * 0.38;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancelAndPop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topSectionHeight,
              child: ColoredBox(
                color: colorScheme.primary,
                child: SafeArea(
                  bottom: false,
                  child: _buildTopSection(theme, colorScheme, isLoading),
                ),
              ),
            ),
            Positioned(
              top: topSectionHeight - _overlapHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomSheet(theme, colorScheme, isLoading),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Image.asset(
                    'assets/splash-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Xác thực 2 bước',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bảo mật tài khoản của bạn',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: IconButton(
              onPressed: isLoading ? null : _cancelAndPop,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onPrimary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_sheetTopRadius),
          topRight: Radius.circular(_sheetTopRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          _sheetTopRadius + 8,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _useRecoveryCode ? 'Recovery code' : 'Mã xác thực',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _useRecoveryCode
                    ? 'Nhập recovery code khi mất thiết bị 2FA'
                    : 'Mở app Authenticator và nhập mã 6 số',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              if (_useRecoveryCode)
                TextFormField(
                  controller: _recoveryController,
                  decoration: _recoveryInputDecoration(colorScheme),
                  enabled: !isLoading,
                  validator: (value) {
                    if (!_useRecoveryCode) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập recovery code';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleVerify(),
                )
              else
                _buildPinInput(
                  theme: theme,
                  colorScheme: colorScheme,
                  isLoading: isLoading,
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: isLoading ? null : _toggleRecoveryMode,
                  child: Text(
                    _useRecoveryCode
                        ? 'Dùng mã từ Authenticator'
                        : 'Dùng recovery code',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _handleVerify,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Xác nhận'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
