# 🚨 CRITICAL: Frontend Tidak Mengirim Bearer Token

## Masalah yang Ditemukan

**Tanggal**: 6 November 2025, 14:30  
**Severity**: CRITICAL 🔥

### Gejala

Data yang di-create dari frontend app tersimpan dengan `user_id = 1` padahal user login adalah user 8.

### Root Cause

Frontend **TIDAK mengirim Bearer token** di Authorization header!

### Bukti dari Log

```
[2025-11-06 06:30:03] local.INFO: ApiTokenAuth Middleware {
    "token_received":"NULL",    // ❌ TOKEN TIDAK ADA!
    "url":"http://192.168.8.48:8000/api/kontakpalsus",
    "method":"POST"
}
[2025-11-06 06:30:03] local.INFO: ApiTokenAuth: User authenticated {
    "user_id":1,                 // ❌ Fallback ke user 1
    "username":"admin"
}
```

### Mengapa User 1?

1. Frontend tidak kirim token → `$token = null`
2. Query `User::where('token', null)->first()` menemukan User 1 (yang token-nya memang NULL)
3. Middleware authenticate sebagai User 1
4. Data tersimpan dengan `user_id = 1`

---

## Backend Fix yang Sudah Dilakukan ✅

### 1. Middleware Sekarang Reject Request Tanpa Token

```php
// app/Http/Middleware/ApiTokenAuth.php

if (empty($token)) {
    Log::warning('ApiTokenAuth: No token provided');
    return response()->json([
        'message' => 'Unauthenticated - Token required',
        'error' => 'No Bearer token found in Authorization header'
    ], 401);
}
```

### 2. Test Verification

```bash
# Test dengan token (User 8): ✅ PASS
php test-frontend-request.php
# Result: 201 Created, user_id = 8

# Test tanpa token: ✅ PASS
php test-no-token.php
# Result: 401 Unauthorized
```

---

## 🎯 ACTION REQUIRED: Frontend Team

### CRITICAL - Implementasi WAJIB Segera!

#### 1. Verify Token Tersimpan di Storage

```dart
// Check apakah token ada
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');

if (token == null || token.isEmpty) {
  print('❌ ERROR: Token tidak ada! User harus login ulang');
  // Redirect ke login
  Navigator.pushReplacementNamed(context, '/login');
  return;
}

print('✅ Token found: ${token.substring(0, 10)}...');
```

#### 2. Pastikan Token Dikirim di SETIAP Request

```dart
// CORRECT ✅
final response = await http.post(
  Uri.parse('http://192.168.8.48:8000/api/kontakamans'),
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',  // ← WAJIB ADA!
  },
  body: jsonEncode({
    'name': nameController.text,
    'phoneNumber': phoneController.text,
    'relation': relationController.text,
  }),
);

// WRONG ❌
final response = await http.post(
  Uri.parse('http://192.168.8.48:8000/api/kontakamans'),
  headers: {
    'Content-Type': 'application/json',
    // ❌ TIDAK ADA Authorization header!
  },
  body: jsonEncode({...}),
);
```

#### 3. Handle 401 Error dengan Benar

```dart
if (response.statusCode == 401) {
  // Token invalid/expired atau tidak ada
  print('❌ Unauthenticated: ${response.body}');

  // Clear token & redirect ke login
  await prefs.remove('auth_token');
  await prefs.remove('user_id');

  if (mounted) {
    Navigator.pushReplacementNamed(context, '/login');
  }
  return;
}
```

#### 4. Debug Helper - Tambahkan Logging

```dart
// Di fungsi API call
Future<http.Response> createKontak(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  // DEBUG: Print untuk verifikasi
  print('🔍 DEBUG API Call:');
  print('  Token: ${token?.substring(0, 20) ?? "NULL"}...');
  print('  Endpoint: /api/kontakamans');
  print('  Data: $data');

  final response = await http.post(
    Uri.parse('$baseUrl/api/kontakamans'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(data),
  );

  print('  Response Status: ${response.statusCode}');
  print('  Response Body: ${response.body}');

  return response;
}
```

---

## Testing Guide untuk Frontend

### Test Case 1: Login dan Verify Token Tersimpan

