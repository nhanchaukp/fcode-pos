import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Danh sách màu seed dùng cho Material 3 ColorScheme.
/// Có thể mở rộng thêm nếu cần.
const List<Color> material3SeedColors = <Color>[
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.deepPurple,
  Colors.purple,
  Colors.pink,
  Colors.red,
  Colors.orange,
  Colors.deepOrange,
  Colors.amber,
  Colors.green,
  Colors.lightGreen,
  Colors.cyan,
  Colors.blueGrey,
];

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Provider quản lý chỉ số màu seed hiện tại trong [material3SeedColors].
final themeSeedColorIndexProvider =
    StateNotifierProvider<ThemeSeedColorNotifier, int>(
  (ref) => ThemeSeedColorNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const _themeKey = 'theme_mode';

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    if (stored == null) return;

    final mode = ThemeMode.values.firstWhere(
      (element) => element.name == stored,
      orElse: () => ThemeMode.system,
    );

    if (mode != state) {
      state = mode;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> toggleTheme() {
    final nextMode =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    return setThemeMode(nextMode);
  }
}

class ThemeSeedColorNotifier extends StateNotifier<int> {
  ThemeSeedColorNotifier() : super(0) {
    _loadSeedColor();
  }

  static const _seedKey = 'theme_seed_color_index';

  Future<void> _loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIndex = prefs.getInt(_seedKey);
    if (storedIndex == null) return;

    if (storedIndex >= 0 && storedIndex < material3SeedColors.length) {
      state = storedIndex;
    }
  }

  Future<void> setSeedColorIndex(int index) async {
    if (index == state) return;
    if (index < 0 || index >= material3SeedColors.length) return;

    state = index;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedKey, index);
  }
}
