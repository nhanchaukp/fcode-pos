import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/data/models/status.dart';
import 'package:fcode_pos/screens/tabs/main_shell.dart';
import 'package:fcode_pos/screens/two_factor_screen.dart';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:fcode_pos/utils/safe_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fcode_pos/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:fcode_pos/utils/extensions/build_context.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _overlapHeight = 32.0;
  static const _sheetTopRadius = 32.0;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Status _status = Status.idle;
  bool _obscurePassword = true;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _status = Status.idle;
    super.dispose();
  }

  Future<void> _handleLogin() async {
    safeSetState(() => _emailError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    safeSetState(() => _status = Status.loading);
    final auth = ref.read(authProvider.notifier);

    try {
      final result = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result.requiresTwoFactor) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TwoFactorScreen()),
        );
        return;
      }

      if (result.user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        ).then((_) => DeepLinkService.processPendingNavigation());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkService.processPendingNavigation();
        });
      }
    } on ApiException catch (e) {
      safeSetState(() => _status = Status.error);
      final emailError = e.fieldError('email');
      if (emailError != null) {
        safeSetState(() => _emailError = emailError);
        _formKey.currentState?.validate();
      }
      Toastr.error(emailError ?? e.firstFieldError ?? e.message);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      safeSetState(() => _status = Status.error);
      Toastr.error('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.');
    } finally {
      safeSetState(() => _status = Status.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = _status == Status.loading;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSectionHeight = screenHeight * 0.38;

    return Scaffold(
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
                child: _buildTopSection(theme, colorScheme),
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
    );
  }

  Widget _buildTopSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            child: Image.asset('assets/splash-logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          Text(
            'FCODE Pos',
            textAlign: TextAlign.center,
            style:
                (context.isExtraWideScreen
                        ? theme.textTheme.displaySmall
                        : theme.textTheme.headlineMedium)
                    ?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
          ),
          const SizedBox(height: 6),
          Text(
            'Giải pháp bán hàng thông minh',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
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
                'Chào mừng trở lại',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Đăng nhập để tiếp tục',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration(
                  colorScheme: colorScheme,
                  label: 'Email',
                  hint: 'admin@example.com',
                  icon: Icons.alternate_email_rounded,
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                enabled: !isLoading,
                onChanged: (_) {
                  if (_emailError != null) {
                    safeSetState(() => _emailError = null);
                  }
                },
                validator: (value) {
                  if (_emailError != null) return _emailError;
                  if (value?.isEmpty ?? true) {
                    return 'Email là bắt buộc';
                  }
                  if (!value!.contains('@')) {
                    return 'Vui lòng nhập email hợp lệ';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration(
                  colorScheme: colorScheme,
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu của bạn',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                  ),
                ),
                obscureText: _obscurePassword,
                enabled: !isLoading,
                onChanged: (_) {
                  if (_emailError != null) {
                    safeSetState(() => _emailError = null);
                  }
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Mật khẩu là bắt buộc';
                  }
                  if (value!.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleLogin(),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _handleLogin,
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
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Đăng Nhập'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '© FCODE Pos',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ColorScheme colorScheme,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      suffixIcon: suffixIcon,
      enabledBorder: border(
        colorScheme.outlineVariant.withValues(alpha: 0.6),
        1,
      ),
      focusedBorder: border(colorScheme.primary, 1.8),
      errorBorder: border(colorScheme.error, 1),
      focusedErrorBorder: border(colorScheme.error, 1.8),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}
