# General App Version - Quick Checklist

## ✅ Registration & Onboarding

### 1. Registration Form
```dart
// File: Your registration screen
'app_version': 'general', // ← MUST be 'general'
```

**Check:**
- [ ] `app_version` set to `'general'`
- [ ] No health-specific fields in registration
- [ ] User created successfully in database

---

### 2. Onboarding Questions
```dart
// File: lib/signUp/questions.dart

// Question 1: Activity Level
question1 = [
  'Very active', 'Moderately active', 'Sedentary', 'I don't know'
];

// Question 2: Sleep Quality  
question3 = [
  'No, I sleep well', 'Difficulty falling asleep', ...
];

// Question 3: Wellness Concerns
question4 = [
  'Stress management', 'Energy levels', 'Mood balance', ...
];

// Question 4: Fitness Goals
question5 = [
  'None', 'Lose weight', 'Gain weight', ...
];
```

**Check:**
- [ ] Questions are wellness-focused (not health/period)
- [ ] No period-related questions
- [ ] Backend has matching questions

---

### 3. Onboarding Submission
```dart
// File: lib/signUp/questions.dart

final body = {
  'answers': answers,
  'activity_level': activityLevel,
  'sleep_quality': sleepQuality,
  'wellness_concerns': wellnessConcerns,
  // NO period fields
};
```

**Check:**
- [ ] Submits to `/api/onboarding/submit`
- [ ] Includes activity_level
- [ ] Includes sleep_quality
- [ ] Includes wellness_concerns
- [ ] NO cycle_regularity field
- [ ] NO last_period_start field
- [ ] NO last_period_end field

---

## 🎨 UI/UX Changes

### 4. Home Screen Features

**Show:**
- [ ] AI Assistant/Chatbot
- [ ] Wellness tracking
- [ ] Activity insights
- [ ] Sleep insights
- [ ] Health tips
- [ ] Profile/settings

**Hide/Remove:**
- [ ] ❌ Period tracker button
- [ ] ❌ Cycle calendar
- [ ] ❌ Period predictions
- [ ] ❌ Menstrual health stats

---

### 5. App Branding

**Update Text:**

| Instead of | Use |
|------------|-----|
| "Track Your Period" | "Track Your Wellness" |
| "Menstrual Health" | "Health & Lifestyle" |
| "Cycle Tracker" | "Activity Tracker" |
| "Period Insights" | "Wellness Insights" |

**Check:**
- [ ] No period/menstrual/cycle mentions
- [ ] Wellness-focused language throughout
- [ ] Icons reflect wellness (not period)

---

### 6. Upgrade Prompt

**When User Tries Period Tracking:**

```dart
// Show upgrade dialog
final confirmed = await UpgradeDialog.show(context);

if (confirmed == true) {
  // Perform upgrade
  await WellnessService().upgradeToHealth();
}
```

**Check:**
- [ ] Upgrade dialog shows when accessing period tracking
- [ ] "Later" button keeps user on general version
- [ ] "Upgrade Now" button initiates upgrade
- [ ] Upgrade completes successfully

---

## 🔌 API Integration

### 7. API Endpoints to Use

**Use These:**
```dart
✅ POST /api/register
✅ POST /api/login
✅ GET /api/wellness/questions
✅ POST /api/onboarding/submit
✅ GET /api/wellness/profile
✅ PUT /api/wellness/profile
✅ GET /api/wellness/stats
```

**DO NOT Use:**
```dart
❌ POST /api/catatan-haid (without auto_upgrade)
❌ GET /api/catatan-haid
❌ GET /api/catatan-haid/stats
```

---

### 8. Token Management

```dart
// After registration
AuthService.token = tokenFromResponse;

// Before API calls
headers: AuthService.getAuthHeaders()
```

**Check:**
- [ ] Token saved after registration
- [ ] Token included in authenticated requests
- [ ] Token persists across app restarts

---

## 🔧 Backend Configuration

### 9. Database Seeder

