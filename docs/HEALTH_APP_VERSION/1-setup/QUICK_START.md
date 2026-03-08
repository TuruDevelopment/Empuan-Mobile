# ⚡ Quick Start - Health App Version

## 5-Minute Setup Guide

---

## Step 1: Backend (3 minutes)

### 1.1 Run Migrations

```bash
cd your-backend-folder
php artisan migrate
```

### 1.2 Seed BOTH Wellness AND Health Questions

```bash
# Seed wellness questions
php artisan db:seed WellnessQuestionSeeder

# Seed health questions (IMPORTANT!)
php artisan db:seed HealthQuestionSeeder
```

### 1.3 Verify

```bash
php artisan tinker
>>> \App\Models\Question::where('question_type', 'wellness')->count();
// Should return: 3 or more

>>> \App\Models\Question::where('question_type', 'health')->count();
// Should return: 3 or more
```

---

## Step 2: Frontend (2 minutes)

### 2.1 Update Registration

**File:** `lib/signUp/tempSignUpPage.dart`

**Find this code:**
```dart
final body = {
  "name": name,
  "username": username,
  "email": email,
  "password": password,
  "gender": "Perempuan",
  // ... other fields
};
```

**Add this line:**
```dart
final body = {
  "name": name,
  "username": username,
  "email": email,
  "password": password,
  "gender": "Perempuan",
  "app_version": "health",  // ← ADD THIS LINE (change from 'general')
  // ... other fields
};
```

### 2.2 Update Onboarding Questions

**File:** `lib/signUp/questions.dart`

**Find:**
```dart
final questions = await WellnessService().getQuestions(
  type: 'wellness',  // ← Change this
  limit: 10,
);
```

**Change to:**
```dart
final questions = await WellnessService().getQuestions(
  type: 'health',  // ← Changed to 'health'
  limit: 10,
);
```

### 2.3 Verify API Config

**File:** `lib/config/api_config.dart`

**Ensure period tracking endpoints exist:**
```dart
// Period tracking endpoints (IMPORTANT for health version)
static const String catatanHaid = '/catatan-haid';
static String catatanHaidById(int id) => '/admin/catatan-haid/$id';
```

---

## Step 3: Run App

```bash
cd your-mobile-app-folder
flutter pub get
flutter run -d emulator-5554
```

---

## ✅ Verify Setup

### Test Registration
1. Open app
2. Go to registration
3. Fill in details
4. Register

**Check console:**
```
[REGISTRATION] ✅ Registration successful
```

### Test Onboarding
1. Answer questions (should include period-related)
2. Submit

**Check console:**
```
[ONBOARDING] ✅ Onboarding submitted successfully
```

### Test Period Tracking
1. Navigate to period tracker
2. Submit period data

**Check console:**
```
[PERIOD_TRACKING] ✅ Period data submitted successfully
```

### Check Database
```sql
SELECT id, name, app_version FROM users WHERE email = 'your@test.com';
```

**Expected:**
```
app_version = 'health'
```

---

## 🐛 Common Issues

### Health Questions Not Loading?

```bash
php artisan db:seed HealthQuestionSeeder
php artisan optimize:clear
```

### Period Tracking Shows Upgrade Prompt?

Check registration:
```dart
'app_version': 'health', // ← Must be 'health', not 'general'
```

### 403 Error on Period Tracking?

User might be registered as 'general'. Check:
```sql
SELECT app_version FROM users WHERE email = 'test@example.com';
```

If 'general', either:
1. Re-register with `app_version: 'health'`
2. Use auto-upgrade: `auto_upgrade: true` in period tracking request

---

## 📋 What's Next?

1. ✅ Setup complete!
2. Read [WHAT_TO_CHANGE.md](../2-changes/WHAT_TO_CHANGE.md) for detailed changes
3. Read [ENDPOINTS.md](../3-api/ENDPOINTS.md) for API reference
4. Test all period tracking features

---

**Time:** ~5 minutes  
**Status:** ✅ Ready
