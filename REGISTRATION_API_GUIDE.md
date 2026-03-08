# Registration & Onboarding API Documentation

## Overview

The backend now supports **two app versions**:
- **General Version** (`app_version: "general"`) - Wellness & lifestyle focused
- **Health Version** (`app_version: "health"`) - Period tracking + wellness

---

## 📋 Registration Flow

### Step 1: Register User

**Endpoint:** `POST /api/register`

**Request:**
```json
{
  "name": "Jane Doe",
  "username": "janedoe",
  "email": "jane@example.com",
  "password": "password123",
  "gender": "female",
  "dob": "1995-05-15",
  "app_version": "general"
}
```

**Required Fields:**
| Field | Type | Description |
|-------|------|-------------|
| name | string | User's full name |
| username | string | Unique username |
| email | string | Unique email address |
| password | string | Minimum 6 characters |
| gender | string | User's gender |
| dob | string | Date of birth (YYYY-MM-DD) |
| app_version | string | `"general"` or `"health"` |

**Optional Fields (can be sent during registration or later):**
| Field | Type | Description |
|-------|------|-------------|
| activity_level | string | `"Very active"`, `"Moderately active"`, `"Sedentary"`, `"I don't know"` |
| sleep_quality | string | Sleep quality description |
| wellness_concerns | array | List of concerns: `["Stress management", "Energy levels"]` |

**Success Response (200):**
```json
{
  "user": {
    "id": 1,
    "name": "Jane Doe",
    "username": "janedoe",
    "email": "jane@example.com",
    "gender": "female",
    "dob": "1995-05-15",
    "app_version": "general",
    "activity_level": null,
    "sleep_quality": null,
    "wellness_concerns": null,
    "onboarding_completed": false,
    "created_at": "2026-03-08T06:00:00.000000Z",
    "updated_at": "2026-03-08T06:00:00.000000Z"
  },
  "token": "1|abc123xyz..."
}
```

---

### Step 2: Get Onboarding Questions

**Endpoint:** `GET /api/wellness/questions`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| type | string | `"wellness"` | `"wellness"` or `"health"` |
| limit | number | `10` | Max 50 |

**Request Example:**
```
GET /api/wellness/questions?type=wellness&limit=4
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "question": "How would you describe your daily activity level?",
      "options": [
        { "id": 1, "text": "Very active" },
        { "id": 2, "text": "Moderately active" },
        { "id": 3, "text": "Sedentary" },
        { "id": 4, "text": "I don't know" }
      ]
    },
    {
      "id": 2,
      "question": "What sleep improvements are you looking for?",
      "options": [
        { "id": 5, "text": "No, I sleep well" },
        { "id": 6, "text": "Difficulty falling asleep" },
        { "id": 7, "text": "Waking up tired" },
        { "id": 8, "text": "Frequent night awakenings" },
        { "id": 9, "text": "Irregular sleep schedule" }
      ]
    },
    {
      "id": 4,
      "question": "What are your main wellness concerns?",
      "options": [
        { "id": 10, "text": "Stress management" },
        { "id": 11, "text": "Energy levels" },
        { "id": 12, "text": "Mood balance" },
        { "id": 13, "text": "Physical fitness" },
        { "id": 14, "text": "Nutrition" },
        { "id": 15, "text": "Work-life balance" }
      ]
    }
  ],
  "meta": {
    "type": "wellness",
    "total": 3
  }
}
```

---

### Step 3: Submit Onboarding Answers

