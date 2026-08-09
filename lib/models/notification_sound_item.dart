/// Model đại diện cho một file nhạc chuông thông báo
class NotificationSoundItem {
  final String id;
  final String title;
  final String fileName; // VD: "anime_aah.m4a"
  final String assetPath; // VD: "assets/sounds/anime_aah.m4a"
  final String androidSoundName; // VD: "anime_aah" (không đuôi mở rộng)

  const NotificationSoundItem({
    required this.id,
    required this.title,
    required this.fileName,
    required this.assetPath,
    required this.androidSoundName,
  });

  /// Danh sách 9 file nhạc chuông có sẵn trong assets/sounds/ (Không dùng emoji)
  static const List<NotificationSoundItem> availableSounds = [
    NotificationSoundItem(
      id: 'default',
      title: 'Mặc định hệ thống',
      fileName: 'default',
      assetPath: '',
      androidSoundName: 'default',
    ),
    NotificationSoundItem(
      id: 'anime_aah',
      title: 'Anime Aah',
      fileName: 'anime_aah.m4a',
      assetPath: 'sounds/anime_aah.m4a',
      androidSoundName: 'anime_aah',
    ),
    NotificationSoundItem(
      id: 'car_lock',
      title: 'Khóa xe',
      fileName: 'car_lock.m4a',
      assetPath: 'sounds/car_lock.m4a',
      androidSoundName: 'car_lock',
    ),
    NotificationSoundItem(
      id: 'codonkia_voice',
      title: 'Có Đơn Kìa',
      fileName: 'codonkia_voice.m4a',
      assetPath: 'sounds/codonkia_voice.m4a',
      androidSoundName: 'codonkia_voice',
    ),
    NotificationSoundItem(
      id: 'iphone_15_new_sound',
      title: 'iPhone 15 Sound',
      fileName: 'iphone_15_new_sound.m4a',
      assetPath: 'sounds/iphone_15_new_sound.m4a',
      androidSoundName: 'iphone_15_new_sound',
    ),
    NotificationSoundItem(
      id: 'mario_bros',
      title: 'Super Mario Bros',
      fileName: 'mario_bros.m4a',
      assetPath: 'sounds/mario_bros.m4a',
      androidSoundName: 'mario_bros',
    ),
    NotificationSoundItem(
      id: 'mario_coin',
      title: 'Mario Coin',
      fileName: 'mario_coin.m4a',
      assetPath: 'sounds/mario_coin.m4a',
      androidSoundName: 'mario_coin',
    ),
    NotificationSoundItem(
      id: 'minion_laugh',
      title: 'Minion Laugh',
      fileName: 'minion_laugh.m4a',
      assetPath: 'sounds/minion_laugh.m4a',
      androidSoundName: 'minion_laugh',
    ),
    NotificationSoundItem(
      id: 'quack',
      title: 'Tiếng Vịt Quack',
      fileName: 'quack.m4a',
      assetPath: 'sounds/quack.m4a',
      androidSoundName: 'quack',
    ),
    NotificationSoundItem(
      id: 'snapchat_sound',
      title: 'Snapchat Sound',
      fileName: 'snapchat_sound.m4a',
      assetPath: 'sounds/snapchat_sound.m4a',
      androidSoundName: 'snapchat_sound',
    ),
  ];

  static NotificationSoundItem findById(String id) {
    return availableSounds.firstWhere(
      (sound) => sound.id == id,
      orElse: () => availableSounds.first,
    );
  }
}
