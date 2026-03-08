# ✅ Health App Version - COMPLETE SETUP GUIDE

## Your app is now configured as Health App Version! 📗

---

## 🎯 What Changed

### 1. Registration ✅ UPDATED

**File:** `lib/tempSignUpPage.dart`

**Changed:**
```dart
"app_version": "health",  // ← Changed from 'general' to 'health'
```

**Why:** This enables period tracking features for the user.

---

## ⚡ Quick Setup (5 Minutes)

### Step 1: Backend Setup (3 minutes)

**Open a new terminal and run:**

```bash
# Navigate to your backend folder
cd path/to/your/backend

# Run migrations
php artisan migrate

# Seed BOTH wellness AND health questions
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder

# Clear cache
php artisan optimize:clear
```

**Or copy the full command:**
```bash
cd path/to/your/backend && php artisan migrate && php artisan db:seed WellnessQuestionSeeder && php artisan db:seed HealthQuestionSeeder && php artisan optimize:clear
```

---

### Step 2: Verify Backend (1 minute)

```bash
php artisan tinker
```

Then paste:
```php
\App\Models\Question::where('question_type', 'health')->count();
// Should return: 3 or more

exit
```

---

### Step 3: Run Flutter App (1 minute)

```bash
# In your mobile app folder
cd path/to/empuan-mobile

flutter pub get
flutter run -d emulator-5554
```

---

## ✅ Test the App

### 1. Register New User

1. Open app
2. Go to registration
3. Fill in details
4. Tap "Register"

**Check console:**
```
[REGISTRATION] Health App Version - Registering user...
[REGISTRATION] ✅ Registration successful for HEALTH app version
```

### 2. Complete Onboarding

1. Answer questions (should include period-related questions)
2. Submit

**Check console:**
```
[ONBOARDING] ✅ Onboarding submitted successfully
```

### 3. Test Period Tracking

1. Navigate to period tracker feature
2. Submit period data

**Check console:**
```
[PERIOD_TRACKING] ✅ Period data submitted successfully
```

---

## 🔍 Verify Database

```sql
-- Check user's app version (should be 'health')
SELECT id, name, email, app_version 
FROM users 
WHERE email = 'your@test.com';

-- Expected: app_version = 'health'
```

---

## 📁 Files Modified

| File | Change | Status |
|------|--------|--------|
| `lib/tempSignUpPage.dart` | `app_version: 'health'` | ✅ Done |
| Backend database | Health questions seeded | ⚠️ You must run |
| `lib/config/api_config.dart` | Period endpoints | ✅ Already configured |
| `lib/signUp/questions.dart` | Period questions | ✅ Already configured |

---

## 🎯 Features Available

As a Health App Version, you now have access to:

- ✅ **Period Tracking** - Submit and track menstrual cycles
- ✅ **Period Predictions** - Get cycle forecasts
- ✅ **Health Statistics** - View period analytics
- ✅ **Wellness Features** - Activity, sleep, lifestyle tracking
- ✅ **AI Assistant** - Get health answers
- ✅ **Personalized Insights** - Tailored recommendations

---

## 📊 API Endpoints Available

All endpoints are now accessible:

```dart
✅ POST /api/register
✅ POST /api/login
✅ GET /api/wellness/questions      // Health questions
✅ POST /api/onboarding/submit
✅ GET /api/wellness/profile
✅ PUT /api/wellness/profile
✅ POST /api/catatan-haid           // Period tracking
✅ GET /api/catatan-haid
✅ GET /api/catatan-haid/stats
```

---

## 🐛 Troubleshooting

### Issue: Period Tracking Shows 403 Error

**Cause:** User registered as 'general' instead of 'health'

**Solution:**
1. Check registration code has: `'app_version': 'health'`
2. Re-register new user
3. Or use auto-upgrade: `auto_upgrade: true` in period tracking request

---

### Issue: Health Questions Not Found

**Cause:** HealthQuestionSeeder not run

**Solution:**
```bash
php artisan db:seed HealthQuestionSeeder
php artisan optimize:clear
```

---

### Issue: Questions Not Loading

**Cause:** Backend not running or wrong API URL

**Solution:**
1. Check backend is running: `php artisan serve`
2. Check API URL in `lib/config/api_config.dart`:
   ```dart
   static const String _developmentUrl = 'http://YOUR_IP:8000/api';
   ```

---

## 📞 Quick Commands

### Backend
```bash
# Seed health questions
php artisan db:seed HealthQuestionSeeder

# Clear cache
php artisan optimize:clear

# Check questions
php artisan tinker
>>> \App\Models\Question::where('question_type', 'health')->count();
```

### Frontend
```bash
# Run app
flutter run -d emulator-5554

# Check logs
flutter logs | grep -E "REGISTRATION|PERIOD"
```

### Database
```sql
-- Check health users
SELECT * FROM users WHERE app_version = 'health';

-- Check health questions
SELECT * FROM questions WHERE question_type = 'health';

-- Check period data
SELECT * FROM catatan_haid WHERE user_id = 1;
```

---

## 📚 Documentation

| Document | Location |
|----------|----------|
| Setup Commands | `docs/HEALTH_APP_VERSION/1-setup/SETUP_COMMANDS.md` |
| What to Change | `docs/HEALTH_APP_VERSION/2-changes/WHAT_TO_CHANGE.md` |
| API Endpoints | `docs/HEALTH_APP_VERSION/3-api/ENDPOINTS.md` |
| Changes Applied | `docs/HEALTH_APP_VERSION/HEALTH_APP_CHANGES_APPLIED.md` |

---

## ✅ Checklist

Before you're done:

- [ ] Backend: Run `php artisan db:seed HealthQuestionSeeder`
- [ ] Backend: Run `php artisan db:seed WellnessQuestionSeeder`
- [ ] Backend: Run `php artisan optimize:clear`
- [ ] Frontend: `app_version: 'health'` in registration
- [ ] Test: Register new user
- [ ] Test: Complete onboarding
- [ ] Test: Access period tracking
- [ ] Verify: Database has `app_version = 'health'`

---

## 🎉 You're Done!

Your Health App Version is now fully configured and ready to use!

**Features:**
- ✅ Period tracking enabled
- ✅ Health questions loaded
- ✅ All API endpoints accessible
- ✅ Auto-upgrade support ready

**Next Steps:**
1. Run backend seeders (see SETUP_COMMANDS.md)
2. Test registration
3. Test period tracking
4. Enjoy! 🎊

---

**Last Updated:** March 8, 2026  
**App Version:** Health (Period Tracker + Wellness)  
**Status:** ✅ Ready to Use (after backend setup)
