import 'package:fcode_pos/models/notification_sound_item.dart';
import 'package:fcode_pos/services/notification_service.dart';
import 'package:fcode_pos/services/notification_sound_service.dart';
import 'package:fcode_pos/ui/components/app_scaffold.dart';
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
  String? _playingSoundId;

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

  Future<void> _selectSound(NotificationSoundItem item) async {
    setState(() {
      _selectedSound = item;
    });
    await NotificationSoundService.instance.setSelectedSound(item);
    await _previewSound(item);
  }

  Future<void> _previewSound(NotificationSoundItem item) async {
    if (_playingSoundId == item.id) {
      await NotificationSoundService.instance.stopPreview();
      setState(() {
        _playingSoundId = null;
      });
    } else {
      setState(() {
        _playingSoundId = item.id;
      });
      await NotificationSoundService.instance.previewSound(item);
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Nhạc chuông thông báo',
      actions: [
        IconButton(
          tooltip: 'Bắn thử thông báo',
          onPressed: _testNotification,
          icon: const Icon(Icons.notifications_active_outlined),
        ),
      ],
      body: (context, scrollController) => ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: NotificationSoundItem.availableSounds.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 56, endIndent: 16),
        itemBuilder: (context, index) {
          final sound = NotificationSoundItem.availableSounds[index];
          final isSelected = sound.id == _selectedSound.id;
          final isPlaying = sound.id == _playingSoundId;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            // ignore: deprecated_member_use
            leading: Radio<String>(
              value: sound.id,
              // ignore: deprecated_member_use
              groupValue: _selectedSound.id,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) _selectSound(sound);
              },
            ),
            title: Text(
              sound.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
            trailing: sound.id == 'default'
                ? null
                : IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      color: isPlaying
                          ? colorScheme.error
                          : colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: isPlaying ? 'Dừng phát' : 'Nghe thử',
                    onPressed: () => _previewSound(sound),
                  ),
            onTap: () => _selectSound(sound),
          );
        },
      ),
    );
  }
}
