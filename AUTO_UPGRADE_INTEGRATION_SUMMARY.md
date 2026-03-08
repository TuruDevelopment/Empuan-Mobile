# Auto-Upgrade Integration - Implementation Summary

## ✅ Completed Tasks

### 1. API Configuration Updated

**File:** `lib/config/api_config.dart`

**Added Endpoints:**
```dart
// Wellness & Onboarding endpoints
static const String wellnessQuestions = '/wellness/questions';
static const String onboardingSubmit = '/onboarding/submit';
static const String wellnessProfile = '/wellness/profile';
static const String wellnessUpgradeToHealth = '/wellness/upgrade-to-health';
static const String wellnessAnswers = '/wellness/answers';
static const String wellnessStats = '/wellness/stats';
```

---

### 2. Wellness Service Created

**File:** `lib/services/wellness_service.dart`

**Features:**
- ✅ Get app version (`getAppVersion()`)
- ✅ Check if health version (`isHealthVersion()`)
- ✅ Get wellness/health questions (`getQuestions()`)
- ✅ Submit onboarding answers (`submitOnboarding()`)
- ✅ Get user profile (`getProfile()`)
- ✅ Update profile (`updateProfile()`)
- ✅ Manual upgrade (`upgradeToHealth()`)
- ✅ Get statistics (`getStats()`)
- ✅ Submit answers separately (`submitAnswers()`)

**Usage Example:**
```dart
// Get questions
final questions = await WellnessService().getQuestions(
  type: 'wellness',
  limit: 4,
);

// Submit onboarding
await WellnessService().submitOnboarding(
  answers: [...],
  activityLevel: 'Moderately active',
  sleepQuality: 'Good',
  wellnessConcerns: ['Stress management'],
);

// Upgrade to health
final result = await WellnessService().upgradeToHealth();
// Returns: 'upgraded', 'already_upgraded', or 'error'
```

---

### 3. Period Tracking Helper Created

**File:** `lib/services/period_tracking_helper.dart`

**Features:**
- ✅ Submit period data with auto-upgrade (`submitPeriodData()`)
- ✅ Get period history (`getPeriodHistory()`)
- ✅ Get period stats (`getPeriodStats()`)
- ✅ Check access (`checkAccess()`)
- ✅ Manual upgrade (`upgradeToHealth()`)

**Usage Example:**
```dart
// Submit with auto-upgrade (recommended)
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  endDate: DateTime(2026, 2, 5),
  autoUpgrade: true, // ← Auto-upgrade if needed
  onUpgrade: () {
    print('User was upgraded!');
  },
);

// Get history
final periods = await PeriodTrackingHelper.getPeriodHistory(
  history: true,
  months: 6,
  autoUpgrade: true,
);

// Get stats
final stats = await PeriodTrackingHelper.getPeriodStats(
  months: 6,
  autoUpgrade: true,
);
```

---

### 4. Documentation Created

**File:** `FRONTEND_AUTO_UPGRADE_INTEGRATION.md`

**Contents:**
- Overview of auto-upgrade feature
- Quick start guide
- Detailed API usage examples
- Complete integration examples
- Error handling patterns
- Testing guide
- UI/UX recommendations
- Migration notes

---

## 🎯 How to Use

### For Wellness App (General Version)

```dart
// 1. Register with app_version: 'general'
final registerResponse = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/register'),
  body: jsonEncode({
    'name': 'Jane Doe',
    'email': 'jane@example.com',
    'password': 'password123',
    'app_version': 'general', // ← Wellness app
  }),
);

// 2. Submit onboarding
await WellnessService().submitOnboarding(
  answers: [...],
  activityLevel: 'Moderately active',
  sleepQuality: 'Good',
  wellnessConcerns: ['Stress management'],
);

// 3. User stays on general version
// No access to period tracking (403 error)
```

### For Health App (Period Tracker)

```dart
// 1. Register with app_version: 'health'
final registerResponse = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/register'),
  body: jsonEncode({
    'name': 'Jane Doe',
    'email': 'jane@example.com',
    'password': 'password123',
    'app_version': 'health', // ← Health app
  }),
);

// 2. Submit period data (no upgrade needed)
await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  autoUpgrade: true, // Still recommended
);
```

### For Wellness User Accessing Period Tracking

```dart
// User registered as 'general' tries period tracking
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  autoUpgrade: true, // ← Auto-upgrade happens here!
  onUpgrade: () {
    // Show upgrade success message
    print('🎉 Upgraded to health version!');
  },
);

// User is now 'health' version
// Period data is saved
```

---

## 📊 Auto-Upgrade Flow

