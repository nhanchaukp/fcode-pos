# API Documentation: Coupon Admin

## Overview

Coupon Admin API cho phép quản trị viên quản lý mã giảm giá (CRUD), xem lịch sử sử dụng, bật/tắt coupon và kiểm tra tính hợp lệ.


## Base URL

```
/api/coupon
```

---

## Endpoints

### 1. Danh sách Coupon

Lấy danh sách mã giảm giá có phân trang và bộ lọc.

**Endpoint:** `GET /api/coupon`

**Query Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `search` | string | ❌ | Tìm kiếm theo mã coupon (LIKE) |
| `type` | string | ❌ | Lọc theo loại: `subtraction`, `percentage`, `fixed` |
| `is_enabled` | boolean | ❌ | Lọc theo trạng thái: `1` (bật), `0` (tắt) |
| `sort` | string | ❌ | Sắp xếp theo: `created_at`, `expires_at`, `code` (mặc định: `created_at`) |
| `direction` | string | ❌ | Hướng sắp xếp: `asc`, `desc` (mặc định: `desc`) |
| `per_page` | number | ❌ | Số lượng mỗi trang (mặc định: 15) |

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "code": "SUMMER-50K",
        "type": "subtraction",
        "value": "50000",
        "is_enabled": true,
        "quantity": 100,
        "limit": 1,
        "max_discount": null,
        "expires_at": "2026-06-07T00:00:00.000000Z",
        "usage_count": 5,
        "created_at": "2026-05-07T00:00:00.000000Z",
        "updated_at": "2026-05-07T00:00:00.000000Z"
      }
    ],
    "per_page": 15,
    "total": 1,
    "last_page": 1
  }
}
```

---

### 2. Chi tiết Coupon

Lấy thông tin chi tiết một mã giảm giá kèm số lần đã sử dụng.

**Endpoint:** `GET /api/coupon/{id}`

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "id": 1,
    "code": "SUMMER-50K",
    "type": "subtraction",
    "value": "50000",
    "is_enabled": true,
    "quantity": 100,
    "limit": 1,
    "max_discount": null,
    "expires_at": "2026-06-07T00:00:00.000000Z",
    "usage_count": 5,
    "created_at": "2026-05-07T00:00:00.000000Z",
    "updated_at": "2026-05-07T00:00:00.000000Z"
  }
}
```

---

### 3. Tạo Coupon

Tạo mã giảm giá mới.

**Endpoint:** `POST /api/coupon`

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | ✅ | Mã giảm giá (tối đa 64 ký tự, duy nhất) |
| `type` | string | ✅ | Loại: `subtraction` (giảm trừ), `percentage` (%), `fixed` (giá cố định) |
| `value` | number | ✅ | Giá trị giảm giá (VND hoặc %) |
| `is_enabled` | boolean | ❌ | Trạng thái kích hoạt (mặc định: `true`) |
| `quantity` | number | ❌ | Số lượng coupon còn lại |
| `limit` | number | ❌ | Giới hạn số lần sử dụng mỗi user |
| `expires_at` | datetime | ✅ | Ngày hết hạn (phải sau thời điểm hiện tại) |
| `data.maxDiscount` | number | ✅* | Giới hạn giảm giá tối đa (*bắt buộc khi `type=percentage`) |

**Request Example (subtraction):**

```json
{
  "code": "SUMMER-50K",
  "type": "subtraction",
  "value": 50000,
  "is_enabled": true,
  "quantity": 100,
  "limit": 1,
  "expires_at": "2026-06-07 00:00:00"
}
```

**Request Example (percentage):**

```json
{
  "code": "SALE-10PCT",
  "type": "percentage",
  "value": 10,
  "is_enabled": true,
  "quantity": 50,
  "limit": 2,
  "expires_at": "2026-06-07 00:00:00",
  "data": {
    "maxDiscount": 100000
  }
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Coupon created",
  "data": {
    "id": 1,
    "code": "SUMMER-50K",
    "type": "subtraction",
    "value": "50000",
    "is_enabled": true,
    "quantity": 100,
    "limit": 1,
    "max_discount": null,
    "expires_at": "2026-06-07T00:00:00.000000Z",
    "usage_count": 0,
    "created_at": "2026-05-07T00:00:00.000000Z",
    "updated_at": "2026-05-07T00:00:00.000000Z"
  }
}
```