```dart
// Setelah login berhasil
final loginResponse = await authService.login(username, password);

if (loginResponse.statusCode == 200) {
  final data = jsonDecode(loginResponse.body);

  // WAJIB: Simpan token
  await prefs.setString('auth_token', data['token']);
  await prefs.setInt('user_id', data['user']['id']);

  // VERIFY: Baca kembali untuk memastikan tersimpan
  final savedToken = prefs.getString('auth_token');
  print('✅ Token saved: ${savedToken?.substring(0, 20)}...');

  // TEST: Coba panggil GET /api/users/current
  final testResponse = await http.get(
    Uri.parse('$baseUrl/api/users/current'),
    headers: {'Authorization': 'Bearer $savedToken'},
  );

  if (testResponse.statusCode == 200) {
    print('✅ Token valid dan berfungsi!');
  } else {
    print('❌ Token tidak berfungsi: ${testResponse.body}');
  }
}
```

### Test Case 2: Create Data dengan Token

```dart
// User 8 token untuk testing
final testToken = 'c0649cdb-907f-4a15-8199-2ff3789a0c01';

final response = await http.post(
  Uri.parse('http://192.168.8.48:8000/api/kontakamans'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $testToken',
  },
  body: jsonEncode({
    'name': 'Test dari Flutter',
    'phoneNumber': '08123456789',
    'relation': 'Teman',
  }),
);

// Expected: 201 Created
// Response: {"data":{"id":7,"user_id":8,"name":"Test dari Flutter"}}
print('Status: ${response.statusCode}');
print('Body: ${response.body}');
```

### Test Case 3: Request Tanpa Token (Harus Gagal)

```dart
// Test: Request tanpa Authorization header
final response = await http.post(
  Uri.parse('http://192.168.8.48:8000/api/kontakamans'),
  headers: {
    'Content-Type': 'application/json',
    // ❌ Tidak ada Authorization header
  },
  body: jsonEncode({
    'name': 'Test No Token',
    'phoneNumber': '08123456789',
    'relation': 'Teman',
  }),
);

// Expected: 401 Unauthorized
// Response: {"message":"Unauthenticated - Token required"}
assert(response.statusCode == 401, 'Should return 401 without token');
```

---

## Checklist untuk Frontend Developer

### Immediate Actions (Hari Ini!)

-   [ ] Check apakah token tersimpan setelah login
-   [ ] Verify Authorization header dikirim di SEMUA API calls
-   [ ] Add logging untuk debug token issue
-   [ ] Test dengan user 8 token: `c0649cdb-907f-4a15-8199-2ff3789a0c01`
-   [ ] Verify response 401 handled dengan benar

### Code Review Checklist

-   [ ] Setiap `http.post()` / `http.get()` harus include `Authorization` header
-   [ ] Token diambil dari SharedPreferences sebelum setiap request
-   [ ] Handle case token null/empty → redirect ke login
-   [ ] Handle response 401 → clear token & redirect ke login
-   [ ] Tidak ada hardcoded user_id di request body

### Testing Checklist

-   [ ] Login dengan user "Yongky" (ID 8)
-   [ ] Create kontak baru
-   [ ] Verify di database: `user_id` harus = 8
-   [ ] Logout dan login lagi
-   [ ] Create data lagi, verify masih `user_id = 8`

---

## Database untuk Verifikasi

### User Tokens

```sql
-- User 1 (admin): Token = NULL ❌
-- User 8 (Yongky): Token = c0649cdb-907f-4a15-8199-2ff3789a0c01 ✅

SELECT id, username, name, token
FROM users
WHERE id IN (1, 8);
```

### Check Data Ownership

```sql
-- Cek kontak terakhir yang dibuat
SELECT id, name, user_id, created_at,
       (SELECT username FROM users WHERE id = kontak_amans.user_id) as owner
FROM kontak_amans
ORDER BY created_at DESC
LIMIT 5;
```

---

## Support & Contact

Jika masih ada masalah:

1. Cek log Laravel: `storage/logs/laravel.log`
2. Cek console output di Flutter
3. Gunakan Postman untuk test manual
4. Hubungi backend team dengan log error lengkap

**Backend Test Scripts Available:**

-   `php test-frontend-request.php` - Test dengan token User 8
-   `php test-no-token.php` - Test tanpa token (harus 401)
-   `php test-user-id.php` - Verify user_id logic

---

**Last Updated**: 6 November 2025, 14:35  
**Status**: Backend Fixed ✅ | Frontend Action Required 🚨
