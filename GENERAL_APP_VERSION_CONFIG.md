# General App Version - Configuration Guide

## 📋 Overview

This guide explains what needs to be changed/configured for the **General App Version** (Wellness App) vs the **Health App Version** (Period Tracker + Wellness).

---

## 🎯 App Version Differences

| Feature | General Version | Health Version |
|---------|----------------|----------------|
| **App Version String** | `'general'` | `'health'` |
| **Period Tracking** | ❌ Not available | ✅ Available |
| **Wellness Features** | ✅ Available | ✅ Available |
| **Onboarding Questions** | Wellness-focused | Health + Wellness |
| **Target Users** | Wellness & lifestyle | Menstrual health tracking |

---

## 🔧 Changes Required for General App Version

### 1. Registration Configuration

**File:** Your registration screen/file

**Change:** Set `app_version` to `'general'`

```dart
// In your registration function
final registerResponse = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'name': fullName,
    'username': username,
    'email': email,
    'password': password,
    'gender': 'Perempuan',
    'dob': selectedDate.toIso8601String().split('T')[0],
    'app_version': 'general', // ← CHANGE THIS for general app
  }),
);
```

---

### 2. Onboarding Questions

**File:** `lib/signUp/questions.dart` (already configured)

**Current Configuration:**
```dart
// Question 1: Activity Level
List<Map<String, dynamic>> question1 = [
  {"id": 0, "selected": false, "title": 'Very active'},
  {"id": 1, "selected": false, "title": 'Moderately active'},
  {"id": 2, "selected": false, "title": 'Sedentary'},
  {"id": 3, "selected": false, "title": 'I don\'t know'},
];

// Question 2: Sleep Quality
List<Map<String, dynamic>> question3 = [
  {"id": 0, "selected": false, "title": 'No, I sleep well'},
  {"id": 1, "selected": false, "title": 'Difficulty falling asleep'},
  {"id": 2, "selected": false, 'title': 'Waking up tired'},
  // ... more options
];

// Question 3: Wellness Concerns
List<Map<String, dynamic>> question4 = [
  {"id": 0, "selected": false, "title": 'Stress management'},
  {"id": 1, "selected": false, "title": 'Energy levels'},
  {"id": 2, "selected": false, "title": 'Mood balance'},
  {"id": 3, "selected": false, "title": 'Physical fitness'},
  // ... more options
];

// Question 4: Fitness Goals
List<Map<String, dynamic>> question5 = [
  {"id": 0, "selected": false, "title": 'None'},
  {"id": 1, "selected": false, "title": 'Lose weight'},
  {"id": 2, "selected": false, "title": 'Gain weight'},
  // ... more options
];
```

**To Change Questions:**
- Edit the `title` values in the lists above
- Add/remove options by modifying the lists
- Ensure backend has matching questions (run seeder after changes)

---

### 3. Onboarding Submission

**File:** `lib/signUp/questions.dart` (already configured)

**Current Configuration:**
```dart
final body = {
  'answers': answers, // Uses mapped backend IDs
  'activity_level': activityLevel,
  'sleep_quality': sleepQuality,
  'wellness_concerns': wellnessConcerns,
  // NO period-related fields for general version
};
```

**No changes needed** - already configured for general version.

---

### 4. Feature Availability

**File:** Your home screen / feature menu

**Hide Period Tracking Features:**

```dart
// Check app version
final appVersion = await WellnessService().getAppVersion();
final isHealthVersion = appVersion == 'health';

// Show/hide features based on version
if (isHealthVersion) {
  // Show period tracking button
  PeriodTrackerButton();
} else {
  // Show upgrade prompt instead
  UpgradePromptWidget();
}
```

**Alternative - Use Upgrade Dialog:**

```dart
// When user tries to access period tracking
onPeriodTrackingTap: () async {
  final appVersion = await WellnessService().getAppVersion();
  
  if (appVersion == 'general') {
    // Show upgrade dialog
    final confirmed = await UpgradeDialog.show(context);
    
    if (confirmed == true) {
      // Perform upgrade
      final result = await UpgradeDialog.showWithUpgrade(context);
      
      if (result == true) {
        // Navigate to period tracking
        Navigator.push(context, ...);
      }
    }
  } else {
    // Navigate to period tracking
    Navigator.push(context, ...);
  }
}
```

---

### 5. UI Text & Branding

**Files to Update:**

#### A. Welcome/Intro Screens

**File:** `lib/signUp/intro.dart`, `lib/start_page.dart`

**Change text to reflect wellness focus:**

