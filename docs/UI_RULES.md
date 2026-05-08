# UI Rules (Compact • Borderless • Modern)

Mục tiêu của bộ quy tắc này là giữ giao diện **compact**, **không viền**, **hiện đại**, tối ưu hiển thị thông tin (đặc biệt trên mobile), đồng thời giảm style inline rải rác.

## Nguyên tắc nền tảng
- **Ưu tiên typography & nền** để phân tách thay vì viền (border).
- **Elevation thấp** (thường 0), hạn chế shadow nặng.
- **Spacing nhỏ nhưng đều**: dùng token thay vì hardcode nhiều giá trị rời rạc.
- **Đồng nhất**: component dùng chung + theme global > style inline.

## Token dùng chung
- **Spacing / Radius**: dùng `AppSpacing` / `AppRadius` trong `lib/ui/theme/tokens.dart`.
- **Không thêm token tuỳ hứng**: nếu cần mới, bổ sung có chủ đích và dùng nhất quán.

## Theme & component mặc định
- **Theme tổng** đặt tại `lib/app.dart`:
  - `useMaterial3: true`
  - `AppBarTheme` phẳng, không “scrolledUnderElevation”
  - `InputDecorationTheme` dạng `filled`, `isDense`, padding nhỏ
  - `NavigationBarTheme` chiều cao thấp (~60)
- **Card/Section container**:
  - Tránh `Card` có viền; ưu tiên `Container` với `colorScheme.surfaceContainer*` + radius 10–12.
  - Nếu cần phân tách mạnh: dùng `Divider` mảnh hoặc đổi `surfaceContainer` level.

## Pattern layout khuyến nghị
- **Section header**: dùng `SectionHeader` (`lib/ui/components/section_header.dart`) cho tiêu đề + icon + action.
- **List row compact**:
  - Ưu tiên `dense: true`, `visualDensity: VisualDensity.compact`
  - `contentPadding` nhỏ hơn mặc định
  - Icon nhỏ hơn (18–20) và hạn chế dùng quá nhiều icon phụ.
- **Empty state**:
  - Không dùng padding quá lớn; thông điệp ngắn gọn.
  - Dùng `surfaceVariant`/`surfaceContainer` để tạo mảng nền thay cho viền.

## Quy tắc “không viền”
- Tránh `Border.all(...)` mặc định.
- Chỉ dùng border khi có lý do UX rõ ràng (ví dụ field focus/error), và border phải **mờ + mảnh**.

## Quy tắc “compact”
- Mặc định giảm:
  - `padding` từ 16 → 12 (hoặc 10 theo ngữ cảnh)
  - khoảng cách giữa các item từ 12 → 8
- Luôn kiểm tra: chạm tay (tap target) vẫn đủ lớn, chữ vẫn đọc được.

## Review checklist khi tạo màn mới
- Có đang hardcode `padding/radius` rải rác không? Nếu có, cân nhắc token.
- Có dùng border để phân tách không? Nếu có, thử đổi nền + divider.
- Có thể trích xuất thành component dùng chung không? (header, row, summary block)

