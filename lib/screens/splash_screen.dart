import 'package:fcode_pos/providers/auth_provider.dart';
import 'package:fcode_pos/screens/main_shell.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasShownError = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return auth.when(
      data: (user) {
        // Reset error flag khi load thành công
        _hasShownError = false;
        return user != null ? const MainShell() : const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) {
        // Chỉ show error một lần để tránh spam
        if (!_hasShownError) {
          _hasShownError = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Toastr.error(
                'Lỗi xác thực: ${error.toString()}',
                duration: const Duration(seconds: 4),
              );
            }
          });
        }
        return const LoginScreen();
      },
    );
  }
}
