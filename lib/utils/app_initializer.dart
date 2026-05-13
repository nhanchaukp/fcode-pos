import 'dart:io';

import 'package:fcode_pos/config/google_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toastr_flutter/toastr.dart'
    show
        ToastrHelper,
        ToastrHideMethod,
        ToastrPosition,
        ToastrShowMethod,
        ToastrTheme;
import 'package:window_manager/window_manager.dart';

/// A utility class for initializing the Flutter application.
///
/// This class ensures Flutter bindings are initialized, configures
/// window dimensions for desktop applications, and sets the device
/// orientation for mobile platforms.
class AppInitializer {
  /// Initializes the application setup.
  ///
  /// Ensures Flutter bindings are initialized, sets up window dimensions,
  /// and configures device orientation settings.
  static Future<void> initialize({required ThemeMode themeMode}) async {
    _setupToastr(themeMode);
    await _setupWindowDimensions();
    await _setupDeviceOrientation();
    await _setupLocaleData();
    await _setupGoogleSignIn();
  }

  static void _setupToastr(ThemeMode themeMode) {
    final isDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
    ToastrHelper.configure(
      position: ToastrPosition.topCenter,
      showMethod: ToastrShowMethod.slideDown,
      hideMethod: ToastrHideMethod.slideUp,
      theme: isDark ? ToastrTheme.dark : ToastrTheme.light,
    );
  }

  /// Configures the window dimensions for desktop applications.
  ///
  /// Ensures the window manager is initialized and sets a minimum window size.
  static Future<void> _setupWindowDimensions() async {
    // Flutter maintains web on its own.
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) return;

    await windowManager.ensureInitialized();
    windowManager.setMinimumSize(const Size(425, 600));
  }

  /// Configures the device orientation and system UI overlays.
  ///
  /// Cho phép xoay dọc và ngang, đồng thời đảm bảo system UI overlays
  /// được cấu hình thủ công.
  static Future<void> _setupDeviceOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    );
  }

  /// Loads locale data required by intl formatters.
  static Future<void> _setupLocaleData() async {
    await initializeDateFormatting('vi');
  }

  /// Khởi tạo Google Sign-In SDK một lần duy nhất khi app khởi động.
  /// clientId được lấy từ GoogleConfig — điền vào lib/config/google_config.dart.
  static Future<void> _setupGoogleSignIn() async {
    try {
      String? clientId;
      if (!kIsWeb) {
        if (Platform.isIOS) clientId = GoogleConfig.iosClientId;
        if (Platform.isAndroid) clientId = GoogleConfig.androidClientId;
      }
      await GoogleSignIn.instance.initialize(clientId: clientId);
    } catch (_) {
      // Không block app startup nếu Google Sign-In chưa được cấu hình
    }
  }
}
