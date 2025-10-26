import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  static Future<void> initialize() async {
    _ensureInitialized();
    await _setupWindowDimensions();
    await _setupDeviceOrientation();
    await _setupLocaleData();
  }

  /// Ensures that Flutter bindings are initialized.
  static void _ensureInitialized() {
    WidgetsFlutterBinding.ensureInitialized();
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
  /// Locks the device orientation to portrait mode and ensures system
  /// UI overlays are manually configured.
  static Future<void> _setupDeviceOrientation() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    );
  }

  /// Loads locale data required by intl formatters.
  static Future<void> _setupLocaleData() async {
    await initializeDateFormatting('vi');
  }
}
