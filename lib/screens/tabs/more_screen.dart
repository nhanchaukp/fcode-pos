import 'package:fcode_pos/providers/auth_provider.dart';
import 'package:fcode_pos/providers/theme_provider.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hux/hux.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    final user = authState.asData?.value;
    final isLoading = authState.isLoading;
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.name ?? 'Tài khoản'),
            if (user?.email != null)
              Text(
                user!.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: isLoading
                ? null
                : () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                      Toastr.success('Đã đăng xuất');
                    }
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Card(
            elevation: 0,
            child: SwitchListTile(
              title: const Text('Chế độ tối'),
              subtitle: const Text('Bật chế độ giao diện tối'),
              value: isDarkMode,
              onChanged: (value) {
                themeNotifier.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.phone_android_outlined),
              title: const Text('Theo dõi thiết bị đăng nhập'),
              subtitle: const Text('Quản lý thiết bị được phép đăng nhập'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showPlaceholderDialog(
                  context,
                  title: 'Theo dõi thiết bị',
                  content:
                      'Tính năng đang được phát triển. Vui lòng quay lại sau.',
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Điều khoản & Điều kiện'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showPlaceholderDialog(
                  context,
                  title: 'Điều khoản sử dụng',
                  content:
                      'Nội dung điều khoản sẽ được cập nhật trong phiên bản sắp tới.',
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Chính sách bảo mật'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showPlaceholderDialog(
                  context,
                  title: 'Chính sách bảo mật',
                  content:
                      'Chúng tôi sẽ cập nhật chính sách chi tiết ở bản phát hành tiếp theo.',
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info != null
                  ? '${info.version} (${info.buildNumber})'
                  : 'Đang tải...';
              return Center(
                child: Text(
                  'Phiên bản ứng dụng: $version',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPlaceholderDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
