import 'package:fcode_pos/api/api_exception.dart';
import 'package:fcode_pos/data/models/status.dart';
import 'package:fcode_pos/ui/components/loading_icon.dart';
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
  final _emailController = TextEditingController(
    text: "nhanchauthai@gmail.com",
  );
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Status _status = Status.idle;
  Status _passkeyLoading = Status.idle;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _status = Status.idle;
    _passkeyLoading = Status.idle;
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      safeSetState(() => _status = Status.loading);
      final auth = ref.read(authProvider.notifier);

      try {
        final user = await auth.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null && mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      } on ApiException catch (e) {
        safeSetState(() => _status = Status.error);
        Toastr.error(e.message);
      } catch (e, stack) {
        debugPrintStack(stackTrace: stack);
        safeSetState(() => _status = Status.error);
        Toastr.error('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.');
      } finally {
        safeSetState(() => _status = Status.idle);
      }
    }
  }

  Future<void> _handlePasskeyLogin() async {
    if (!mounted) return;
    setState(() => _passkeyLoading = Status.loading);

    final auth = ref.read(authProvider.notifier);

    try {
      final user = await auth.loginWithPasskey();

      if (user != null && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      safeSetState(() => _passkeyLoading = Status.error);
      Toastr.error(e.message);
    } catch (e, stack) {
      debugPrintStack(
        stackTrace: stack,
        label: "Error during Passkey login: $e",
      );
      safeSetState(() => _passkeyLoading = Status.error);
      Toastr.error('Đăng nhập bằng Passkey thất bại. Vui lòng thử lại.');
    } finally {
      safeSetState(() => _passkeyLoading = Status.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  Image.asset(
                    'assets/splash-logo.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'FCODE Pos',
                    style: context.isExtraWideScreen
                        ? Theme.of(context).textTheme.displayLarge
                        : Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đăng nhập',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Tài khoản',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: _status != Status.loading,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Tài khoản là bắt buộc';
                      }
                      if (!value!.contains('@')) {
                        return 'Vui lòng nhập một tài khoản hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu của bạn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _status == Status.loading
                            ? null
                            : () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    enabled: _status != Status.loading,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Mật khẩu là bắt buộc';
                      }
                      if (value!.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Primary Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _status == Status.loading
                          ? null
                          : _handleLogin,
                      child: _status == Status.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng Nhập'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Secondary Passkey Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _passkeyLoading == Status.loading
                          ? null
                          : _handlePasskeyLogin,
                      icon: LoadingIcon(
                        icon: Icons.fingerprint,
                        loading: _passkeyLoading == Status.loading,
                      ),
                      label: const Text('Đăng nhập bằng Passkey'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
