# Twotone Icon Index

Chỉ mục các icon **Amazing Icons Twotone** đã được dùng trong project.

- Package: [`amazing_icons`](https://pub.dev/packages/amazing_icons) `^3.1.1`
- Import: `import 'package:amazing_icons/twotone.dart';`
- Typedef dùng chung: `TwotoneIconBuilder` trong `lib/ui/components/badge_twotone_icon.dart`

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

## Danh sách icon đã dùng (A–Z)

| Icon | Tên API | Dùng ở đâu |
|------|---------|------------|
| ➕ Vòng tròn thêm | `addCircle` | `OrderStatus.new_` |
| 📦 Hộp | `box` | Product hub, sản phẩm còn tồn |
| 📦 Hộp xóa | `boxRemove` | Sản phẩm hết tồn |
| 📂 Danh mục | `category` | `OrderStatus.all`, nhóm sản phẩm |
| 📊 Biểu đồ | `chart` | `RefundType.partial` |
| 🕐 Đồng hồ | `clock` | `RefundReason.accountExpired` |
| ❌ Vòng tròn đóng | `closeCircle` | Hủy / từ chối / thu hồi |
| ⚠️ Cảnh báo | `danger` | Lỗi sản phẩm, mail thất bại |
| ✉️ Email | `email` | Product hub — Nhật ký email |
| 🚫 Cấm | `forbidden` | `RefundType.none` |
| ▶️ Google Play | `googlePlay` | Service badge — Google One |
| ℹ️ Thông tin | `infoCircle` | Service mặc định, voucher unknown |
| 🔑 Chìa khóa | `key` | Product hub — Kho tài khoản |
| 📚 Lớp | `layer` | Chip "Mua nhiều" |
| 🔒 Khóa | `lock` | Chip "Cần mật khẩu" |
| 🏅 Huy chương sao | `medalStar` | Product hub — Đánh giá |
| 💬 Lập trình | `messageProgramming` | Product hub — ChatGPT, service ChatGPT |
| 💰 Nhận tiền | `moneyRecive` | Product hub — Hoàn tiền |
| 🖥️ Màn hình | `monitor` | Service badge — Netflix |
| ⋯ Thêm | `more` | `RefundReason.other` |
| 📝 Ghi chú | `note` | `InvoiceStatus.draft` |
| 👤 Hồ sơ | `profile` | Yêu cầu KH, chip "Cần tài khoản" |
| 👥 Nhiều người | `profile2user` | Product hub — Khách hàng |
| 🧾 Hóa đơn | `receiptText` | Product hub — Hóa đơn ĐT |
| 🔄 Làm mới | `refresh` | `OrderStatus.processing` |
| 📱 Quét mã | `scanBarcode` | Chip SKU sản phẩm |
| 📤 Gửi | `send2` | Product hub — Telegram Bot |
| ⚙️ Cài đặt | `setting` | Service Microsoft, lý do dịch vụ |
| 🛡️ Bảo mật | `shieldSecurity` | Product hub — Ví tài khoản |
| 🛡️✓ Bảo vệ | `shieldTick` | `OrderStatus.underWarranty` |
| 🛍️ Túi mua | `shoppingBag` | `RefundType.item` |
| 📈 Tăng trưởng | `statusUp` | Product hub — Google Adsense |
| 🏷️ Thẻ giá | `tag` | Product hub — Giá nhập |
| 🎫 Vé | `ticket` | Product hub — Icallme |
| 🎟️ Giảm giá | `ticketDiscount` | Product hub — Mã giảm giá |
| ⏱️ Hẹn giờ | `timer1` | Chờ xử lý / hết hạn |
| ✅ Vòng tròn tick | `tickCircle` | Thành công / khả dụng / đã gửi |
| 🚚 Xe tải | `truck` | NCC, vấn đề giao hàng |
| ↩️ Hoàn tác | `undo` | `OrderStatus.refund` |
| ✔️ Xác minh | `verify` | Hoàn thành / đã dùng |
| 👛 Ví | `wallet` | Product hub — Tài chính |
| ▶️ YouTube | `youtube` | Service badge — YouTube |

**Tổng: 41 icon** đã được map trong codebase.

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

1. Tra tên icon trong package: `AmazingIconTwotone.<tên>` — xem [amazing_icons twotone catalog](https://pub.dev/packages/amazing_icons).
2. Map vào `badge_twotone_icon.dart` nếu là enum badge, hoặc dùng trực tiếp tại component.
3. Cập nhật file docs này khi thêm icon mới vào project.
