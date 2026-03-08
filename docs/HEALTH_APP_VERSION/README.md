# 📗 Health App Version - Complete Guide

## Overview

This documentation covers everything you need to configure and maintain the **Health App Version** (Period Tracker + Wellness) of Empuan Mobile.

---

## 🎯 What is Health App Version?

The **Health App Version** is the complete health-focused version of the Empuan app that includes:

- ✅ **Period Tracking** (menstrual cycle monitoring)
- ✅ **Period Predictions** (cycle forecasting)
- ✅ **Health Statistics** (period analytics)
- ✅ **Wellness Features** (activity, sleep, lifestyle)
- ✅ **AI Assistant**
- ✅ **Personalized Insights**

---

## 📁 Documentation Structure

```
docs/HEALTH_APP_VERSION/
├── README.md                      ← You are here
├── 1-setup/
│   ├── QUICK_START.md            ← Start here for 5-min setup
│   ├── BACKEND_SETUP.md          ← Backend configuration
│   └── FRONTEND_SETUP.md         ← Frontend configuration
├── 2-changes/
│   ├── WHAT_TO_CHANGE.md         ← Complete list of changes
│   ├── FILES_TO_MODIFY.md        ← Files that need modification
│   └── BRANDING_GUIDE.md         ← UI/UX branding guidelines
└── 3-api/
    ├── ENDPOINTS.md              ← API endpoints for health version
    ├── PERIOD_TRACKING.md        ← Period tracking API usage
    └── AUTO_UPGRADE.md           ← Auto-upgrade feature guide
```

---

## ⚡ Quick Start

### 1. Backend Setup (5 min)

```bash
# Run migrations
php artisan migrate

# Seed BOTH wellness AND health questions
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder

# Clear cache
php artisan optimize:clear
```

### 2. Frontend Configuration (2 min)

**File:** `lib/signUp/tempSignUpPage.dart` or your registration file

```dart
final body = {
  'name': fullName,
  'email': email,
  'password': password,
  'app_version': 'health', // ← MUST be 'health' for period tracker
  // ... other fields
};
```

### 3. Run the App

```bash
flutter pub get
flutter run -d emulator-5554
```

---

## 🔑 Key Configuration Points

### 1. Registration

Set `app_version` to `'health'`:

```dart
final body = {
  'name': fullName,
  'email': email,
  'password': password,
  'app_version': 'health', // ← Important!
  // ... other fields
};
```

### 2. Onboarding Questions

Use health questions (includes period-related questions):

```dart
// File: lib/signUp/questions.dart
final questions = await WellnessService().getQuestions(
  type: 'health', // ← Health type for period tracking
  limit: 10,
);
```

### 3. Features Available

**All features available in Health version:**
- ✅ Period tracker
- ✅ Cycle calendar
- ✅ Period predictions
- ✅ Menstrual health stats
- ✅ Wellness tracking
- ✅ Activity insights
- ✅ Sleep insights
- ✅ AI Assistant

### 4. API Endpoints

**All endpoints available:**
```dart
✅ POST /api/register
✅ POST /api/login
✅ GET /api/wellness/questions
✅ POST /api/onboarding/submit
✅ GET /api/wellness/profile
✅ PUT /api/wellness/profile
✅ POST /api/catatan-haid       // Period tracking
✅ GET /api/catatan-haid
✅ GET /api/catatan-haid/stats
```

---

## 📋 Complete Change Checklist

### Registration & Onboarding

- [ ] Set `app_version: 'health'` in registration
- [ ] Use health questions (includes period questions)
- [ ] Submit period data to `/api/catatan-haid`
- [ ] Include cycle_regularity, last_period_start, last_period_end

### UI/UX Features

- [ ] Show period tracker on home screen
- [ ] Show cycle calendar
- [ ] Show period predictions
- [ ] Show menstrual health stats
- [ ] Keep all wellness features

### Backend Configuration

- [ ] Run BOTH seeders: WellnessQuestionSeeder + HealthQuestionSeeder
- [ ] Verify health questions in database
- [ ] Clear cache: `php artisan optimize:clear`

### Testing

