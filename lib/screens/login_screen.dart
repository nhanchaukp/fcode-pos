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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              Color.lerp(colorScheme.primary, colorScheme.surface, 0.55)!,
              colorScheme.surface,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrandHeader(theme, colorScheme),
                    const SizedBox(height: 32),
                    _buildCard(theme, colorScheme, isLoading),
                    const SizedBox(height: 24),
                    Text(
                      '© FCODE Pos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          height: 104,
          width: 104,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.onPrimary.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
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
            color: colorScheme.onPrimary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.2),
        ),
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
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Đăng nhập để tiếp tục',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.85),
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
                    color: colorScheme.onPrimary.withValues(alpha: 0.7),
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
          ],
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
      fillColor: colorScheme.onPrimary.withValues(alpha: 0.12),
      prefixIcon: Icon(icon, color: colorScheme.onPrimary.withValues(alpha: 0.7)),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
        color: colorScheme.onPrimary.withValues(alpha: 0.9),
      ),
      hintStyle: TextStyle(
        color: colorScheme.onPrimary.withValues(alpha: 0.45),
      ),
      enabledBorder: border(
        colorScheme.onPrimary.withValues(alpha: 0.25),
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
