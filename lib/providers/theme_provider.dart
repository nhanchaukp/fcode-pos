import 'package:fcode_pos/config/theme_colors.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

/// Provider quản lý chỉ số palette hiện tại trong [themePalettes].
final themePaletteIndexProvider =
    StateNotifierProvider<ThemePaletteNotifier, int>(
      (ref) => ThemePaletteNotifier(),
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
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    return setThemeMode(nextMode);
  }
}

class ThemePaletteNotifier extends StateNotifier<int> {
  ThemePaletteNotifier() : super(0) {
    _load();
  }

  // Dùng cùng key cũ để không mất lựa chọn đã lưu.
  static const _key = 'theme_seed_color_index';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_key);
    if (stored == null) return;
    if (stored >= 0 && stored < themePalettes.length) {
      state = stored;
    }
  }

  Future<void> setPaletteIndex(int index) async {
    if (index == state) return;
    if (index < 0 || index >= themePalettes.length) return;
    state = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }
}