**Run:**
```bash
php artisan db:seed WellnessQuestionSeeder
```

**DO NOT Run:**
```bash
# Don't run for general app
php artisan db:seed HealthQuestionSeeder
```

**Check:**
- [ ] Wellness questions exist in database
- [ ] Question type = 'wellness'
- [ ] No health/period questions seeded

---

### 10. User Database

**Expected User Record:**
```sql
id: 1
name: "John Doe"
email: "john@example.com"
app_version: "general"  ← MUST be 'general'
activity_level: "Moderately active"
sleep_quality: "Difficulty falling asleep"
wellness_concerns: ["Stress management"]
onboarding_completed: true
```

**Check:**
- [ ] `app_version` = 'general'
- [ ] `activity_level` populated
- [ ] `sleep_quality` populated
- [ ] `wellness_concerns` populated (JSON)
- [ ] `onboarding_completed` = true

---

## 🧪 Testing

### 11. Registration Flow

- [ ] Register new user
- [ ] Verify `app_version` = 'general'
- [ ] Check database for user record
- [ ] Token received successfully

---

### 12. Onboarding Flow

- [ ] Questions load from backend
- [ ] Can select answers for all 4 questions
- [ ] Submit onboarding successfully
- [ ] Success dialog appears
- [ ] Navigate to AllSetPage

---

### 13. Feature Access

- [ ] Wellness features accessible
- [ ] Period tracking shows upgrade prompt
- [ ] Upgrade dialog displays correctly
- [ ] Can decline upgrade ("Later")
- [ ] Can accept upgrade ("Upgrade Now")

---

### 14. API Calls

- [ ] `/api/wellness/questions` returns questions
- [ ] `/api/onboarding/submit` succeeds
- [ ] `/api/wellness/profile` returns data
- [ ] `/api/catatan-haid` returns 403 (expected)

---

## 📊 Analytics (Optional)

### 15. Track Events

```dart
Analytics.logEvent('registration_completed');
Analytics.logEvent('wellness_onboarding_started');
Analytics.logEvent('wellness_onboarding_completed');
Analytics.logEvent('activity_level_selected');
Analytics.logEvent('sleep_quality_selected');
Analytics.logEvent('wellness_concerns_selected');
Analytics.logEvent('upgrade_prompt_shown');
Analytics.logEvent('upgrade_accepted');
Analytics.logEvent('upgrade_declined');
```

**Check:**
- [ ] Analytics events fire correctly
- [ ] User properties set (app_version)
- [ ] Funnels configured for onboarding

---

## 🐛 Troubleshooting

### Common Issues

**Issue: Questions not loading**
```bash
# Solution: Run seeder
php artisan db:seed WellnessQuestionSeeder
php artisan optimize:clear
```

**Issue: User created as 'health'**
```dart
// Check registration code
'app_version': 'general', // ← Must be 'general'
```

**Issue: Onboarding fails**
- Check question/option ID mapping
- Verify backend has matching questions
- Check API logs for exact error

**Issue: Period tracking accessible**
- Check backend middleware
- Verify app_version check in controller

---

## ✅ Final Verification

### Before Release:

- [ ] All registration fields correct
- [ ] Onboarding completes successfully
- [ ] No period tracking in UI
- [ ] Wellness branding throughout
- [ ] Upgrade prompt works
- [ ] API calls use correct endpoints
- [ ] Database has correct app_version
- [ ] All tests pass

---

## 📝 Summary

**General App Version = Wellness App**

1. ✅ `app_version: 'general'`
2. ✅ Wellness questions only
3. ✅ No period tracking features
4. ✅ Wellness branding
5. ✅ Upgrade prompt for period features
6. ✅ Wellness API endpoints only
7. ✅ WellnessQuestionSeeder

**Done!** 🎉

---

## Document Info

- **Version:** 1.0
- **Date:** March 8, 2026
- **Type:** Quick Reference Checklist
- **Related:** `GENERAL_APP_VERSION_CONFIG.md`
