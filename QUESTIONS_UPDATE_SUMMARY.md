# Questions.dart & Upgrade UI - Update Summary

## ✅ Completed Updates

### 1. Updated `lib/signUp/questions.dart`

#### Changes Made:

**A. Added WellnessService Import**
```dart
import 'package:Empuan/services/wellness_service.dart';
```

**B. Updated Question Fetching**
- Now uses `WellnessService().getQuestions()` instead of direct HTTP call
- Properly maps backend question/option IDs to frontend indices
- Shows success/error messages when questions load
- Better error handling with user feedback

**C. Updated Onboarding Submission**
- Uses mapped backend IDs for questions and options
- Shows success dialog (`_showOnboardingSuccess()`) instead of direct navigation
- Better error messages from backend

**D. Added Success Dialog**
- Beautiful animated success screen
- Shows feature preview (AI Assistant, Personalized Insights, Wellness Support)
- Smooth transition to AllSetPage

**E. Added Feature Row Widget**
- Reusable `_buildFeatureRow()` method
- Consistent styling with app theme

---

### 2. Created `lib/components/upgrade_dialog.dart`

A reusable dialog component for prompting users to upgrade from general to health version.

#### Features:

**`UpgradeDialog.show(context)`**
- Shows upgrade prompt with benefits list
- Returns `true` if user agrees to upgrade
- Returns `false` if user chooses "Later"

**`UpgradeDialog.showWithUpgrade(context)`**
- Shows upgrade progress dialog
- Automatically calls `WellnessService().upgradeToHealth()`
- Returns result of upgrade

#### Usage Example:

```dart
// Show upgrade prompt
final confirmed = await UpgradeDialog.show(context);

if (confirmed == true) {
  // User agreed to upgrade
  final result = await UpgradeDialog.showWithUpgrade(context);
  
  if (result == true) {
    // Upgrade successful
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Upgraded to health version!')),
    );
  }
}
```

---

## 📊 Question ID Mapping

The app now properly maps frontend question selections to backend IDs:

```
Frontend Question 0 (Activity) → Backend Question ID from API
Frontend Question 1 (Sleep)    → Backend Question ID from API
Frontend Question 2 (Wellness) → Backend Question ID from API

Frontend Option 0,1,2,3...     → Backend Option IDs from API
```

### Logging for Debugging:

```
[ONBOARDING] === Question 0 ===
[ONBOARDING] Backend ID: 1
[ONBOARDING] Text: How active is your daily lifestyle?
[ONBOARDING] Options: 1: Very active, 2: Moderately active, 3: Sedentary, 4: I don't know
[ONBOARDING]   Map option 0 (Very active) -> 1
[ONBOARDING]   Map option 1 (Moderately active) -> 2
[ONBOARDING]   Map option 2 (Sedentary) -> 3
[ONBOARDING]   Map option 3 (I don't know) -> 4
```

---

## 🎨 UI Components Added

### 1. Success Dialog (`_showOnboardingSuccess()`)

```
┌─────────────────────────────────┐
│         ✓ (icon)                │
│                                 │
│        All Set!                 │
│                                 │
│  Your profile has been set up   │
│      successfully.              │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 🤖 AI Assistant           │  │
│  │    Get instant answers    │  │
│  │ 📈 Personalized Insights  │  │
│  │  Tailored recommendations │  │
│  │ ❤️ Wellness Support       │  │
│  │  Your journey companion   │  │
│  └───────────────────────────┘  │
│                                 │
│     [    Continue    →  ]       │
└─────────────────────────────────┘
```

### 2. Upgrade Dialog (`UpgradeDialog`)

```
┌─────────────────────────────────┐
│         ↑ (icon)                │
│                                 │
│   Unlock Period Tracking        │
│                                 │
│  Upgrade to health version to   │
│  access period tracking...      │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 📅 Track Your Cycle       │  │
│  │  Monitor your health      │  │
│  │ 🔮 Get Predictions        │  │
│  │  Know when it's due       │  │
│  │ 📊 View Statistics        │  │
│  │  Understand patterns      │  │
│  │ ❤️ All Wellness Features  │  │
│  │  Keep your data           │  │
│  └───────────────────────────┘  │
│                                 │
│  [  Later  ]  [↑ Upgrade Now]  │
└─────────────────────────────────┘
```

### 3. Upgrade Progress Dialog

```
┌─────────────────────────────────┐
│         ⏳ (loading)            │
│                                 │
│   Upgrading your account...     │
│                                 │
│  Please wait while we upgrade   │
│         your account            │
└─────────────────────────────────┘
```

---

## 🔄 Flow Diagram

### Onboarding Flow (Updated)

