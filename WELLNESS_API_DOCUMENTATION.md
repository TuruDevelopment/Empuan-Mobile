# Backend API Support for General Wellness & Health App Versions

This document describes the backend modifications made to support both the **General Wellness** app version and the **Health (Period Tracker)** app version.

---

## Overview

The backend now supports two app versions:
1. **General Version** - Focuses on wellness, lifestyle, and general health monitoring
2. **Health Version** - Includes period tracking features along with wellness features

Both versions share the same codebase but use different onboarding flows and feature availability based on the `app_version` field in the user profile.

---

## Database Changes

### New Tables

#### `user_answers`
Stores user responses to onboarding questions (wellness or health).

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | FK to users.id |
| question_id | bigint | FK to questions.id (nullable) |
| option_id | bigint | FK to options.id (nullable) |
| answer_text | text | Free-text answer (nullable) |
| answer_type | string | 'wellness' or 'health' |
| timestamps | - | created_at, updated_at |

### Modified Tables

#### `users`
New columns added:

| Column | Type | Default | Description |
|--------|------|---------|-------------|
| activity_level | string(50) | NULL | User's activity level (Very active, Moderately active, Sedentary) |
| sleep_quality | string(100) | NULL | User's sleep quality description |
| wellness_concerns | json | NULL | Array of wellness concerns |
| app_version | string(50) | 'general' | 'general' or 'health' |
| onboarding_completed | boolean | false | Whether user completed onboarding |

#### `questions`
New columns added:

| Column | Type | Default | Description |
|--------|------|---------|-------------|
| question_type | string(50) | 'general' | 'wellness', 'health', or 'general' |
| category | string(100) | NULL | Category like 'activity', 'sleep', 'cycle', 'discomfort' |

---

## New API Endpoints

### Authentication & Onboarding

#### POST `/api/register`
Register a new user (updated to support wellness fields).

**Request Body:**
```json
{
  "name": "John Doe",
  "username": "johndoe",
  "email": "john@example.com",
  "password": "password123",
  "gender": "female",
  "dob": "1990-01-01",
  "activity_level": "Moderately active",
  "sleep_quality": "No, I sleep well",
  "wellness_concerns": ["Stress management", "Energy levels"],
  "app_version": "general"
}
```

**Response:**
```json
{
  "user": { ... },
  "token": "..."
}
```

#### POST `/api/onboarding/submit`
Submit onboarding answers after registration.

**Request Body:**
```json
{
  "answers": [
    {
      "question_id": 1,
      "option_id": 3,
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
  "activity_level": "Very active",
  "sleep_quality": "Difficulty falling asleep",
  "wellness_concerns": ["Stress management", "Mood balance"]
}
```

**Response:**
```json
{
  "message": "Onboarding completed successfully",
  "user": { ... }
}
```

---

### Wellness Endpoints

#### GET `/api/wellness/questions`
Get wellness/health questions for onboarding.

**Query Parameters:**
- `type` (optional): 'wellness' or 'health' (default: 'wellness')
- `limit` (optional): Number of questions (default: 10, max: 50)

