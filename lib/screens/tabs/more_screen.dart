import 'dart:io';
import 'package:fcode_pos/config/theme_colors.dart';
import 'package:fcode_pos/models.dart';
import 'package:fcode_pos/providers/auth_provider.dart';
import 'package:fcode_pos/providers/biometric_provider.dart';
import 'package:fcode_pos/providers/notification_provider.dart';
import 'package:fcode_pos/providers/theme_provider.dart';
import 'package:fcode_pos/screens/developer/developer_screen.dart';
import 'package:fcode_pos/screens/login_screen.dart';
import 'package:fcode_pos/screens/settings/notification_sound_screen.dart';
import 'package:fcode_pos/services/notification_sound_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/ui/components/app_switch_tile.dart';
import 'package:fcode_pos/ui/components/badge/status_badges.dart';
import 'package:fcode_pos/ui/components/in_app_browser.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final paletteIndex = ref.watch(themePaletteIndexProvider);
    final paletteNotifier = ref.read(themePaletteIndexProvider.notifier);
    final notificationEnabled = ref.watch(notificationEnabledProvider);
    final notificationNotifier = ref.read(notificationEnabledProvider.notifier);
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final biometricInfo = ref.watch(biometricInfoProvider).asData?.value;
    final canUseBiometrics =
        ref.watch(canUseBiometricsProvider).asData?.value ?? true;

    final biometricTitle = biometricInfo?.title ??
        (Platform.isIOS ? 'Mở khóa bằng Face ID' : 'Mở khóa bằng vân tay');
    final biometricSubtitle = biometricInfo?.subtitle ??
        (Platform.isIOS
            ? 'Yêu cầu Face ID hoặc mật mã thiết bị khi mở ứng dụng'
            : 'Yêu cầu vân tay hoặc mã PIN / hình mở khóa khi mở ứng dụng');
    final biometricIcon = biometricInfo?.icon ??
        (Platform.isIOS ? Icons.face_rounded : Icons.fingerprint_rounded);

    final user = authState.asData?.value;
    final isLoading = authState.isLoading;
    final isDarkMode =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Cài đặt',
      showBack: false,
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          visualDensity: VisualDensity.compact,
          onPressed: isLoading
              ? null
              : () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                    Toastr.success('Đã đăng xuất');
                  }
                },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _UserProfileCard(
            user: user,
            isLoading: isLoading,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Thông báo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppSwitchTile(
            icon: notificationEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            title: 'Thông báo đẩy',
            subtitle: 'Nhận thông báo đơn hàng mới và cập nhật trạng thái',
            value: notificationEnabled,
            onChanged: (value) {
              notificationNotifier.setNotificationEnabled(value);
            },
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: Icon(
                Icons.music_note_outlined,
                color: colorScheme.primary,
              ),
              title: const Text('Nhạc chuông thông báo'),
              subtitle: Text(
                NotificationSoundService.instance.currentSound.title,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSoundScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Giao diện',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppSwitchTile(
            icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: 'Chế độ tối',
            subtitle: 'Bật chế độ giao diện tối',
            value: isDarkMode,
            onChanged: (value) {
              themeNotifier.setThemeMode(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.color_lens_outlined,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Giao diện',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn bộ màu cho ứng dụng',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Theme options được generate động từ themePalettes trong theme_colors.dart.
                  // Thêm ThemePalette mới ở đó sẽ tự động xuất hiện ở đây (ví dụ: Halloween, 90s).
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(themePalettes.length, (index) {
                      final palette = themePalettes[index];
                      final isSelected = index == paletteIndex;
                      final dot = palette.previewColor;
                      return InkWell(
                        onTap: () => paletteNotifier.setPaletteIndex(index),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: dot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                palette.name,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Bảo mật & Quyền riêng tư',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canUseBiometrics) ...[
            AppSwitchTile(
              icon: biometricIcon,
              title: biometricTitle,
              subtitle: biometricSubtitle,
              value: appLockEnabled,
              onChanged: (value) async {
                final success = await ref
                    .read(appLockEnabledProvider.notifier)
                    .toggle(value);
                if (!success && value) {
                  Toastr.error(
                    'Xác thực không thành công. Không thể bật khóa ứng dụng.',
                  );
                } else if (value) {
                  Toastr.success('Đã kích hoạt $biometricTitle');
                } else {
                  Toastr.info('Đã tắt $biometricTitle');
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_android_outlined,
                  color: Colors.blue,
                ),
              ),
              title: const Text('Theo dõi thiết bị đăng nhập'),
              subtitle: const Text('Quản lý thiết bị được phép đăng nhập'),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
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
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.orange,
                ),
              ),
              title: const Text('Điều khoản & Điều kiện'),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () {
                InAppBrowser.open(
                  context,
                  url: 'https://fcode.vn/page/dieu-khoan-su-dung',
                  title: 'Điều khoản sử dụng',
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.green),
              ),
              title: const Text('Chính sách bảo mật'),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Developer',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.developer_mode_outlined,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              title: const Text('Developer'),
              subtitle: const Text('Test UI components & utilities'),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeveloperScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info != null
                  ? '${info.version}+${info.buildNumber}'
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

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({
    required this.user,
    required this.isLoading,
    required this.colorScheme,
  });

  final User? user;
  final bool isLoading;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFooter = _hasTwoFactor || _roleNames.isNotEmpty;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading && user == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_hasUsername) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${user!.username}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (user?.email != null && user!.email.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.alternate_email_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  user!.email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            if (!isLoading && user != null && hasFooter) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (_hasTwoFactor) const TwoFactorBadge(),
                    ..._roleNames.map((name) => RoleBadge(name: name)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasTwoFactor => user?.twoFactorConfirmedAt != null;

  String get _displayName {
    if (user == null) return 'Người dùng';
    if (user!.name.isNotEmpty) return user!.name;
    if (user!.username.isNotEmpty) return user!.username;
    return 'Người dùng';
  }

  bool get _hasUsername =>
      user != null && user!.username.isNotEmpty && user!.username != user!.name;

  List<String> get _roleNames {
    final roles = user?.roles;
    if (roles == null) return const [];
    return roles
        .map((role) => role.name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Widget _buildAvatar() {
    final photoUrl = _resolvePhotoUrl();
    final initial = _displayName.isNotEmpty
        ? _displayName[0].toUpperCase()
        : 'U';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null
            ? Text(
                initial,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
    );
  }

  String? _resolvePhotoUrl() {
    final profilePhoto = user?.profilePhotoUrl?.trim();
    if (profilePhoto != null && profilePhoto.isNotEmpty) return profilePhoto;

    final avatar = user?.avatar?.trim();
    if (avatar != null && avatar.isNotEmpty) return avatar;

    return null;
  }
}