```
User (general version)
       ↓
Try to access period tracking
       ↓
Add auto_upgrade: true
       ↓
Backend checks app_version
       ↓
If general → Auto-upgrade to health
       ↓
Save period data
       ↓
Return success + upgraded: true
```

---

## 🔧 Integration Points

### 1. Registration Flow

Update your registration to include `app_version`:

```dart
// In your registration function
'app_version': 'general', // or 'health'
```

### 2. Onboarding Flow

Use `WellnessService.submitOnboarding()`:

```dart
await WellnessService().submitOnboarding(
  answers: mappedAnswers,
  activityLevel: selectedActivity,
  sleepQuality: selectedSleep,
  wellnessConcerns: selectedConcerns,
);
```

### 3. Period Tracking

Use `PeriodTrackingHelper` with `autoUpgrade: true`:

```dart
await PeriodTrackingHelper.submitPeriodData(
  startDate: startDate,
  endDate: endDate,
  autoUpgrade: true,
);
```

---

## ⚠️ Important Notes

### 1. Token Management

All services use `AuthService.token` for authentication. Make sure token is set after login/registration:

```dart
// After successful login/registration
AuthService.token = tokenFromResponse;
```

### 2. Error Handling

Always handle errors gracefully:

```dart
try {
  final result = await PeriodTrackingHelper.submitPeriodData(...);
  if (result != null) {
    // Success
  } else {
    // Failed
    showError('Failed to save data');
  }
} catch (e) {
  showError('Network error: $e');
}
```

### 3. Backend Requirements

Make sure backend has:
- ✅ Wellness questions seeded
- ✅ Migrations run
- ✅ Auto-upgrade endpoint working

Test with:
```bash
php artisan db:seed WellnessQuestionSeeder
php artisan migrate
```

---

## 🧪 Testing Checklist

- [ ] Register user with `app_version: 'general'`
- [ ] Register user with `app_version: 'health'`
- [ ] Submit onboarding answers
- [ ] Get wellness profile
- [ ] Submit period data with `auto_upgrade: true`
- [ ] Verify general user gets upgraded to health
- [ ] Get period history
- [ ] Get period stats
- [ ] Test manual upgrade
- [ ] Test error handling (403 responses)

---

## 📁 Files Modified/Created

| File | Status | Purpose |
|------|--------|---------|
| `lib/config/api_config.dart` | Modified | Added wellness endpoints |
| `lib/services/wellness_service.dart` | Created | Wellness operations |
| `lib/services/period_tracking_helper.dart` | Created | Period tracking with auto-upgrade |
| `FRONTEND_AUTO_UPGRADE_INTEGRATION.md` | Created | Integration guide |
| `AUTO_UPGRADE_INTEGRATION_SUMMARY.md` | Created | This summary |

---

## 🚀 Next Steps

### 1. Update Existing Code

Replace direct API calls with service methods:

**Before:**
```dart
final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/catatan-haid'),
  ...
);
```

**After:**
```dart
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: startDate,
  autoUpgrade: true,
);
```

### 2. Update questions.dart

The current `questions.dart` already uses `WellnessService` pattern. Make sure it:
- Fetches questions from backend
- Maps question/option IDs correctly
- Submits to `/api/onboarding/submit`

### 3. Add UI for Upgrade Prompts

Create dialogs/screens for:
- Upgrade confirmation
- Upgrade success message
- Feature gating (show/hide based on version)

### 4. Test End-to-End

1. Register new user
2. Complete onboarding
3. Try period tracking
4. Verify auto-upgrade works
5. Check backend database

---

## 📞 Support

### Debugging

Check logs:
```bash
# Backend
tail -f storage/logs/laravel.log

# Frontend
flutter logs | grep -E "WELLNESS|PERIOD_TRACKING"
```

### Common Issues

**Issue: Questions return empty array**
- Solution: Run seeder `php artisan db:seed WellnessQuestionSeeder`

**Issue: 401 Unauthorized**
- Solution: Ensure `AuthService.token` is set

**Issue: Auto-upgrade not working**
- Solution: Check backend endpoint `/api/wellness/upgrade-to-health` exists

---

## ✅ Summary

All auto-upgrade features are now integrated into the frontend:

1. ✅ **Wellness Service** - Handle all wellness operations
2. ✅ **Period Tracking Helper** - Period tracking with auto-upgrade
3. ✅ **API Config** - All endpoints configured
4. ✅ **Documentation** - Complete integration guide

**Ready to test!** 🎉

---

## Document Info

- **Version:** 1.0
- **Date:** March 8, 2026
- **Status:** Implementation Complete
