# 📝 What to Change - Health App Version

## Complete List of Changes for Health App Version

---

## 1. Registration Configuration

### File: `lib/signUp/tempSignUpPage.dart`

**Change:** Set `app_version` to `'health'`

```dart
// Find the RegistrationUser function
Future<Map<String, dynamic>?> RegistrationUser(...) async {
  final body = {
    "name": name,
    "dob": dob,
    "email": email,
    "username": username,
    "password": password,
    "gender": "Perempuan",
    "app_version": "health",  // ← CHANGE THIS to 'health'
  };
  // ... rest of code
}
```

**Why:** This tells the backend this is a Health app user who needs access to period tracking features.

---

## 2. Onboarding Questions

### File: `lib/signUp/questions.dart`

**Change:** Fetch health questions instead of wellness questions

```dart
Future<void> _fetchWellnessQuestions() async {
  // Change type from 'wellness' to 'health'
  final questions = await WellnessService().getQuestions(
    type: 'health',  // ← CHANGE THIS to 'health'
    limit: 10,
  );
  // ... rest of code
}
```

**Why:** Health version includes period-related questions in onboarding.

---

## 3. Onboarding Submission

### File: `lib/signUp/questions.dart`

**Change:** Include period-related fields in submission

```dart
Future<void> _submitOnboarding() async {
  final body = {
    'answers': answers,
    'activity_level': activityLevel,
    'sleep_quality': sleepQuality,
    'wellness_concerns': wellnessConcerns,
    
    // ADD these for health version:
    'cycle_regularity': cycleRegularity,      // ← ADD
    'last_period_start': lastPeriodStart,     // ← ADD
    'last_period_end': lastPeriodEnd,         // ← ADD
  };
  // ... rest of code
}
```

**Why:** Health version collects menstrual cycle data during onboarding.

---

## 4. Period Tracking Integration

### File: Your period tracking screen (e.g., `lib/screens/periodTracker.dart`)

**Add:** Use PeriodTrackingHelper with auto-upgrade support

```dart
// Submit period data
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  endDate: DateTime(2026, 2, 5),
  autoUpgrade: true,  // ← Auto-upgrade if user is general version
);

if (result != null) {
  print('✅ Period data saved');
}
```

**Why:** Allows period tracking data submission with automatic upgrade for general users.

---

## 5. UI Features to Show

### File: Home screen (`lib/screens/home.dart` or `lib/screens/HomePage.dart`)

**Show these features:**

```dart
// Period Tracking Feature
Card(
  title: 'Period Tracker',
  icon: Icons.bloodtype,  // or Icons.water_drop
  onTap: () => navigateToPeriodTracker(),
),

// Cycle Calendar
Card(
  title: 'Cycle Calendar',
  icon: Icons.calendar_month,
  onTap: () => navigateToCycleCalendar(),
),

// Period Predictions
Card(
  title: 'Predictions',
  icon: Icons.insights,
  onTap: () => navigateToPredictions(),
),

// Keep all wellness features too
Card(
  title: 'Wellness Tracking',
  icon: Icons.favorite,
  onTap: () => navigateToWellness(),
),
```

**Why:** Health version includes ALL features (period + wellness).

---

## 6. Branding & Language

### Files: All UI files

**Update text throughout the app:**

| Location | Change To |
|----------|-----------|
| App title | "Empuan - Health & Wellness" |
| Welcome text | "Track your period & wellness" |
| Feature names | Use "Period", "Cycle", "Menstrual" |
| Icons | 🩸 📅 🔮 for period features |

**Example:**
```dart
Text(
  'Track Your Period',  // ← Use period-related language
  style: TextStyle(...),
)
```

---

## 7. Backend Seeder

### Run BOTH seeders:

```bash
# Backend terminal
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder  # ← ADD THIS
```

**Why:** Health version needs both wellness AND health questions.

---

## 8. API Endpoints

### File: `lib/config/api_config.dart`

**Ensure all endpoints are defined:**

```dart
// Wellness endpoints
static const String wellnessQuestions = '/wellness/questions';
static const String onboardingSubmit = '/onboarding/submit';
static const String wellnessProfile = '/wellness/profile';

// Period tracking endpoints (IMPORTANT for health version)
static const String catatanHaid = '/catatan-haid';  // ← MUST HAVE
static const String catatanHaidStats = '/catatan-haid/stats';  // ← MUST HAVE
```

---

## 📋 Complete Checklist

### Registration & Onboarding

- [ ] `app_version: 'health'` in registration
- [ ] Fetch questions with `type: 'health'`
- [ ] Include period data in onboarding submission
- [ ] Submit to `/api/catatan-haid` after onboarding

### UI Features

- [ ] Show period tracker button
- [ ] Show cycle calendar
- [ ] Show period predictions
- [ ] Show menstrual health stats
- [ ] Keep all wellness features
- [ ] Use period-related language

### Backend

- [ ] Run WellnessQuestionSeeder
- [ ] Run HealthQuestionSeeder
- [ ] Verify health questions in database
- [ ] Test period tracking endpoints

### Testing

- [ ] Register with `app_version: 'health'`
- [ ] Verify database: `app_version = 'health'`
- [ ] Complete onboarding with period data
- [ ] Submit period tracking data
- [ ] Access all features without upgrade prompt

---

## 🎯 Quick Reference Table

| What to Change | General Version | Health Version |
|----------------|-----------------|----------------|
| `app_version` | `'general'` | `'health'` |
| Question type | `'wellness'` | `'health'` |
| Period tracking | ❌ Hide | ✅ Show |
| Cycle calendar | ❌ Hide | ✅ Show |
| Predictions | ❌ Hide | ✅ Show |
| Backend seeders | Wellness only | BOTH |
| API endpoints | Wellness only | ALL |

---

## 🐛 Common Mistakes

### ❌ Mistake 1: Wrong app_version

```dart
// WRONG
'app_version': 'general',  // This will block period tracking

// CORRECT
'app_version': 'health',   // This allows period tracking
```

### ❌ Mistake 2: Missing HealthQuestionSeeder

```bash
# WRONG - Only wellness questions
php artisan db:seed WellnessQuestionSeeder

# CORRECT - Both seeders
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder
```

### ❌ Mistake 3: Hiding period features

```dart
// WRONG - Hiding period tracking in health app
if (appVersion == 'health') {
  // Show period tracking
}

// CORRECT - Always show in health app
// Show period tracking (no condition needed)
PeriodTrackerWidget();
```

---

## ✅ Verification

After making all changes:

```sql
-- Check user's app version
SELECT app_version FROM users WHERE email = 'test@health.com';
-- Expected: 'health'

-- Check health questions exist
SELECT COUNT(*) FROM questions WHERE question_type = 'health';
-- Expected: 3 or more

-- Check period data accessible
SELECT * FROM catatan_haid WHERE user_id = 1;
-- Should work without 403 error
```

---

**Last Updated:** March 8, 2026  
**Status:** ✅ Complete