**Endpoint:** `POST /api/onboarding/submit`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body (General Version):**
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
    },
    {
      "question_id": 4,
      "option_id": 10,
      "answer_text": null,
      "answer_type": "wellness"
    }
  ],
  "activity_level": "Moderately active",
  "sleep_quality": "No, I sleep well",
  "wellness_concerns": ["Stress management", "Energy levels"]
}
```

**Request Body (Health Version):**
```json
{
  "answers": [
    {
      "question_id": 10,
      "option_id": 20,
      "answer_text": null,
      "answer_type": "health"
    },
    {
      "question_id": 11,
      "answer_text": "2026-02-01",
      "answer_type": "health"
    },
    {
      "question_id": 12,
      "option_id": 25,
      "answer_text": null,
      "answer_type": "health"
    }
  ],
  "cycle_regularity": "regular",
  "last_period_start": "2026-02-01",
  "last_period_end": "2026-02-05"
}
```

**Answer Object Structure:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| question_id | number | No | ID from questions API |
| option_id | number | No | ID from options (if multiple choice) |
| answer_text | string | No | Free text answer (for date inputs, etc.) |
| answer_type | string | No | `"wellness"` or `"health"` |

**Success Response (200):**
```json
{
  "message": "Onboarding completed successfully",
  "user": {
    "id": 1,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "activity_level": "Moderately active",
    "sleep_quality": "No, I sleep well",
    "wellness_concerns": ["Stress management", "Energy levels"],
    "app_version": "general",
    "onboarding_completed": true
  }
}
```

---

## 🔄 Alternative: Submit Answers Separately

If you want to submit answers separately from profile updates:

**Endpoint:** `POST /api/wellness/answers`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "answers": [
    {
      "question_id": 1,
      "option_id": 2,
      "answer_text": null,
      "answer_type": "wellness"
    }
  ]
}
```

**Update Profile:** `PUT /api/wellness/profile`
```json
{
  "activity_level": "Moderately active",
  "sleep_quality": "No, I sleep well",
  "wellness_concerns": ["Stress management"]
}
```

---

## 📱 Complete Frontend Flow Example

### General Version Flow

```dart
// Step 1: Register
final registerResponse = await http.post(
  Uri.parse('$baseUrl/api/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'name': 'Jane Doe',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'password': 'password123',
    'gender': 'female',
    'dob': '1995-05-15',
    'app_version': 'general', // IMPORTANT!
  }),
);

final token = registerResponse.json()['token'];

// Step 2: Get questions
final questionsResponse = await http.get(
  Uri.parse('$baseUrl/api/wellness/questions?type=wellness&limit=4'),
  headers: {'Authorization': 'Bearer $token'},
);

final questions = questionsResponse.json()['data'];

// Step 3: Show questions to user, collect answers
// User selects: activity_level, sleep_quality, wellness_concerns

// Step 4: Submit onboarding
final onboardingResponse = await http.post(
  Uri.parse('$baseUrl/api/onboarding/submit'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'answers': [
      {'question_id': 1, 'option_id': 2, 'answer_type': 'wellness'},
      {'question_id': 2, 'option_id': 5, 'answer_type': 'wellness'},
      {'question_id': 4, 'option_id': 10, 'answer_type': 'wellness'},
    ],
    'activity_level': 'Moderately active',
    'sleep_quality': 'No, I sleep well',
    'wellness_concerns': ['Stress management', 'Energy levels'],
  }),
);

// Done! User is onboarded
```

### Health Version Flow

```dart
// Step 1: Register
final registerResponse = await http.post(
  Uri.parse('$baseUrl/api/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'name': 'Jane Doe',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'password': 'password123',
    'gender': 'female',
    'dob': '1995-05-15',
    'app_version': 'health', // IMPORTANT!
  }),
);

final token = registerResponse.json()['token'];

// Step 2: Get health questions
final questionsResponse = await http.get(
  Uri.parse('$baseUrl/api/wellness/questions?type=health&limit=4'),
  headers: {'Authorization': 'Bearer $token'},
);

// Step 3: Show health questions (cycle regularity, period dates, discomfort)

// Step 4: Submit onboarding with period data
final onboardingResponse = await http.post(
  Uri.parse('$baseUrl/api/onboarding/submit'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'answers': [
      {'question_id': 10, 'option_id': 20, 'answer_type': 'health'},
      {'question_id': 11, 'answer_text': '2026-02-01', 'answer_type': 'health'},
      {'question_id': 12, 'option_id': 25, 'answer_type': 'health'},
    ],
    'cycle_regularity': 'regular',
    'last_period_start': '2026-02-01',
    'last_period_end': '2026-02-05',
  }),
);

// Step 5 (Health only): Submit period data to catatan-haid
final periodResponse = await http.post(
  Uri.parse('$baseUrl/api/catatan-haid'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'start_date': '2026-02-01',
    'end_date': '2026-02-05',
  }),
);

// Done! User is onboarded with period data
```

---

## 🔍 Get User Profile

