import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "fcode/image_clipboard",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
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