```dart
// Before (Health App)
Text('Track Your Period'),
Text('Monitor your menstrual health'),

// After (General App)
Text('Track Your Wellness'),
Text('Monitor your health & lifestyle'),
```

#### B. Success Page

**File:** `lib/signUp/allSetPage.dart`

**Current Configuration (already updated):**
```dart
_buildFeatureItem(
  icon: Icons.smart_toy_rounded,
  title: 'AI Assistant',
  description: 'Get instant answers to your questions',
),
_buildFeatureItem(
  icon: Icons.self_improvement_rounded,
  title: 'Personalized Insights',
  description: 'Get tailored recommendations',
),
_buildFeatureItem(
  icon: Icons.favorite_rounded,
  title: 'Wellness Support',
  description: 'Support for your entire journey',
),
```

**No period tracking mentions** - already configured for general version.

---

### 6. API Endpoints to Use

**General Version Should Use:**

| Endpoint | Purpose | Auth Required |
|----------|---------|---------------|
| `POST /api/register` | Register user | ❌ |
| `POST /api/login` | Login user | ❌ |
| `GET /api/wellness/questions` | Get onboarding questions | ✅ |
| `POST /api/onboarding/submit` | Submit onboarding | ✅ |
| `GET /api/wellness/profile` | Get user profile | ✅ |
| `PUT /api/wellness/profile` | Update profile | ✅ |
| `GET /api/wellness/stats` | Get wellness stats | ✅ |
| `POST /api/wellness/answers` | Submit answers | ✅ |

**DO NOT Use (Health Version Only):**

| Endpoint | Purpose |
|----------|---------|
| `POST /api/catatan-haid` | Submit period data |
| `GET /api/catatan-haid` | Get period list |
| `GET /api/catatan-haid/stats` | Get period stats |

**Note:** If general version user tries to access period endpoints without `auto_upgrade: true`, they will get 403 Forbidden error.

---

### 7. Backend Seeder Configuration

**For General Version, seed wellness questions:**

```bash
# Run wellness question seeder
php artisan db:seed WellnessQuestionSeeder
```

**Wellness Questions (Expected):**
1. Activity level question
2. Sleep quality question
3. Wellness concerns question

**DO NOT run HealthQuestionSeeder** for general version (contains period-related questions).

---

## 📱 Complete General App Flow

```
1. Registration
   ↓
   POST /api/register
   {
     "app_version": "general"
   }
   
2. Onboarding
   ↓
   GET /api/wellness/questions?type=wellness
   ↓
   Show 4 wellness questions
   ↓
   POST /api/onboarding/submit
   {
     "activity_level": "...",
     "sleep_quality": "...",
     "wellness_concerns": [...]
   }
   
3. Main App
   ↓
   Show wellness features only
   ↓
   If user tries period tracking:
   - Show upgrade dialog
   - OR allow auto-upgrade with flag
```

---

## 🎨 UI/UX Recommendations for General App

### 1. Home Screen Features

**Show:**
- ✅ AI Assistant/Chatbot
- ✅ Wellness tracking
- ✅ Activity/sleep insights
- ✅ Health tips
- ✅ Profile settings

**Hide/Replace:**
- ❌ Period tracker → Replace with "Wellness Tracker"
- ❌ Cycle calendar → Replace with "Activity Calendar"
- ❌ Period predictions → Replace with "Wellness Insights"

### 2. Upgrade Prompt

**When to Show:**
- User taps on period tracking feature
- User searches for period-related content
- User completes wellness onboarding (optional upsell)

**How to Show:**
```dart
// Example upgrade prompt
final confirmed = await UpgradeDialog.show(context);

if (confirmed == true) {
  // User wants to upgrade
  final result = await WellnessService().upgradeToHealth();
  
  if (result == 'upgraded') {
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Upgraded to health version!')),
    );
  }
}
```

---

## 🔐 User Data & Privacy

### General Version Data Collection

**Collected During Registration:**
- Name
- Email
- Username
- Password (encrypted)
- Gender
- Date of birth
- App version (`general`)

**Collected During Onboarding:**
- Activity level
- Sleep quality
- Wellness concerns

**NOT Collected (Health Version Only):**
- Menstrual cycle data
- Period start/end dates
- Cycle regularity
- Period symptoms

---

## 📊 Analytics & Tracking

**Track for General Version:**

```dart
// Example analytics events
Analytics.logEvent('wellness_onboarding_completed');
Analytics.logEvent('activity_level_selected', {'level': activityLevel});
Analytics.logEvent('sleep_quality_selected', {'quality': sleepQuality});
Analytics.logEvent('wellness_concerns_selected', {'concerns': concerns});
Analytics.logEvent('upgrade_prompt_shown');
Analytics.logEvent('upgrade_accepted');
Analytics.logEvent('upgrade_declined');
```