**Response:**
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
    }
  ],
  "meta": {
    "type": "wellness",
    "total": 4
  }
}
```

#### POST `/api/wellness/answers`
Submit wellness/health answers.

**Request Body:**
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

**Response:**
```json
{
  "message": "Answers saved successfully",
  "data": [ ... ]
}
```

#### GET `/api/wellness/profile`
Get user's wellness profile.

**Response:**
```json
{
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "activity_level": "Moderately active",
      "sleep_quality": "No, I sleep well",
      "wellness_concerns": ["Stress management"],
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

#### PUT/PATCH `/api/wellness/profile`
Update user wellness profile.

**Request Body:**
```json
{
  "activity_level": "Very active",
  "sleep_quality": "Waking up tired",
  "wellness_concerns": ["Energy levels", "Physical fitness"],
  "app_version": "general"
}
```

**Response:**
```json
{
  "message": "Profile updated successfully",
  "data": {
    "activity_level": "Very active",
    "sleep_quality": "Waking up tired",
    "wellness_concerns": ["Energy levels", "Physical fitness"],
    "app_version": "general"
  }
}
```

#### GET `/api/wellness/stats`
Get wellness statistics.

**Response:**
```json
{
  "data": {
    "total_answers": 4,
    "wellness_answers": 4,
    "health_answers": 0,
    "profile": {
      "activity_level": "Moderately active",
      "sleep_quality": "No, I sleep well",
      "wellness_concerns": ["Stress management"],
      "app_version": "general"
    }
  }
}
```

#### DELETE `/api/wellness/answers`
Delete user's answers.

**Query Parameters:**
- `answer_id` (optional): Specific answer ID to delete (if not provided, deletes all)

**Response:**
```json
{
  "message": "Answers deleted successfully",
  "deleted_count": 4
}
```

---

## Modified Endpoints

### Questions API

#### GET `/api/questions`
Now supports filtering by question type and category.

**Query Parameters:**
- `type`: Filter by 'wellness', 'health', or 'general'
- `category`: Filter by category (e.g., 'activity', 'sleep', 'cycle')
- `per_page`: Pagination (default: 20, max: 100)

**Example:**
```
GET /api/questions?type=wellness&category=activity
```

---

### Period Tracking (Catatan Haid) API

All period tracking endpoints now check the user's `app_version`. Users with `app_version: 'general'` will receive a 403 error when trying to access period tracking features.

#### POST `/api/catatan-haid`
**Updated:** Returns 403 for general app version users.

#### GET `/api/catatan-haid`
**Updated:** Returns 403 for general app version users.

#### GET `/api/catatan-haid/stats`
**Updated:** Returns 403 for general app version users.

---

## Seeders

New seeders added for questions:

### WellnessQuestionSeeder
Seeds wellness/lifestyle questions:
- Activity level question
- Sleep quality question
- Wellness concerns question

### HealthQuestionSeeder
Seeds health/period tracker questions:
- Cycle regularity question
- Last period question
- Menstrual discomfort question

**Run seeders:**
```bash
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder
```

Or run both via DatabaseSeeder:
```bash
php artisan db:seed
```

---

## App Version Behavior

### General Version (`app_version: 'general'`)
- ✅ Can access wellness endpoints
- ✅ Can answer wellness questions
- ✅ Can update wellness profile
- ❌ Cannot access period tracking endpoints (returns 403)

### Health Version (`app_version: 'health'`)
- ✅ Can access wellness endpoints
- ✅ Can answer wellness questions
- ✅ Can update wellness profile
- ✅ Can access period tracking endpoints
- ✅ Can answer health questions

---

## Migration Commands

Run all new migrations:
```bash
php artisan migrate
```

Rollback specific migrations:
```bash
php artisan migrate:rollback --step=1
```

---

## Example Frontend Integration

### General App Registration Flow

```dart
// 1. Register user
final response = await http.post(
  '/api/register',
  body: {
    'name': 'Jane Doe',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'password': 'password123',
    'gender': 'female',
    'dob': '1995-05-15',
    'app_version': 'general',
  },
);

// 2. Submit onboarding answers
await http.post(
  '/api/onboarding/submit',
  headers: {'Authorization': 'Bearer $token'},
  body: {
    'answers': [
      {'question_id': 1, 'option_id': 2, 'answer_type': 'wellness'},
      {'question_id': 2, 'option_id': 5, 'answer_type': 'wellness'},
      {'question_id': 4, 'option_id': 8, 'answer_type': 'wellness'},
    ],
    'activity_level': 'Moderately active',
    'sleep_quality': 'No, I sleep well',
    'wellness_concerns': ['Stress management', 'Energy levels'],
  },
);
```

### Health App Registration Flow

```dart
// 1. Register user
final response = await http.post(
  '/api/register',
  body: {
    'name': 'Jane Doe',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'password': 'password123',
    'gender': 'female',
    'dob': '1995-05-15',
    'app_version': 'health',
  },
);

// 2. Submit health onboarding answers
await http.post(
  '/api/onboarding/submit',
  headers: {'Authorization': 'Bearer $token'},
  body: {
    'answers': [
      {'question_id': 10, 'option_id': 20, 'answer_type': 'health'},
      {'question_id': 11, 'answer_text': '2026-02-01', 'answer_type': 'health'},
      {'question_id': 12, 'option_id': 25, 'answer_type': 'health'},
    ],
    'cycle_regularity': 'regular',
    'last_period_start': '2026-02-01',
    'last_period_end': '2026-02-05',
  },
);

// 3. Submit period data (health version only)
await http.post(
  '/api/catatan-haid',
  headers: {'Authorization': 'Bearer $token'},
  body: {
    'start_date': '2026-02-01',
    'end_date': '2026-02-05',
  },
);
```

---

## Summary of Changes

| File | Changes |
|------|---------|
| `app/Models/User.php` | Added wellness fields, casts, and userAnswers relationship |
| `app/Models/UserAnswer.php` | **NEW** - Model for storing user answers |
| `app/Models/Question.php` | Added question_type and category fields |
| `app/Http/Controllers/AuthController.php` | Updated register(), added submitOnboarding() |
| `app/Http/Controllers/WellnessController.php` | **NEW** - Controller for wellness endpoints |
| `app/Http/Controllers/QuestionController.php` | Added type/category filtering |
| `app/Http/Controllers/CatatanHaidController.php` | Added app_version checks |
| `routes/api.php` | Added wellness routes |
| `database/migrations/*` | 3 new migrations |
| `database/seeders/*` | 2 new seeders |

---

## Testing

1. Run migrations: `php artisan migrate`
2. Run seeders: `php artisan db:seed`
3. Test registration with wellness fields
4. Test onboarding submission
5. Test wellness endpoints
6. Test period tracking restriction for general version
