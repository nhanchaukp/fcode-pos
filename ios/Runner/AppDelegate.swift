import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "fcode/image_clipboard",
                                           binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { (call, result) in
            if call.method == "copyImage" {
                guard let args = call.arguments as? [String: Any],
                      let path = args["path"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Thiếu đường dẫn ảnh", details: nil))
                    return
                }

                self.copyImageToClipboard(imagePath: path)
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