- [ ] Register new user with `app_version: 'health'`
- [ ] Verify `app_version = 'health'` in database
- [ ] Complete onboarding with period data
- [ ] Submit period tracking data
- [ ] Verify all features accessible

---

## 🎨 Branding Guidelines

### Language

| Use | Description |
|-----|-------------|
| "Track Your Period" | Period tracking feature |
| "Menstrual Health" | Health section |
| "Cycle Tracker" | Cycle monitoring |
| "Period Insights" | Period analytics |
| "Wellness + Health" | Complete app |

### Icons

| Icon | Feature |
|------|---------|
| 🩸 | Period tracking |
| 📅 | Cycle calendar |
| 🔮 | Period predictions |
| 💚 | Wellness features |

---

## 🔄 Auto-Upgrade Feature

Health app supports **auto-upgrade** for users who register as General version:

```dart
// Submit period data with auto-upgrade
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  autoUpgrade: true, // ← Auto-upgrade general users to health
);

if (result['upgraded'] == true) {
  print('User was auto-upgraded to health version!');
}
```

---

## 🐛 Troubleshooting

### Issue: Period Tracking Not Accessible

**Solution:**
Check registration:
```dart
'app_version': 'health', // ← Must be 'health', not 'general'
```

### Issue: Health Questions Not Loading

**Solution:**
```bash
php artisan db:seed HealthQuestionSeeder
php artisan optimize:clear
```

### Issue: 403 on Period Tracking

**Solution:**
User needs health version. Either:
1. Re-register with `app_version: 'health'`
2. Use auto-upgrade: `auto_upgrade: true` in request
3. Manual upgrade via `/api/wellness/upgrade-to-health`

---

## 📞 Quick Reference

### Backend Commands

```bash
# Run migrations
php artisan migrate

# Seed BOTH wellness AND health questions
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder

# Clear cache
php artisan optimize:clear

# Check routes
php artisan route:list --path=catatan-haid
php artisan route:list --path=wellness

# Check database
php artisan tinker
>>> \App\Models\Question::where('question_type', 'health')->count();
```

### Frontend Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run -d emulator-5554

# Check logs
flutter logs | grep -E "REGISTRATION|ONBOARDING|PERIOD"

# Clean build
flutter clean && flutter pub get
```

### Database Checks

```sql
-- Check user's app version (should be 'health')
SELECT id, name, email, app_version, onboarding_completed 
FROM users 
WHERE email = 'user@example.com';

-- Check health questions
SELECT id, question, question_type 
FROM questions 
WHERE question_type = 'health';

-- Check period data
SELECT * FROM catatan_haid WHERE user_id = 1;
```

---

## 📚 Related Documentation

| Document | Location |
|----------|----------|
| Wellness Service | `/lib/services/wellness_service.dart` |
| Period Tracking Helper | `/lib/services/period_tracking_helper.dart` |
| Upgrade Dialog | `/lib/components/upgrade_dialog.dart` |
| API Config | `/lib/config/api_config.dart` |

---

## ✅ Verification Checklist

Before releasing Health App Version:

### Backend
- [ ] Migrations ran successfully
- [ ] BOTH seeders executed (Wellness + Health)
- [ ] Health questions exist in database
- [ ] Period tracking endpoints accessible

### Frontend
- [ ] `app_version: 'health'` in registration
- [ ] Health questions load correctly
- [ ] Onboarding submits period data
- [ ] Period tracking UI visible
- [ ] All features accessible

### Database
- [ ] Users have `app_version = 'health'`
- [ ] Period data saved in `catatan_haid` table
- [ ] `onboarding_completed = true` after onboarding

---

## 🚀 Next Steps

1. **Setup:** Read [1-setup/QUICK_START.md](1-setup/QUICK_START.md)
2. **Changes:** Read [2-changes/WHAT_TO_CHANGE.md](2-changes/WHAT_TO_CHANGE.md)
3. **API:** Read [3-api/ENDPOINTS.md](3-api/ENDPOINTS.md)
4. **Test:** Follow testing checklist

---

**Version:** 1.0  
**Last Updated:** March 8, 2026  
**Status:** ✅ Ready to Use