---

## 🧪 Testing Checklist for General App

### Registration & Onboarding
- [ ] Register with `app_version: 'general'`
- [ ] Verify user created with `app_version = 'general'`
- [ ] Wellness questions load correctly
- [ ] Submit onboarding answers
- [ ] Verify answers saved in database
- [ ] Verify `onboarding_completed = true`

### Feature Access
- [ ] Wellness features accessible
- [ ] Period tracking shows upgrade prompt
- [ ] Upgrade dialog displays correctly
- [ ] Upgrade completes successfully
- [ ] After upgrade, period tracking accessible

### API Calls
- [ ] `/api/wellness/questions` returns wellness questions
- [ ] `/api/onboarding/submit` accepts wellness data
- [ ] `/api/wellness/profile` returns general version profile
- [ ] `/api/catatan-haid` returns 403 (without auto_upgrade)

### UI/UX
- [ ] No period tracking mentions in UI
- [ ] Wellness branding throughout app
- [ ] Upgrade prompt shows when needed
- [ ] Success messages display correctly

---

## 📝 Quick Reference: What to Change

### For General App Version:

| File/Component | Change | Value |
|----------------|--------|-------|
| Registration | `app_version` | `'general'` |
| Onboarding | Question type | `'wellness'` |
| Onboarding Submit | Data fields | Activity, Sleep, Wellness |
| Home Screen | Features | Hide period tracking |
| API Calls | Endpoints | Use wellness endpoints only |
| Backend | Seeder | WellnessQuestionSeeder |
| UI Text | Branding | Wellness-focused language |

### For Health App Version:

| File/Component | Change | Value |
|----------------|--------|-------|
| Registration | `app_version` | `'health'` |
| Onboarding | Question type | `'health'` or `'wellness'` |
| Onboarding Submit | Data fields | Cycle + wellness data |
| Home Screen | Features | Show all features |
| API Calls | Endpoints | All endpoints available |
| Backend | Seeder | Both seeders |
| UI Text | Branding | Health + wellness language |

---

## 🚀 Migration from Health to General

If you need to convert existing health app to general version:

### 1. Update Registration
```dart
// Change this:
'app_version': 'health',

// To this:
'app_version': 'general',
```

### 2. Update Onboarding Questions
Replace health questions with wellness questions in `questions.dart`.

### 3. Update UI
Remove/hide period tracking features from all screens.

### 4. Update Backend
```bash
# Update existing users (optional)
UPDATE users SET app_version = 'general' WHERE app_version = 'health';
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: Questions Not Loading

**Solution:**
```bash
# Run wellness seeder
php artisan db:seed WellnessQuestionSeeder

# Clear cache
php artisan optimize:clear
```

### Issue 2: User Created as Health Version

**Solution:**
```dart
// Ensure registration includes:
'app_version': 'general',
```

### Issue 3: Period Tracking Accessible Without Upgrade

**Solution:**
- Check backend middleware
- Verify `app_version` check in `CatatanHaidController`
- Ensure `auto_upgrade` flag is required

### Issue 4: Onboarding Fails

**Solution:**
- Check question/option ID mapping
- Verify backend has matching questions
- Check logs for exact error message

---

## 📞 Support & Debugging

### Check User's App Version

```dart
final appVersion = await WellnessService().getAppVersion();
print('User app version: $appVersion');
// Output: 'general' or 'health'
```

### Check Backend User Data

```sql
SELECT id, name, email, app_version, onboarding_completed 
FROM users 
WHERE email = 'user@example.com';
```

### Check Onboarding Answers

```sql
SELECT ua.*, q.question, o.text as option_text
FROM user_answers ua
JOIN questions q ON ua.question_id = q.id
LEFT JOIN options o ON ua.option_id = o.id
WHERE ua.user_id = 1;
```

---

## ✅ Summary

**General App Version Configuration:**

1. ✅ Registration: `app_version: 'general'`
2. ✅ Onboarding: Wellness questions only
3. ✅ Features: No period tracking
4. ✅ API: Wellness endpoints only
5. ✅ UI: Wellness branding
6. ✅ Backend: WellnessQuestionSeeder

**All changes documented and ready to implement!** 🎉

---

## Document Info

- **Version:** 1.0
- **Date:** March 8, 2026
- **Purpose:** Guide for configuring General App Version
- **Related Docs:** 
  - `FRONTEND_AUTO_UPGRADE_INTEGRATION.md`
  - `REGISTRATION_API_GUIDE.md`
  - `WELLNESS_API_DOCUMENTATION.md`
