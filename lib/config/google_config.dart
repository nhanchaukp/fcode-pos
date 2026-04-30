// HƯỚNG DẪN CẤU HÌNH GOOGLE OAUTH:
//
// 1. Vào Google Cloud Console: https://console.cloud.google.com/
// 2. Tạo project mới hoặc chọn project hiện có
// 3. Bật API: APIs & Services > Library > tìm "Google AdSense API" > Enable
// 4. Tạo OAuth credentials: APIs & Services > Credentials > Create Credentials > OAuth 2.0 Client IDs
//
// --- iOS ---
// - Loại: iOS
// - Bundle ID: lấy từ Xcode > Runner > Bundle Identifier
// - Download GoogleService-Info.plist HOẶC copy Client ID
// - Thêm vào ios/Runner/Info.plist:
//   <key>CFBundleURLTypes</key>
//   <array>
//     <dict>
//       <key>CFBundleTypeRole</key><string>Editor</string>
//       <key>CFBundleURLSchemes</key>
//       <array>
//         <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
//       </array>
//     </dict>
//   </array>
//   <key>GIDClientID</key><string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
//
// --- Android ---
// - Loại: Android
// - Package name: lấy từ android/app/build.gradle (applicationId)
// - SHA-1: chạy `cd android && ./gradlew signingReport`

class GoogleConfig {
  /// iOS OAuth 2.0 Client ID
  /// Dạng: XXXXXXXXXX-xxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
  static const String iosClientId =
      '930961706809-fibd3hqt1iah7cvvqurkuse1g7csr2ag.apps.googleusercontent.com'; // TODO: Điền iOS client ID của bạn

  /// Android OAuth 2.0 Client ID
  static const String _androidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
  );
  static String? get androidClientId =>
      _androidClientId.isEmpty ? null : _androidClientId;
}
