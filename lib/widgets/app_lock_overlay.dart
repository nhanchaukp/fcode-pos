import 'dart:io';
import 'package:fcode_pos/config/environment.dart';
import 'package:fcode_pos/providers/auth_provider.dart';
import 'package:fcode_pos/providers/biometric_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLockOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockOverlay({required this.child, super.key});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay>
    with WidgetsBindingObserver {
  DateTime? _pausedTime;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Tự động yêu cầu mở khóa khi mở app lần đầu nếu app đang ở trạng thái khóa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptUnlock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final isEnabled = ref.read(appLockEnabledProvider);
      if (isEnabled && _pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        // Khóa app nếu ra ngoài nền từ 5 giây trở lên
        if (elapsed.inSeconds >= 5) {
          ref.read(isAppLockedProvider.notifier).lock();
          _checkAndPromptUnlock();
        }
      }
      _pausedTime = null;
    }
  }

  Future<void> _checkAndPromptUnlock() async {
    final isLocked = ref.read(isAppLockedProvider);
    if (isLocked && !_isAuthenticating && mounted) {
      _isAuthenticating = true;
      try {
        await ref.read(isAppLockedProvider.notifier).requestUnlock();
      } finally {
        if (mounted) {
          setState(() {
            _isAuthenticating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(isAppLockedProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final biometricInfo = ref.watch(biometricInfoProvider).asData?.value;
    final buttonLabel = biometricInfo?.buttonLabel ??
        (Platform.isIOS ? 'Mở khóa bằng Face ID' : 'Mở khóa bằng vân tay');
    final biometricIcon = biometricInfo?.icon ??
        (Platform.isIOS ? Icons.face_rounded : Icons.fingerprint_rounded);
    final user = ref.watch(authProvider).asData?.value;

    return Stack(
      children: [
        widget.child,
        if (isLocked)
          Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Logo hoặc Avatar
                      if (user?.avatar != null && user!.avatar!.isNotEmpty)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(user.avatar!),
                        )
                      else
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_rounded,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        user != null ? 'Chào ${user.name}' : Environment.appName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ứng dụng đang được bảo vệ. Vui lòng xác thực để tiếp tục.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      // Nút kích hoạt mở khóa
                      FilledButton.icon(
                        onPressed: _isAuthenticating
                            ? null
                            : () => _checkAndPromptUnlock(),
                        icon: Icon(biometricIcon, size: 22),
                        label: Text(buttonLabel),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
