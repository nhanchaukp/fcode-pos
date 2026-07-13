# Twotone Icon Index

Chỉ mục icon **Amazing Icons Twotone** — gồm icon đã dùng trong project và catalog tra cứu từ package.

- Package: [`amazing_icons`](https://pub.dev/packages/amazing_icons) `^3.1.1` — **956 icon** twotone
- Import: `import 'package:amazing_icons/twotone.dart';`
- Typedef dùng chung: `TwotoneIconBuilder` trong `lib/ui/components/badge_twotone_icon.dart`
- Cột **Project**: ✅ = đã map trong codebase (41 icon)

## Cách dùng

```dart
import 'package:amazing_icons/twotone.dart';

// Gọi trực tiếp
AmazingIconTwotone.box(size: 28, color: Colors.blue, opacity: 0.4)

// Trong badge / chip (thường opacity 0.45)
AmazingIconTwotone.tickCircle(size: 14, color: color, opacity: 0.45)
```

| Tham số | Mặc định | Ghi chú |
|---------|----------|---------|
| `size` | `25` | Hub grid: 28, badge: 12–14, service badge: 20 |
| `color` | `Colors.black` | Thường dùng màu semantic (`primary`, `error`, …) |
| `opacity` | `0.4` | Lớp nền twotone; badge/chip thường `0.45`, service badge `0.35` |

---

## Catalog từ package (theo chức năng hiển thị)

> **194 icon** được index theo ngữ cảnh POS/e-commerce. Mỗi icon có 2 lớp màu (foreground + background opacity) tạo hiệu ứng chiều sâu twotone.

### Thêm / Tạo mới

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `add` | Nút thêm, tạo mới đơn giản |  |
| `addCircle` | Thêm trong vòng tròn — tạo record mới | ✅ |
| `addItem` | Thêm mục vào danh sách |  |
| `addSquare` | Thêm trong ô vuông |  |
| `archiveAdd` | Thêm vào kho lưu trữ |  |
| `receiptAdd` | Tạo hóa đơn / biên lai mới |  |
| `noteAdd` | Thêm ghi chú |  |
| `messageAdd` | Soạn tin / thêm hội thoại |  |
| `messageAdd1` | Thêm tin nhắn (biến thể) |  |
| `boxAdd` | Nhập kho / thêm hàng |  |
| `moneyAdd` | Cộng tiền / nạp số dư |  |
| `profileAdd` | Thêm người dùng / khách hàng |  |

### Đóng / Hủy / Từ chối

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `closeCircle` | Đóng hoặc hủy trong vòng tròn | ✅ |
| `closeSquare` | Đóng hoặc hủy trong ô vuông |  |
| `boxRemove` | Xuất kho / hết hàng / gỡ sản phẩm | ✅ |
| `moneyRemove` | Trừ tiền / hoàn trừ |  |
| `profileRemove` | Xóa người dùng |  |
| `profileDelete` | Xóa hồ sơ vĩnh viễn |  |
| `truckRemove` | Hủy giao hàng |  |
| `noteRemove` | Xóa ghi chú |  |
| `forbidden` | Không cho phép / không áp dụng | ✅ |
| `forbidden2` | Cấm truy cập (biến thể) |  |
| `shieldSlash` | Bảo mật bị vô hiệu |  |
| `lockSlash` | Không khóa / mở khóa |  |

### Xác nhận / Hoàn thành

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `check` | Đánh dấu đúng / xác nhận |  |
| `tickCircle` | Thành công / đã duyệt / khả dụng | ✅ |
| `tickSquare` | Hoàn tất trong ô vuông |  |
| `verify` | Xác minh / đã hoàn thành | ✅ |
| `shieldTick` | Được bảo hành / bảo vệ hợp lệ | ✅ |
| `boxTick` | Hàng đã kiểm / nhập kho OK |  |
| `bagTick` | Đơn mua đã xử lý |  |
| `truckTick` | Giao hàng thành công |  |
| `moneyTick` | Thanh toán thành công |  |
| `profileTick` | Tài khoản đã xác thực |  |
| `refreshCircle` | Làm mới hoàn tất |  |

### Chờ / Thời gian / Hết hạn

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `timer1` | Đang chờ / đếm ngược | ✅ |
| `timerPause` | Tạm dừng hẹn giờ |  |
| `timerStart` | Bắt đầu đếm thời gian |  |
| `clock` | Thời hạn / hết hạn tài khoản | ✅ |
| `clock1` | Đồng hồ (biến thể) |  |
| `boxTime` | Hàng sắp hết hạn |  |
| `moneyTime` | Giao dịch chờ xử lý |  |
| `truckTime` | Giao hàng trễ / hẹn giao |  |
| `ticketExpired` | Vé / mã đã hết hạn |  |
| `messageTime` | Tin nhắn theo thời gian |  |

### Làm mới / Hoàn tác

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `refresh` | Đang xử lý / tải lại | ✅ |
| `refresh2` | Làm mới dữ liệu (biến thể) |  |
| `refreshCircle` | Refresh trong vòng tròn |  |
| `refreshLeftSquare` | Quay lại và làm mới |  |
| `refreshRightSquare` | Tiến và làm mới |  |
| `refreshSquare2` | Làm mới trong ô vuông |  |
| `rotateLeft` | Xoay / quay lui thao tác |  |
| `rotateRight` | Xoay / lặp lại thao tác |  |
| `rotate3d` | Xoay 3D / đổi góc nhìn |  |
| `undo` | Hoàn tiền / hoàn tác | ✅ |

### Cảnh báo / Lỗi / Thông tin

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `danger` | Lỗi / rủi ro / sản phẩm lỗi | ✅ |
| `warning2` | Cảnh báo cần chú ý |  |
| `chartFail` | Biểu đồ thất bại / KPI xấu |  |
| `infoCircle` | Thông tin / trạng thái không xác định | ✅ |
| `information` | Chi tiết thông tin bổ sung |  |
| `shieldCross` | Bảo mật bị chặn |  |

### Người dùng / Khách hàng

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `profile` | Một người dùng / khách hàng | ✅ |
| `profile2user` | Nhóm khách hàng / nhiều user | ✅ |
| `profileCircle` | Avatar trong vòng tròn |  |
| `profileAdd` | Thêm khách hàng |  |
| `profileRemove` | Gỡ khách hàng |  |
| `profileTick` | Khách đã xác thực |  |
| `personalcard` | Thẻ căn cước / thông tin cá nhân |  |

### Bảo mật / Mật khẩu / Vault

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `key` | Kho tài khoản / API key | ✅ |
| `keySquare` | Khóa trong ô vuông |  |
| `lock` | Cần mật khẩu / đã khóa | ✅ |
| `lock1` | Khóa (biến thể) |  |
| `lockCircle` | Khóa bảo mật vòng tròn |  |
| `lockSlash` | Không yêu cầu mật khẩu |  |
| `shieldSecurity` | Ví bảo mật / vault | ✅ |
| `shieldSearch` | Quét bảo mật |  |
| `shieldTick` | Được bảo vệ / bảo hành | ✅ |
| `shieldSlash` | Tắt bảo vệ |  |
| `passwordCheck` | Kiểm tra mật khẩu |  |

### Hộp / Kho / Sản phẩm

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `box` | Sản phẩm / còn tồn kho | ✅ |
| `box1` | Thùng hàng (biến thể 1) |  |
| `box2` | Thùng hàng (biến thể 2) |  |
| `boxAdd` | Nhập kho |  |
| `boxRemove` | Hết tồn / xuất kho | ✅ |
| `boxSearch` | Tra cứu tồn kho |  |
| `boxTick` | Kiểm kho OK |  |
| `boxTime` | Hàng sắp hết hạn |  |
| `bag` | Túi hàng / đơn mua |  |
| `bag2` | Túi hàng (biến thể) |  |
| `bagTick` | Đơn đã gói |  |
| `bagCross` | Hủy đơn / túi lỗi |  |
| `shoppingBag` | Hoàn sản phẩm / mua lẻ | ✅ |
| `shoppingCart` | Giỏ hàng |  |
| `scanBarcode` | SKU / mã vạch | ✅ |
| `barcode` | Mã vạch đơn giản |  |
| `scan` | Quét mã |  |
| `scanner` | Máy quét |  |
| `scanning` | Đang quét |  |

### Danh mục / Phân loại

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `category` | Nhóm sản phẩm / tất cả danh mục | ✅ |
| `category2` | Phân loại (biến thể) |  |
| `layer` | Mua nhiều / nhiều lớp | ✅ |

### Tiền / Thanh toán / Ví

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `money` | Tiền / tài chính chung |  |
| `money2` | Tiền (biến thể 2) |  |
| `money3` | Tiền (biến thể 3) |  |
| `money4` | Tiền (biến thể 4) |  |
| `moneyAdd` | Cộng tiền |  |
| `moneyChange` | Đổi tiền / tỷ giá |  |
| `moneyForbidden` | Không được thanh toán |  |
| `moneyRecive` | Hoàn tiền / nhận tiền | ✅ |
| `moneyRemove` | Trừ tiền |  |
| `moneySend` | Chuyển tiền / chi tiền |  |
| `moneyTick` | Thanh toán OK |  |
| `moneyTime` | Giao dịch chờ |  |
| `moneys` | Nhiều khoản tiền |  |
| `wallet` | Ví / số dư | ✅ |
| `tag` | Giá nhập / nhãn giá | ✅ |
| `ticketDiscount` | Mã giảm giá | ✅ |

### Vận chuyển / Nhà cung cấp

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `truck` | Nhà cung cấp / giao hàng | ✅ |
| `truckFast` | Giao nhanh |  |
| `truckRemove` | Hủy vận chuyển |  |
| `truckTick` | Giao thành công |  |
| `truckTime` | Giao trễ / hẹn giao |  |

### Email / Tin nhắn / Bot

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `email` | Email / nhật ký gửi mail | ✅ |
| `emailAi` | Email AI / tự động |  |
| `emailEdit` | Soạn / sửa email |  |
| `emailNotification` | Thông báo email |  |
| `emailSearch` | Tìm email |  |
| `emailStar` | Email quan trọng |  |
| `emailTracking` | Theo dõi email |  |
| `message` | Tin nhắn |  |
| `message2` | Tin nhắn (biến thể) |  |
| `messageProgramming` | ChatGPT / bot lập trình | ✅ |
| `messageCircle` | Chat vòng tròn |  |
| `messageSquare` | Chat ô vuông |  |
| `messageText` | Nội dung tin nhắn |  |
| `messages` | Hộp thư đến |  |
| `send2` | Gửi / Telegram bot | ✅ |

### Tài liệu / Ghi chú / Hóa đơn

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `document` | Tài liệu chung |  |
| `document1` | Tài liệu (biến thể) |  |
| `documentText` | Văn bản / nội dung file |  |
| `documentText1` | Văn bản (biến thể) |  |
| `documentCopy` | Sao chép tài liệu |  |
| `documentDownload` | Tải tài liệu |  |
| `documentUpload` | Tải lên tài liệu |  |
| `note` | Nháp / ghi chú | ✅ |
| `note1` | Ghi chú (biến thể 1) |  |
| `note2` | Ghi chú (biến thể 2) |  |
| `note3` | Ghi chú (biến thể 3) |  |
| `noteAdd` | Thêm ghi chú |  |
| `noteText` | Nội dung ghi chú |  |
| `noteSquare` | Sticky note |  |
| `receipt` | Biên lai |  |
| `receipt1` | Biên lai (biến thể 1) |  |
| `receipt2` | Biên lai (biến thể 2) |  |
| `receipt3` | Biên lai (biến thể 3) |  |
| `receiptText` | Hóa đơn điện tử | ✅ |
| `receiptDiscount` | Chiết khấu trên hóa đơn |  |
| `receiptDiscount2` | Giảm giá hóa đơn (biến thể) |  |

### Biểu đồ / Báo cáo / Thống kê

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `chart` | Hoàn một phần / biểu đồ | ✅ |
| `chart1` | Biểu đồ cột/line (biến thể 1) |  |
| `chart2` | Biểu đồ (biến thể 2) |  |
| `chart3` | Biểu đồ (biến thể 3) |  |
| `chart4` | Biểu đồ (biến thể 4) |  |
| `chartFail` | KPI thất bại |  |
| `chartSquare` | Biểu đồ trong ô vuông |  |
| `chartSuccess` | KPI tốt / tăng trưởng |  |
| `statusUp` | Tăng trưởng / Adsense / thống kê lên | ✅ |
| `status` | Trạng thái chung |  |
| `medalStar` | Đánh giá / huy chương | ✅ |

### Vé / Phiếu / Voucher

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `ticket` | Voucher / vé Icallme | ✅ |
| `ticket2` | Vé (biến thể) |  |
| `ticketDiscount` | Mã giảm giá | ✅ |
| `ticketExpired` | Vé hết hạn |  |
| `ticketStar` | Vé VIP / ưu đãi |  |

### Thương hiệu / Dịch vụ streaming

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `monitor` | Netflix / màn hình streaming | ✅ |
| `monitorMobbile` | Xem trên mobile |  |
| `monitorRecorder` | Ghi màn hình |  |
| `youtube` | YouTube | ✅ |
| `googlePlay` | Google One / Play | ✅ |
| `googleDrive` | Google Drive |  |
| `android` | Android |  |
| `apple` | Apple / iOS |  |

### Cài đặt / Hệ thống

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `setting` | Cài đặt / Microsoft / dịch vụ | ✅ |
| `setting2` | Cài đặt (biến thể 2) |  |
| `setting3` | Cài đặt (biến thể 3) |  |
| `setting4` | Cài đặt (biến thể 4) |  |
| `setting5` | Cài đặt (biến thể 5) |  |
| `settings` | Nhiều cài đặt / config |  |

### Menu / Khác

| API | Chức năng hiển thị | Project |
|-----|-------------------|---------|
| `more` | Lý do khác / thêm tùy chọn | ✅ |
| `more2` | Menu thêm (biến thể) |  |
| `moreCircle` | Thêm trong vòng tròn |  |
| `moreSquare` | Thêm trong ô vuông |  |
| `menu` | Menu điều hướng |  |
| `menuBoard` | Bảng menu / dashboard |  |

<!-- total=194 used=45 pkg=956 -->

---

## Theo ngữ cảnh sử dụng

### Product Hub (`lib/screens/tabs/product_hub_screen.dart`)

| Màn hình | Icon |
|----------|------|
| Sản phẩm | `box` |
| Kho tài khoản | `key` |
| Ví tài khoản | `shieldSecurity` |
| Nhà cung cấp | `truck` |
| Hoàn tiền | `moneyRecive` |
| Giá nhập | `tag` |
| Khách hàng | `profile2user` |
| Nhật ký email | `email` |
| Tài chính | `wallet` |
| Đánh giá | `medalStar` |
| Mã giảm giá | `ticketDiscount` |
| Hóa đơn ĐT | `receiptText` |
| Google Adsense | `statusUp` |
| ChatGPT | `messageProgramming` |
| Icallme | `ticket` |
| Telegram Bot | `send2` |

### Badge enum (`lib/ui/components/badge_twotone_icon.dart`)

Resolver `twotoneIconFor()` — dùng bởi `EnumBadge` và các badge wrapper.

| Enum | Giá trị | Icon |
|------|---------|------|
| **OrderStatus** | all | `category` |
| | new_ | `addCircle` |
| | paymentSuccess | `tickCircle` |
| | processing | `refresh` |
| | complete | `verify` |
| | cancel | `closeCircle` |
| | underWarranty | `shieldTick` |
| | refund | `undo` |
| **RefundStatus** | pending | `timer1` |
| | approved | `tickCircle` |
| | rejected | `closeCircle` |
| | completed | `verify` |
| **RefundType** | pending | `timer1` |
| | partial | `chart` |
| | full | `tickCircle` |
| | item | `shoppingBag` |
| | none | `forbidden` |
| **RefundReason** | customerRequest | `profile` |
| | productDefect | `danger` |
| | deliveryIssue | `truck` |
| | accountExpired | `clock` |
| | serviceIssue | `setting` |
| | other | `more` |
| **InvoiceStatus** | draft | `note` |
| | issued | `tickCircle` |
| | cancelled | `closeCircle` |
| **MailLogStatus** | sent | `tickCircle` |
| | pending | `timer1` |
| | failed | `danger` |
| **IcallmeVoucherStatus** | available | `tickCircle` |
| | used | `verify` |
| | revoked | `closeCircle` |
| | expired | `timer1` |
| | unknown | `infoCircle` |

### Service Badge (`lib/ui/components/service_badge.dart`)

| `serviceType` | Icon | Màu nền |
|---------------|------|---------|
| `netflix` | `monitor` | `#E50914` |
| `youtube` | `youtube` | `#FF0000` |
| `google_one` | `googlePlay` | `#4285F4` |
| `chatgpt` | `messageProgramming` | `#10A37F` |
| `microsoft` | `setting` | `#00A4EF` |
| *(default)* | `infoCircle` | `#9E9E9E` |

### Product List Chips (`lib/ui/components/product_list_item.dart`)

| Chip | Icon |
|------|------|
| SKU | `scanBarcode` |
| Nhóm | `category` |
| Tồn (> 0) | `box` |
| Tồn (= 0) | `boxRemove` |
| Mua nhiều | `layer` |
| Cần tài khoản | `profile` |
| Cần mật khẩu | `lock` |

---

## Thêm icon mới

1. Tra icon trong **Catalog** phía trên hoặc toàn bộ package (`AmazingIconTwotone.<tên>`) — [amazing_icons](https://pub.dev/packages/amazing_icons).
2. Map vào `badge_twotone_icon.dart` nếu là enum badge, hoặc dùng trực tiếp tại component.
3. Cập nhật cột **Project** ✅ và mục **Theo ngữ cảnh sử dụng** trong file docs này.
