# Hướng dẫn Tích hợp APNs & FCM và Cập nhật Điều Khoản (In-App Browser)

Tài liệu này hướng dẫn chi tiết về cấu trúc mã nguồn đã được cập nhật và các bước cấu hình cần thiết trên **Apple Developer Console** và **Firebase Console** để hoàn tất việc nhận thông báo đẩy (Push Notifications) qua **APNs** và **FCM**.

---

## 1. Tóm tắt các thay đổi trong Codebase

### 📄 1.1 Cập nhật mở Điều khoản sử dụng trong In-App Browser
- **File**: `lib/screens/tabs/more_screen.dart`
- **Thay đổi**: Khi người dùng nhấn vào mục *"Điều khoản & Điều kiện"*, ứng dụng sẽ mở trực tiếp liên kết `https://fcode.vn/page/dieu-khoan-su-dung` bằng màn hình trình duyệt nội bộ `InAppBrowser`.

### 🔔 1.2 Tích hợp Service Quản lý Thông báo đẩy (FCM + APNs)
- **File mới**: `lib/services/notification_service.dart`
- **Chức năng**:
  - Tự động xin quyền hiển thị thông báo trên iOS và Android 13+.
  - Hiển thị banner thông báo nổi (Local Notification) khi ứng dụng đang chạy ở **Foreground**.
  - Lắng nghe sự kiện người dùng bấm vào thông báo ở trạng thái **Background** và **Terminated** (khi ứng dụng bị đóng hoàn toàn).
  - Cung cấp hàm lấy token: `getFCMToken()` (Firebase Messaging Token) và `getAPNsToken()` (Apple APNs Token trên iOS).
- **Khởi tạo tự động**: Đã kết nối vào `AppInitializer` (`lib/utils/app_initializer.dart`).

---

## 2. Hướng dẫn Cấu hình APNs Key (.p8) và Firebase Console

Để ứng dụng nhận được thông báo thực tế từ Server đến thiết bị iOS và Android, cần hoàn thành 4 bước cấu hình sau:

### 🔑 Bước 2.1: Tạo APNs Key trên Apple Developer Console
1. Truy cập trang [Apple Developer - Keys](https://developer.apple.com/account/resources/authkeys/list).
2. Nhấn nút **+** (Create a Key).
3. Đặt tên Key (ví dụ: `FCM Push Notification Key`).
4. Tích chọn dịch vụ **Apple Push Notifications service (APNs)**.
5. Bấm **Continue** ➔ **Register**.
6. Tải tệp **`.p8`** về máy *(Lưu ý: Tệp này chỉ cho phép tải về 1 lần duy nhất)*.
7. Ghi lại **Key ID** (10 ký tự) và **Team ID** (hiển thị góc trên bên phải trang Apple Developer).

---

### 🔥 Bước 2.2: Tải APNs Key lên Firebase Console
1. Truy cập [Firebase Console](https://console.firebase.google.com/) ➔ Chọn dự án của bạn.
2. Nhấn vào biểu tượng Bánh răng (⚙️) ➔ Chọn **Project Settings** ➔ chọn tab **Cloud Messaging**.
3. Cuộn xuống mục **Apple app configuration**.
4. Tại mục **APNs Authentication Key**, bấm **Upload**:
   - Tải tệp `.p8` vừa tải ở Bước 2.1 lên.
   - Nhập **Key ID** và **Team ID**.
   - Bấm **Save**.

---

### 📁 Bước 2.3: Thêm File cấu hình Firebase vào Dự án

#### Dành cho iOS:
1. Trên Firebase Console, thêm ứng dụng iOS với Bundle ID: `com.nhanchaukp.fcode.pos`.
2. Tải tệp **`GoogleService-Info.plist`** về máy.
3. Mở Xcode bằng lệnh:
   ```bash
   open ios/Runner.xcworkspace
   ```
4. Kéo thả tệp `GoogleService-Info.plist` vào thư mục `Runner` trong danh sách file bên trái của Xcode (Nhớ tích chọn *Copy items if needed* và chọn target *Runner*).

#### Dành cho Android:
1. Trên Firebase Console, thêm ứng dụng Android với Package Name: `com.nhanchaukp.fcode.pos`.
2. Tải tệp **`google-services.json`** về máy.
3. Chép tệp `google-services.json` vào thư mục `android/app/`.

---

### 🛠 Bước 2.4: Bật Capabilities trên Xcode (iOS)
1. Mở Xcode bằng lệnh:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Chọn target **Runner** (ở cột bên trái) ➔ Chọn tab **Signing & Capabilities**.
3. Bấm **+ Capability** và thêm 2 quyền sau:
   - **Push Notifications**
   - **Background Modes**: Tích chọn 2 ô:
     - [x] **Remote notifications**
     - [x] **Background fetch**

---

## 3. Hướng dẫn Build & Deploy TestFlight

### 3.1 Cập nhật số Build (Build Number)
Trong tệp `pubspec.yaml`, tăng giá trị phía sau dấu `+`:
```yaml
version: 1.0.110+122  # Tăng số build number từ 121 -> 122
```

### 3.2 Đóng gói ứng dụng (IPA)
Chạy lệnh đóng gói Release bằng Flutter CLI:
```bash
flutter build ipa --release
```

### 3.3 Upload lên TestFlight
- Sử dụng ứng dụng **Transporter** (từ Mac App Store) kéo thả tệp `.ipa` tạo ra tại `build/ios/ipa/*.ipa` và bấm **Deliver**.
- Hoặc mở **Xcode** ➔ **Window** ➔ **Organizer** ➔ Chọn bản Archive ➔ **Distribute App** ➔ **TestFlight & App Store**.
