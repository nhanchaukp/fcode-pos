import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    // 1. Image Clipboard Channel
    let clipboardChannel = FlutterMethodChannel(
      name: "fcode/image_clipboard",
      binaryMessenger: messenger
    )

    clipboardChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "copyImage" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Thiếu đường dẫn ảnh", details: nil))
          return
        }

        self?.copyImageToClipboard(imagePath: path)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // 2. App Group Channel (Notification Sound Sync for UNNotificationServiceExtension)
    let appGroupChannel = FlutterMethodChannel(
      name: "fcode/app_group",
      binaryMessenger: messenger
    )

    appGroupChannel.setMethodCallHandler { (call, result) in
      if call.method == "setNotificationSound" {
        guard let args = call.arguments as? [String: Any],
              let fileName = args["fileName"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Thiếu tên file sound", details: nil))
          return
        }

        let appGroupId = "group.com.nhanchaukp.fcode.pos"
        if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
          sharedDefaults.set(fileName, forKey: "selected_notification_sound_filename")
          sharedDefaults.synchronize()
          print("[iOS App Group] Saved notification sound: \(fileName) to \(appGroupId)")
        } else {
          print("[iOS App Group] Failed to access UserDefaults for suite: \(appGroupId)")
        }
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func copyImageToClipboard(imagePath: String) {
    if let image = UIImage(contentsOfFile: imagePath) {
      UIPasteboard.general.image = image
      print("[iOS] Copied image to clipboard")
    } else {
      print("[iOS] Không thể load ảnh tại \(imagePath)")
    }
  }
}
