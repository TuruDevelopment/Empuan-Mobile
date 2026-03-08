# Frontend Integration Guide - Backend Updates

## 📋 Overview

The backend now supports **two app versions** with **automatic upgrade** capability:

- **General Version** (`app_version: "general"`) - Wellness & lifestyle features
- **Health Version** (`app_version: "health"`) - Period tracking + wellness features

**Key Feature:** Wellness users can be **automatically upgraded** to health version when they try to access period tracking.

---

## 🚀 Quick Start

### For Health App (Period Tracker)

```dart
// Registration - Add app_version
POST /api/register
{
  "name": "Jane Doe",
  "username": "janedoe",
  "email": "jane@example.com",
  "password": "password123",
  "gender": "female",
  "dob": "1995-05-15",
  "app_version": "health"  // ← Add this
}

// Period Tracking - Add auto_upgrade flag
POST /api/catatan-haid
{
  "auto_upgrade": true,  // ← Auto-upgrade if needed
  "start_date": "2026-02-01",
  "end_date": "2026-02-05"
}
```

### For Wellness App (General Version)

```dart
// Registration
POST /api/register
{
  "name": "Jane Doe",
  "username": "janedoe",
  "email": "jane@example.com",
  "password": "password123",
  "gender": "female",
  "dob": "1995-05-15",
  "app_version": "general"  // ← Use general
}

// Onboarding
POST /api/onboarding/submit
{
  "answers": [
    {"question_id": 1, "option_id": 2, "answer_type": "wellness"}
  ],
  "activity_level": "Moderately active",
  "sleep_quality": "No, I sleep well",
  "wellness_concerns": ["Stress management"]
}
```

---

## 📝 Table of Contents

