# 🔌 API Endpoints - Health App Version

## All Available API Endpoints for Health App

---

## ✅ All Endpoints Available

Health app version has access to **ALL** API endpoints:

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/register` | ❌ | Register new user |
| POST | `/api/login` | ❌ | Login user |
| GET | `/api/me` | ✅ | Get current user info |
| POST | `/api/logout` | ✅ | Logout user |

### Wellness & Onboarding

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/wellness/questions` | ✅ | Get wellness/health questions |
| POST | `/api/onboarding/submit` | ✅ | Submit onboarding answers |
| GET | `/api/wellness/profile` | ✅ | Get user wellness profile |
| PUT | `/api/wellness/profile` | ✅ | Update wellness profile |
| POST | `/api/wellness/answers` | ✅ | Submit answers separately |
| GET | `/api/wellness/stats` | ✅ | Get wellness statistics |
| POST | `/api/wellness/upgrade-to-health` | ✅ | Upgrade from general to health |

### Period Tracking (Health Only)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/catatan-haid` | ✅ | Submit period data |
| GET | `/api/catatan-haid` | ✅ | Get period history |
| GET | `/api/catatan-haid/stats` | ✅ | Get period statistics |

---

## 📝 Usage Examples

### 1. Registration (Health Version)

```dart
final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'name': 'Jane Doe',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'password': 'password123',
    'gender': 'Perempuan',
    'dob': '1995-05-15',
    'app_version': 'health', // ← IMPORTANT
  }),
);

final token = jsonDecode(response.body)['token'];
```

---

### 2. Get Health Questions

```dart
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/wellness/questions?type=health&limit=10'),
  headers: AuthService.getAuthHeaders(),
);

final questions = jsonDecode(response.body)['data'];
// Returns health-related questions (cycle, period, etc.)
```

---

### 3. Submit Onboarding (Health)

```dart
final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/onboarding/submit'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'answers': [
      {'question_id': 10, 'option_id': 20, 'answer_type': 'health'},
      {'question_id': 11, 'answer_text': '2026-02-01', 'answer_type': 'health'},
    ],
    'cycle_regularity': 'regular',
    'last_period_start': '2026-02-01',
    'last_period_end': '2026-02-05',
  }),
);
```

---

### 4. Submit Period Data

```dart
final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/catatan-haid'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'start_date': '2026-02-01',
    'end_date': '2026-02-05',
  }),
);
```

**Response:**
```json
{
  "message": "Data haid berhasil ditambahkan",
  "data": {
    "id": 1,
    "user_id": 1,
    "start_date": "2026-02-01",
    "end_date": "2026-02-05"
  }
}
```

---

### 5. Get Period History

```dart
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/catatan-haid?history=true&months=6'),
  headers: AuthService.getAuthHeaders(),
);

final periods = jsonDecode(response.body)['data'];
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "start_date": "2026-02-01",
      "end_date": "2026-02-05",
      "cycle_length": 28,
      "created_at": "2026-02-01T00:00:00.000000Z"
    }
  ]
}
```

---

### 6. Get Period Stats

```dart
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/catatan-haid/stats?months=6'),
  headers: AuthService.getAuthHeaders(),
);

final stats = jsonDecode(response.body)['data'];
```

**Response:**
```json
{
  "data": {
    "periods": [...],
    "prediction": {
      "days_remaining": 14,
      "predicted_date": "2026-03-01"
    },
    "chart_data": {
      "bleeding_history": [5, 6, 5, 7]
    }
  }
}
```

---

## 🔄 Auto-Upgrade Feature

Health app supports **auto-upgrade** for users who register as General version but try to access period tracking:

```dart
// Submit period data with auto-upgrade
final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/catatan-haid'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'start_date': '2026-02-01',
    'end_date': '2026-02-05',
    'auto_upgrade': true, // ← Auto-upgrade if user is general version
  }),
);
```

**Response (if user was upgraded):**
```json
{
  "message": "Data haid berhasil ditambahkan",
  "data": {...},
  "upgraded": true
}
```

---

## ⚠️ Error Responses

### 403 Forbidden (Without Auto-Upgrade)

```json
{
  "message": "Period tracking is only available for health version users",
  "errors": {
    "app_version": ["Feature not available for your app version"]
  },
  "upgrade_available": true,
  "upgrade_endpoint": "POST /api/wellness/upgrade-to-health"
}
```

**Solution:**
1. Add `auto_upgrade: true` to request
2. Or call `/api/wellness/upgrade-to-health` first

---

## 📊 Endpoint Comparison

| Endpoint | General Version | Health Version |
|----------|-----------------|----------------|
| `/api/register` | ✅ | ✅ |
| `/api/wellness/questions` | ✅ | ✅ |
| `/api/onboarding/submit` | ✅ | ✅ |
| `/api/wellness/profile` | ✅ | ✅ |
| `/api/catatan-haid` | ❌ (403) | ✅ |
| `/api/catatan-haid/stats` | ❌ (403) | ✅ |
| `/api/wellness/upgrade-to-health` | ✅ | ✅ (already upgraded) |

---

## 🐛 Troubleshooting

### Issue: 403 on Period Tracking

**Cause:** User has `app_version: 'general'`

**Solutions:**
1. Re-register with `app_version: 'health'`
2. Use auto-upgrade: `auto_upgrade: true`
3. Manual upgrade: `POST /api/wellness/upgrade-to-health`

### Issue: Questions Not Found

**Cause:** Seeders not run

**Solution:**
```bash
php artisan db:seed HealthQuestionSeeder
php artisan optimize:clear
```

### Issue: Token Expired

**Cause:** JWT token expired

**Solution:**
```dart
// Re-login
await AuthService().login(email: email, password: password);
```

---

## ✅ Quick Reference

### Health App Endpoints

```dart
// Use ALL endpoints
✅ /api/register
✅ /api/login
✅ /api/wellness/questions
✅ /api/onboarding/submit
✅ /api/wellness/profile
✅ /api/catatan-haid
✅ /api/catatan-haid/stats
```

### Headers

```dart
// For authenticated requests
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

### Base URL

```dart
// Development
static const String _developmentUrl = 'http://192.168.1.4:8000/api';

// Production
static const String _productionUrl = 'https://empuanapp.id/api';
```

---

**Last Updated:** March 8, 2026  
**Status:** ✅ Complete
