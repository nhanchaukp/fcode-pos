import 'package:fcode_pos/models/notification_sound_item.dart';
import 'package:fcode_pos/services/notification_service.dart';
import 'package:fcode_pos/services/notification_sound_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
import 'package:fcode_pos/utils/extensions/colors.dart';
import 'package:fcode_pos/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';

class NotificationSoundScreen extends StatefulWidget {
  const NotificationSoundScreen({super.key});

  @override
  State<NotificationSoundScreen> createState() =>
      _NotificationSoundScreenState();
}

class _NotificationSoundScreenState extends State<NotificationSoundScreen> {
  late NotificationSoundItem _selectedSound;

  @override
  void initState() {
    super.initState();
    _selectedSound = NotificationSoundService.instance.currentSound;
  }

  @override
  void dispose() {
    NotificationSoundService.instance.stopPreview();
    super.dispose();
  }

  Future<void> _selectAndPlaySound(NotificationSoundItem item) async {
    setState(() {
      _selectedSound = item;
    });
    await NotificationSoundService.instance.setSelectedSound(item);
    await NotificationSoundService.instance.previewSound(item);
  }

  Future<void> _testNotification() async {
    Toastr.info('Đang gửi thông báo thử...', context: context);
    await NotificationService.instance.showLocalNotification(
      title: 'Thông báo thử nghiệm',
      body: 'Âm thanh: ${_selectedSound.title}',
      delay: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBorderColor = colorScheme.outlineVariant.a == 0
        ? Colors.transparent
        : colorScheme.outlineVariant.applyOpacity(0.4);

    final sounds = NotificationSoundItem.availableSounds;
    const cardBorderRadius = BorderRadius.all(Radius.circular(12));

    return AppScaffold(
      title: 'Nhạc chuông thông báo',
      actions: [
        IconButton(
          tooltip: 'Bắn thử thông báo',
          onPressed: _testNotification,
          icon: const Icon(Icons.notifications_active_outlined),
        ),
      ],
      body: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'ÂM THANH CÓ SẴN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant.applyOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Material(
            color: isDark
                ? colorScheme.surfaceContainer
                : colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: cardBorderRadius,
              side: BorderSide(color: cardBorderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < sounds.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 0.3,
                      indent: 48,
                      endIndent: 0,
                      color: cardBorderColor,
                    ),
                  _buildSoundTile(
                    sound: sounds[i],
                    isSelected: sounds[i].id == _selectedSound.id,
                    isFirst: i == 0,
                    isLast: i == sounds.length - 1,
                    colorScheme: colorScheme,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Âm thanh được chọn sẽ phát khi có đơn hàng mới hoặc thông báo cập nhật trạng thái.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.applyOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTile({
    required NotificationSoundItem sound,
    required bool isSelected,
    required bool isFirst,
    required bool isLast,
    required ColorScheme colorScheme,
  }) {
    final itemBorderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(12) : Radius.zero,
      bottom: isLast ? const Radius.circular(12) : Radius.zero,
    );

    return InkWell(
      borderRadius: itemBorderRadius,
      onTap: () => _selectAndPlaySound(sound),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sound.title,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