1. [Registration Flow](#registration-flow)
2. [Onboarding Flow](#onboarding-flow)
3. [Auto-Upgrade Feature](#auto-upgrade-feature)
4. [Period Tracking API](#period-tracking-api)
5. [Wellness API](#wellness-api)
6. [Error Handling](#error-handling)
7. [Complete Examples](#complete-examples)

---

## Registration Flow

### Endpoint: `POST /api/register`

**Required Fields:**
```json
{
  "name": "string (required)",
  "username": "string (required, unique)",
  "email": "string (required, unique)",
  "password": "string (required, min 6 chars)",
  "gender": "string (required)",
  "dob": "string (required, YYYY-MM-DD)",
  "app_version": "string (optional, default: 'general')"
}
```

**Optional Wellness Fields:**
```json
{
  "activity_level": "Very active|Moderately active|Sedentary|I don't know",
  "sleep_quality": "string",
  "wellness_concerns": ["array of strings"]
}
```

**Success Response (200):**
```json
{
  "user": {
    "id": 1,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "app_version": "health",
    "onboarding_completed": false
  },
  "token": "1|abc123xyz..."
}
```

**Example (Flutter/Dart):**
```dart
Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
  required String gender,
  required DateTime dob,
  String appVersion = 'health',  // Default to health
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'username': name.replaceAll(' ', '').toLowerCase(),
      'email': email,
      'password': password,
      'gender': gender,
      'dob': dob.toIso8601String().split('T')[0],
      'app_version': appVersion,
    }),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Registration failed: ${response.body}');
  }
}
```

---

## Onboarding Flow

### Step 1: Get Questions

**Endpoint:** `GET /api/wellness/questions`

**Query Parameters:**
- `type` (optional): `"wellness"` or `"health"` (default: `"wellness"`)
- `limit` (optional): Number of questions (default: 10, max: 50)

**Request:**
```
GET /api/wellness/questions?type=wellness&limit=4
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "question": "How would you describe your daily activity level?",
      "options": [
        {"id": 1, "text": "Very active"},
        {"id": 2, "text": "Moderately active"},
        {"id": 3, "text": "Sedentary"},
        {"id": 4, "text": "I don't know"}
      ]
    }
  ],
  "meta": {
    "type": "wellness",
    "total": 3
  }
}
```

### Step 2: Submit Answers

**Endpoint:** `POST /api/onboarding/submit`

**Request:**
```json
{
  "answers": [
    {
      "question_id": 1,
      "option_id": 2,
      "answer_text": null,
      "answer_type": "wellness"
    },
    {
      "question_id": 2,
      "option_id": 5,
      "answer_text": null,
      "answer_type": "wellness"
    }
  ],
  "activity_level": "Moderately active",
  "sleep_quality": "No, I sleep well",
  "wellness_concerns": ["Stress management", "Energy levels"]
}
```

**Success Response (200):**
```json
{
  "message": "Onboarding completed successfully",
  "user": {
    "id": 1,
    "activity_level": "Moderately active",
    "sleep_quality": "No, I sleep well",
    "wellness_concerns": ["Stress management", "Energy levels"],
    "onboarding_completed": true
  }
}
```

**Example (Flutter/Dart):**
```dart
Future<void> submitOnboarding({
  required String token,
  required List<Map<String, dynamic>> answers,
  String? activityLevel,
  String? sleepQuality,
  List<String>? wellnessConcerns,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/onboarding/submit'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'answers': answers,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (wellnessConcerns != null) 'wellness_concerns': wellnessConcerns,
    }),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Onboarding failed: ${response.body}');
  }
}
```

---

## Auto-Upgrade Feature

### What is Auto-Upgrade?

When a user registered as `"general"` version tries to access period tracking features, they can be **automatically upgraded** to `"health"` version.

### Two Ways to Use Auto-Upgrade

#### Method 1: Automatic (Recommended)

Add `auto_upgrade: true` to any period tracking request:

```dart
Future<void> submitPeriodData({
  required DateTime startDate,
  DateTime? endDate,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/catatan-haid'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'auto_upgrade': true,  // ← Auto-upgrade if needed
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
    }),
  );
  
  if (response.statusCode == 201) {
    // Success! User was auto-upgraded if needed
    print('Period data saved');
  } else if (response.statusCode == 403) {
    // Should not happen with auto_upgrade: true
    print('Error: ${response.body}');
  }
}
```

**Benefits:**
- ✅ No extra API calls
- ✅ Seamless user experience
- ✅ Simple implementation

#### Method 2: Manual Upgrade

Explicitly upgrade user before accessing features:

```dart
Future<void> upgradeToHealth() async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/wellness/upgrade-to-health'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    if (data['already_upgraded']) {
      print('User already has health version');
    } else {
      print('Successfully upgraded to health version');
    }
  }
}
```

**With User Confirmation Dialog:**
```dart
Future<void> checkAndUpgrade() async {
  // Check current version
  final profile = await getProfile();
  final appVersion = profile['data']['user']['app_version'];
  
  if (appVersion == 'general') {
    // Show upgrade dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock Period Tracking'),
        content: Text(
          'Upgrade to health version to access period tracking. '
          'This is free and instant!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Upgrade Now'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await upgradeToHealth();
    }
  }
}
```

---

## Period Tracking API

### Submit Period Data

**Endpoint:** `POST /api/catatan-haid`

**Request:**
```json
{
  "auto_upgrade": true,  // Recommended
  "start_date": "2026-02-01",
  "end_date": "2026-02-05"
}
```

**Success Response (201):**
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

**Error Response (403) - Without Auto-Upgrade:**
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

### Get Period List

**Endpoint:** `GET /api/catatan-haid`

**Query Parameters:**
- `history` (optional): `true` to get all records
- `months` (optional): Number of months (default: 5)

**Request:**
```
GET /api/catatan-haid?history=true&months=6
Authorization: Bearer {token}
```

### Get Period Stats

**Endpoint:** `GET /api/catatan-haid/stats`

**Query Parameters:**
- `months` (optional): Number of months for stats (default: 6)

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

## Wellness API

### Get User Profile

**Endpoint:** `GET /api/wellness/profile`

**Response:**
```json
{
  "data": {
    "user": {
      "id": 1,
      "name": "Jane Doe",
      "activity_level": "Moderately active",
      "sleep_quality": "No, I sleep well",
      "wellness_concerns": ["Stress management"],
      "app_version": "health",
      "onboarding_completed": true
    },
    "answers": [...]
  }
}
```

### Update Profile

**Endpoint:** `PUT /api/wellness/profile`

**Request:**
```json
{
  "activity_level": "Very active",
  "sleep_quality": "Waking up tired",
  "wellness_concerns": ["Energy levels", "Physical fitness"],
  "app_version": "health"  // Can also upgrade this way
}
```

---

## Error Handling

### 403 Forbidden - Upgrade Required

```dart
Future<dynamic> handleApiError(dynamic error) {
  if (error is HttpException) {
    final statusCode = (error as HttpException).statusCode;
    
    if (statusCode == 403) {
      final body = jsonDecode(error.message);
      
      if (body['upgrade_available'] == true) {
        // Show upgrade prompt
        return UpgradeRequiredError(
          message: body['message'],
          upgradeEndpoint: body['upgrade_endpoint'],
        );
      }
    }
  }
  return error;
}
```

### Network Error

```dart
try {
  await submitPeriodData(startDate, endDate);
} on SocketException {
  // No internet connection
  showError('No internet connection');
} on TimeoutException {
  // Request timed out
  showError('Request timed out');
} catch (e) {
  // Other errors
  showError('Something went wrong: $e');
}
```

---

## Complete Examples

### Health App - Full Registration & Onboarding

```dart
class HealthAppService {
  final String baseUrl = 'http://your-api-url.com/api';
  String? token;
  
  // Complete registration flow
  Future<void> registerAndOnboard({
    required String name,
    required String email,
    required String password,
    required String gender,
    required DateTime dob,
  }) async {
    // Step 1: Register
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': name.replaceAll(' ', '').toLowerCase(),
        'email': email,
        'password': password,
        'gender': gender,
        'dob': dob.toIso8601String().split('T')[0],
        'app_version': 'health',  // Health app
      }),
    );
    
    if (registerResponse.statusCode != 200) {
      throw Exception('Registration failed');
    }
    
    token = jsonDecode(registerResponse.body)['token'];
    
    // Step 2: Get questions
    final questionsResponse = await http.get(
      Uri.parse('$baseUrl/wellness/questions?type=health&limit=4'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    final questions = jsonDecode(questionsResponse.body)['data'];
    
    // Step 3: Show questions to user (your UI code)
    final answers = await showHealthQuestions(questions);
    
    // Step 4: Submit onboarding
    await http.post(
      Uri.parse('$baseUrl/onboarding/submit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'answers': answers,
        'cycle_regularity': answers[0]['option_id'] == 1 ? 'regular' : 'irregular',
      }),
    );
  }
  
  // Submit period data with auto-upgrade
  Future<void> submitPeriod({
    required DateTime start,
    DateTime? end,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/catatan-haid'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'auto_upgrade': true,  // Auto-upgrade if needed
        'start_date': start.toIso8601String().split('T')[0],
        'end_date': end?.toIso8601String().split('T')[0],
      }),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to submit period data');
    }
  }
}
```

### Wellness App - Full Registration & Onboarding

```dart
class WellnessAppService {
  final String baseUrl = 'http://your-api-url.com/api';
  String? token;
  
  Future<void> registerAndOnboard({
    required String name,
    required String email,
    required String password,
    required String gender,
    required DateTime dob,
  }) async {
    // Step 1: Register with general version
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': name.replaceAll(' ', '').toLowerCase(),
        'email': email,
        'password': password,
        'gender': gender,
        'dob': dob.toIso8601String().split('T')[0],
        'app_version': 'general',  // Wellness app
      }),
    );
    
    token = jsonDecode(registerResponse.body)['token'];
    
    // Step 2: Get wellness questions
    final questionsResponse = await http.get(
      Uri.parse('$baseUrl/wellness/questions?type=wellness&limit=4'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    final questions = jsonDecode(questionsResponse.body)['data'];
    
    // Step 3: Show questions and collect answers
    final answers = await showWellnessQuestions(questions);
    
    // Step 4: Submit onboarding
    await http.post(
      Uri.parse('$baseUrl/onboarding/submit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'answers': answers,
        'activity_level': getSelectedActivityLevel(),
        'sleep_quality': getSelectedSleepQuality(),
        'wellness_concerns': getSelectedConcerns(),
      }),
    );
  }
}
```

---

## API Endpoints Reference

### Authentication
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/register` | ❌ | Register new user |
| POST | `/api/login` | ❌ | Login user |
| GET | `/api/me` | ✅ | Get current user |
| POST | `/api/logout` | ✅ | Logout user |

### Onboarding & Wellness
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/onboarding/submit` | ✅ | Submit onboarding answers |
| GET | `/api/wellness/questions` | ✅ | Get questions |
| POST | `/api/wellness/answers` | ✅ | Submit answers |
| GET | `/api/wellness/profile` | ✅ | Get profile |
| PUT | `/api/wellness/profile` | ✅ | Update profile |
| POST | `/api/wellness/upgrade-to-health` | ✅ | Upgrade to health |
| GET | `/api/wellness/stats` | ✅ | Get statistics |

### Period Tracking (Health Only)
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/catatan-haid` | ✅ | Submit period data |
| GET | `/api/catatan-haid` | ✅ | Get period list |
| GET | `/api/catatan-haid/stats` | ✅ | Get statistics |

---

## Testing Checklist

- [ ] Register user with `app_version: "health"`
- [ ] Register user with `app_version: "general"`
- [ ] Submit onboarding answers
- [ ] Get wellness profile
- [ ] Submit period data with `auto_upgrade: true`
- [ ] Verify general user gets upgraded to health
- [ ] Get period stats
- [ ] Test error handling (403 responses)

---

## Need Help?

**Check Backend Logs:**
```bash
tail -f storage/logs/laravel.log
```

**Clear Cache:**
```bash
php artisan optimize:clear
```

**Test Endpoints:**
```bash
php artisan route:list --path=api
```

---

## Document Revision

- **Version:** 1.0
- **Last Updated:** March 8, 2026
- **Backend Version:** Laravel 10.49.1

**Related Documents:**
- `AUTO_UPGRADE_SUMMARY.md` - Quick reference
- `AUTO_UPGRADE_IMPLEMENTATION.md` - Detailed implementation
- `REGISTRATION_API_GUIDE.md` - Complete API reference
- `COMPATIBILITY_GUIDE.md` - Backward compatibility