```
User Registration
       ↓
Fetch Questions from Backend
       ↓
Show Loading Screen
       ↓
Questions Loaded? → No → Show Error → Retry
       ↓ Yes
Show Questions (4 pages)
       ↓
User Answers All
       ↓
Click "Finish"
       ↓
Submit to /api/onboarding/submit
(with mapped backend IDs)
       ↓
Success? → No → Show Error
       ↓ Yes
Show Success Dialog
       ↓
Click "Continue"
       ↓
Navigate to AllSetPage
```

### Upgrade Flow (New)

```
User accesses period tracking
       ↓
Check app_version
       ↓
Is 'general'? → No → Allow access
       ↓ Yes
Show Upgrade Dialog
       ↓
User chooses:
  - "Later" → Stay on general
  - "Upgrade Now" → Show progress
       ↓
Call /api/wellness/upgrade-to-health
       ↓
Success? → Yes → Allow access
       ↓ No
Show error, stay on general
```

---

## 📝 Testing Checklist

### Questions Loading
- [ ] Questions fetch from backend
- [ ] Question IDs are mapped correctly
- [ ] Option IDs are mapped correctly
- [ ] Success message shows when loaded
- [ ] Error message shows on failure

### Onboarding Submission
- [ ] Answers use correct backend IDs
- [ ] Activity level is sent
- [ ] Sleep quality is sent
- [ ] Wellness concerns are sent
- [ ] Success dialog appears
- [ ] Navigation to AllSetPage works

### Upgrade Dialog
- [ ] Dialog shows correctly
- [ ] Benefits are displayed
- [ ] "Later" button works
- [ ] "Upgrade Now" button works
- [ ] Progress dialog shows
- [ ] Upgrade completes successfully
- [ ] Error handling works

---

## 🎯 Key Code Changes

### Before (Hardcoded IDs):
```dart
final body = {
  'answers': [
    {'question_id': 1, 'option_id': 2, ...}, // ❌ Hardcoded
    {'question_id': 2, 'option_id': 6, ...}, // ❌ Wrong IDs
  ],
  ...
};
```

### After (Mapped IDs):
```dart
// Map frontend to backend
final backendQuestionId = questionIdMap[0]; // ✅ From API
final backendOptionId = optionIdMap[0]?[selectedId]; // ✅ From API

answers.add({
  'question_id': backendQuestionId,
  'option_id': backendOptionId,
  ...
});
```

---

## 📁 Files Modified/Created

| File | Status | Changes |
|------|--------|---------|
| `lib/signUp/questions.dart` | Modified | Use WellnessService, map IDs, add success dialog |
| `lib/components/upgrade_dialog.dart` | Created | Reusable upgrade prompt dialogs |
| `lib/config/api_config.dart` | Modified | Added wellness endpoints (earlier) |
| `lib/services/wellness_service.dart` | Created | Wellness operations (earlier) |

---

## 🚀 Next Steps

1. **Test with Backend:**
   - Run `php artisan db:seed WellnessQuestionSeeder`
   - Register new user
   - Complete onboarding
   - Check logs for ID mapping

2. **Add Upgrade Integration:**
   - Add upgrade prompt before period tracking access
   - Use `UpgradeDialog.showWithUpgrade()` in period tracking flow

3. **Polish UI:**
   - Add animations to success dialog
   - Add sound effects (optional)
   - Improve loading states

---

## 📞 Debugging Tips

### Check Question Mapping:
```bash
flutter logs | grep "ONBOARDING.*Question"
```

Expected output:
```
[ONBOARDING] === Question 0 ===
[ONBOARDING] Backend ID: 1
[ONBOARDING] Text: How active is your daily lifestyle?
[ONBOARDING] Question ID map: {0: 1, 1: 2, 2: 4}
[ONBOARDING] Option ID map: {0: {0: 1, 1: 2, ...}, ...}
```

### Check Submission:
```bash
flutter logs | grep "ONBOARDING.*Submitting"
```

Expected:
```
[ONBOARDING] Submitting to: http://192.168.1.4:8000/api/onboarding/submit
[ONBOARDING] Request body: {answers: [{question_id: 1, option_id: 2, ...}], ...}
```

---

## ✅ Summary

All requested updates are complete:

1. ✅ **Questions use fetched backend IDs** - No more hardcoded values
2. ✅ **Success dialog added** - Beautiful onboarding completion screen
3. ✅ **Upgrade dialog created** - Reusable component for upgrade prompts
4. ✅ **Better error handling** - User-friendly messages
5. ✅ **Proper logging** - Easy to debug ID mapping

**Ready for testing!** 🎉

---

## Document Info

- **Version:** 1.0
- **Date:** March 8, 2026
- **Status:** Implementation Complete