**Validation Errors (422):**

```json
{
  "message": "The code field is required. (and 3 more errors)",
  "errors": {
    "code": ["The code field is required."],
    "type": ["The type field is required."],
    "value": ["The value field is required."],
    "expires_at": ["The expires at field is required."]
  }
}
```

---

### 4. Cập nhật Coupon

Cập nhật thông tin mã giảm giá.

**Endpoint:** `PUT /api/coupon/{id}`

**Request Body:** Giống với endpoint Tạo Coupon. Trường `code` có thể giữ nguyên giá trị cũ.

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Coupon updated",
  "data": {
    "id": 1,
    "code": "SUMMER-50K-V2",
    "type": "subtraction",
    "value": "60000",
    "is_enabled": true,
    "quantity": 80,
    "limit": 2,
    "max_discount": null,
    "expires_at": "2026-07-07T00:00:00.000000Z",
    "usage_count": 5,
    "created_at": "2026-05-07T00:00:00.000000Z",
    "updated_at": "2026-05-07T10:00:00.000000Z"
  }
}
```

---

### 5. Xóa Coupon

Xóa mã giảm giá.

**Endpoint:** `DELETE /api/coupon/{id}`

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Coupon deleted",
  "data": null
}
```

---

### 6. Bật/Tắt Coupon

Chuyển đổi trạng thái kích hoạt của mã giảm giá.

**Endpoint:** `POST /api/coupon/{id}/toggle`

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Coupon disabled",
  "data": {
    "id": 1,
    "code": "SUMMER-50K",
    "type": "subtraction",
    "value": "50000",
    "is_enabled": false,
    "quantity": 100,
    "limit": 1,
    "max_discount": null,
    "expires_at": "2026-06-07T00:00:00.000000Z",
    "usage_count": 5,
    "created_at": "2026-05-07T00:00:00.000000Z",
    "updated_at": "2026-05-07T10:00:00.000000Z"
  }
}
```

---

### 7. Lịch sử sử dụng Coupon

Xem danh sách đơn hàng đã sử dụng mã giảm giá (phân trang).

**Endpoint:** `GET /api/coupon/{id}/usage`

**Query Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `per_page` | number | ❌ | Số lượng mỗi trang (mặc định: 15) |

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "current_page": 1,
    "data": [
      {
        "order_id": 42,
        "order_total": 250000,
        "order_status": "completed",
        "redeemed_at": "2026-05-06 14:30:00",
        "user": {
          "id": 10,
          "name": "Nguyễn Văn A",
          "email": "nguyenvana@example.com"
        }
      }
    ],
    "per_page": 15,
    "total": 1,
    "last_page": 1
  }
}
```

---

### 8. Kiểm tra Coupon (Preview)

Kiểm tra tính hợp lệ và xem trước giảm giá cho một user và số tiền cụ thể.

**Endpoint:** `POST /api/coupon/validate`

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | ✅ | Mã giảm giá cần kiểm tra |
| `user_id` | number | ✅ | ID của user cần kiểm tra |
| `total_amount` | number | ✅ | Tổng tiền đơn hàng |

**Request Example:**

```json
{
  "code": "SUMMER-50K",
  "user_id": 10,
  "total_amount": 200000
}
```

**Response - Hợp lệ (200 OK):**

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "valid": true,
    "message": "Mã giảm giá hợp lệ.",
    "discount": 50000,
    "final_amount": 150000,
    "details": {
      "code": "SUMMER-50K",
      "type": "subtraction",
      "value": "50000",
      "discount_text": "50,000₫",
      "max_discount": null,
      "expires_at": "07/06/2026 00:00",
      "quantity_remaining": 95,
      "is_enabled": true
    }
  }
}
```

**Response - Không hợp lệ (422):**

```json
{
  "success": false,
  "message": "Mã giảm giá đã hết hạn.",
  "errors": []
}
```

---

## Loại Coupon

| Type | Description | Cách tính |
|------|-------------|-----------|
| `subtraction` | Giảm trừ | Giảm trực tiếp `value` VND (tối đa = tổng đơn) |
| `percentage` | Phần trăm | Giảm `value`% tổng đơn (giới hạn bởi `data.maxDiscount`) |
| `fixed` | Giá cố định | Giảm trực tiếp `value` VND (tối đa = tổng đơn) |
