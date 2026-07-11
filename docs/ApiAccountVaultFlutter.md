# Account Vault API — Flutter

Kho lưu credential (email, password, OAuth, 2FA). **Admin only.**

```
Base:  https://fcode.test/api
Auth:  Authorization: Bearer <token>
Header: Accept: application/json
        Content-Type: application/json
```

---

## Endpoints

| Method | Path | Mô tả |
|--------|------|--------|
| `GET` | `/account-vault` | Danh sách (search + filter) |
| `GET` | `/account-vault/providers` | Distinct providers |
| `GET` | `/account-vault/{id}` | Chi tiết **có secrets (đã decrypt)** |
| `POST` | `/account-vault` | Tạo |
| `PUT` | `/account-vault/{id}` | Cập nhật |
| `DELETE` | `/account-vault/{id}` | Xóa |

---

## Models

### List item (không có secrets)

```json
{
  "id": 1,
  "email": "ops@example.com",
  "provider": "google",
  "is_active": true,
  "notes": "Prod OAuth",
  "has_password": true,
  "has_client_id": true,
  "has_refresh_token": true,
  "has_two_factor_secret": false,
  "created_at": "2026-07-11T12:00:00.000000Z",
  "updated_at": "2026-07-11T12:00:00.000000Z"
}
```

### Detail (có secrets)

List item + thêm:

```json
{
  "password": "plain-password",
  "client_id": "xxx.apps.googleusercontent.com",
  "refresh_token": "1//0g...",
  "two_factor_secret": "JBSWY3DPEHPK3PXP"
}
```

> List chỉ dùng cờ `has_*`. Secrets chỉ có ở **show / create / update response**.

---

## 1. List

```
GET /api/account-vault?q=ops&provider=google&is_active=1&per_page=15
```

| Query | Type | Mô tả |
|-------|------|--------|
| `q` | string? | Search theo **email** |
| `provider` | string? | Filter exact |
| `is_active` | `0` \| `1`? | Filter active |
| `per_page` | int? | Default `15`, max `100` |

**Response `200`:**

```json
{
  "success": true,
  "message": "...",
  "data": {
    "current_page": 1,
    "data": [ /* list items */ ],
    "per_page": 15,
    "total": 1,
    "last_page": 1
  }
}
```

Flutter:

```dart
final items = (res['data']['data'] as List).cast<Map<String, dynamic>>();
final total = res['data']['total'] as int;
```

---

## 2. Providers

```
GET /api/account-vault/providers
```

**Response `200`:**

```json
{
  "success": true,
  "message": "...",
  "data": ["apple", "google", "microsoft"]
}
```

Dùng cho dropdown filter.

---

## 3. Detail

```
GET /api/account-vault/{id}
```

**Response `200`:** object detail (có secrets).

---

## 4. Create

```
POST /api/account-vault
```

```json
{
  "email": "ops@example.com",
  "password": "secret",
  "client_id": "cid",
  "provider": "google",
  "refresh_token": "rt",
  "two_factor_secret": "BASE32",
  "is_active": true,
  "notes": "optional"
}
```

| Field | Required | Notes |
|-------|----------|--------|
| `email` | ✅ | unique, max 255 |
| `password` | ❌ | max 2000 |
| `client_id` | ❌ | |
| `provider` | ❌ | string free-form |
| `refresh_token` | ❌ | |
| `two_factor_secret` | ❌ | |
| `is_active` | ❌ | bool, default `true` |
| `notes` | ❌ | |

**Response `201`:** detail object (có secrets).

---

## 5. Update

```
PUT /api/account-vault/{id}
```

Partial OK — chỉ gửi field cần đổi.

```json
{
  "email": "new@example.com",
  "password": "new-secret",
  "is_active": false
}
```

**Response `200`:** detail object (có secrets).

---

## 6. Delete

```
DELETE /api/account-vault/{id}
```

**Response `200`:**

```json
{
  "success": true,
  "message": "...",
  "data": null
}
```

---

## Errors

| Status | Khi nào |
|--------|---------|
| `401` | Chưa login |
| `403` | Không phải admin |
| `404` | Không tìm thấy |
| `422` | Validation fail |

```json
{
  "message": "The email has already been taken.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

Flutter:

```dart
if (status == 422) {
  final errors = res['errors'] as Map<String, dynamic>?;
  final emailError = (errors?['email'] as List?)?.first;
}
```

---

## Gợi ý model Flutter

```dart
class AccountVault {
  final int id;
  final String email;
  final String? provider;
  final bool isActive;
  final String? notes;
  final bool hasPassword;
  final bool hasClientId;
  final bool hasRefreshToken;
  final bool hasTwoFactorSecret;
  // detail only:
  final String? password;
  final String? clientId;
  final String? refreshToken;
  final String? twoFactorSecret;

  bool get isDetail => password != null || clientId != null
      || refreshToken != null || twoFactorSecret != null;
}
```

---

## Security (Flutter)

- Không log body chứa `password` / `refresh_token` / `two_factor_secret`
- Màn list: chỉ hiện email + provider + cờ `has_*`
- Chỉ gọi `GET /{id}` khi user mở màn chi tiết / copy secret
