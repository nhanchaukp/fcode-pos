import 'dart:io';

import 'package:credential_manager/credential_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// A utility class for initializing the Flutter application.
///
/// This class ensures Flutter bindings are initialized, configures
/// window dimensions for desktop applications, and sets the device
/// orientation for mobile platforms.
class AppInitializer {
  // Instance of CredentialManager
  static final CredentialManager credentialManager = CredentialManager();

  /// Initializes the application setup.
  ///
  /// Ensures Flutter bindings are initialized, sets up window dimensions,
  /// and configures device orientation settings.
  static Future<void> initialize() async {
    _ensureInitialized();
    await _setupWindowDimensions();
    await _setupDeviceOrientation();
    await initializeCredentialManager();
  }

  static Future<void> initializeCredentialManager() async {
    // You can add any necessary initialization code for CredentialManager here.
    // For example, checking platform support or setting up configurations.
    if (credentialManager.isSupportedPlatform) {
      credentialManager.init(
        preferImmediatelyAvailableCredentials: true,
      );
    }
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
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
    );
  }
}