**Endpoint:** `GET /api/wellness/profile`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": {
    "user": {
      "id": 1,
      "name": "Jane Doe",
      "activity_level": "Moderately active",
      "sleep_quality": "No, I sleep well",
      "wellness_concerns": ["Stress management", "Energy levels"],
      "app_version": "general",
      "onboarding_completed": true
    },
    "answers": [
      {
        "id": 1,
        "question": "How would you describe your daily activity level?",
        "option": "Moderately active",
        "answer_text": null,
        "answer_type": "wellness",
        "created_at": "2026-03-08 06:00:00"
      }
    ]
  }
}
```

---

## ⚠️ Important Notes

### 1. App Version Determines Feature Access

| Feature | General Version | Health Version |
|---------|----------------|----------------|
| Wellness endpoints | ✅ | ✅ |
| Period tracking API | ❌ (403 error) | ✅ |
| Wellness questions | ✅ | ✅ |
| Health questions | ✅ | ✅ |

### 2. Period Tracking is Restricted

**Endpoint:** `POST /api/catatan-haid`

Only works for `app_version: "health"` users.

**General version users will get:**
```json
{
  "message": "Period tracking is only available for health version users",
  "errors": {
    "app_version": ["Feature not available for your app version"]
  }
}
```
**Status:** 403 Forbidden

### 3. Question Types

Questions in database are categorized:
- `question_type: "wellness"` - Activity, sleep, wellness concerns
- `question_type: "health"` - Cycle, period dates, discomfort
- `question_type: "general"` - General questions

### 4. Answer Storage

Answers are stored in `user_answers` table with:
- `user_id` - Link to user
- `question_id` - Link to question
- `option_id` - Link to selected option (nullable)
- `answer_text` - Free text answer (nullable)
- `answer_type` - "wellness" or "health"

### 5. Profile Storage

Wellness profile is stored directly in `users` table:
- `activity_level` - String
- `sleep_quality` - String
- `wellness_concerns` - JSON array
- `app_version` - "general" or "health"
- `onboarding_completed` - Boolean

---

## 🐛 Common Issues & Solutions

### Issue: "Route [login] not defined"

**Cause:** Middleware redirect configuration issue.

**Solution:** The backend has been fixed. Admin panel is now at `/admin`.

### Issue: 500 Error on API Call

**Possible Causes:**
1. Database not migrated
2. Missing authentication token
3. Invalid request format

**Solution:**
```bash
# Run migrations
php artisan migrate

# Clear cache
php artisan optimize:clear
```

### Issue: Data Not Saved

**Check:**
1. ✅ Token is included in headers: `Authorization: Bearer {token}`
2. ✅ Content-Type is `application/json`
3. ✅ Request body is valid JSON
4. ✅ All required fields are present
5. ✅ `app_version` is set correctly

---

## 📊 API Endpoints Summary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/register` | ❌ | Register new user |
| POST | `/api/login` | ❌ | Login user |
| GET | `/api/wellness/questions` | ✅ | Get onboarding questions |
| POST | `/api/onboarding/submit` | ✅ | Submit onboarding answers |
| POST | `/api/wellness/answers` | ✅ | Submit answers separately |
| GET | `/api/wellness/profile` | ✅ | Get user wellness profile |
| PUT | `/api/wellness/profile` | ✅ | Update wellness profile |
| GET | `/api/wellness/stats` | ✅ | Get wellness statistics |
| POST | `/api/catatan-haid` | ✅ | Submit period data (health only) |
| GET | `/api/catatan-haid` | ✅ | Get period data (health only) |

---

## 🧪 Testing with cURL

### Test Registration
```bash
curl -X POST http://localhost:8000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "gender": "female",
    "dob": "1995-05-15",
    "app_version": "general"
  }'
```

### Test Get Questions
```bash
curl -X GET "http://localhost:8000/api/wellness/questions?type=wellness" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Submit Onboarding
```bash
curl -X POST http://localhost:8000/api/onboarding/submit \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "answers": [
      {"question_id": 1, "option_id": 2, "answer_type": "wellness"}
    ],
    "activity_level": "Moderately active",
    "sleep_quality": "No, I sleep well",
    "wellness_concerns": ["Stress management"]
  }'
```

---

## 📞 Need Help?

Check backend logs:
```bash
tail -f storage/logs/laravel.log
```

Clear cache:
```bash
php artisan optimize:clear
```

Check routes:
```bash
php artisan route:list --path=api
```
