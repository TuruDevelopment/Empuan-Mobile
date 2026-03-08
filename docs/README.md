# 📚 Empuan Mobile - App Version Documentation

## Complete Documentation for Both App Versions

---

## 🎯 App Versions

Empuan Mobile supports **two app versions**:

### 1. General App Version (Wellness App) 📘

**Features:**
- ✅ Wellness tracking (activity, sleep, lifestyle)
- ✅ AI Assistant
- ✅ Personalized insights
- ✅ Health recommendations
- ❌ **NO** period tracking

**Target Users:** Wellness & lifestyle focused users

**Documentation:** [docs/GENERAL_APP_VERSION/](GENERAL_APP_VERSION/README.md)

---

### 2. Health App Version (Period Tracker + Wellness) 📗

**Features:**
- ✅ **Period Tracking** (menstrual cycle monitoring)
- ✅ **Period Predictions** (cycle forecasting)
- ✅ **Health Statistics** (period analytics)
- ✅ **Wellness Features** (activity, sleep, lifestyle)
- ✅ **AI Assistant**
- ✅ **Personalized Insights**

**Target Users:** Menstrual health tracking users

**Documentation:** [docs/HEALTH_APP_VERSION/](HEALTH_APP_VERSION/README.md)

---

## 📁 Documentation Structure

```
docs/
├── GENERAL_APP_VERSION/       ← Wellness App Documentation
│   ├── README.md
│   ├── 1-setup/
│   │   └── QUICK_START.md
│   ├── 2-changes/
│   │   └── WHAT_TO_CHANGE.md
│   └── 3-api/
│       └── ENDPOINTS.md
│
└── HEALTH_APP_VERSION/        ← Health App Documentation
    ├── README.md
    ├── 1-setup/
    │   └── QUICK_START.md
    ├── 2-changes/
    │   └── WHAT_TO_CHANGE.md
    └── 3-api/
        └── ENDPOINTS.md
```

---

## ⚡ Quick Navigation

### For General App Version (Wellness)

1. **Start Here:** [GENERAL_APP_VERSION/README.md](GENERAL_APP_VERSION/README.md)
2. **Quick Setup:** [GENERAL_APP_VERSION/1-setup/QUICK_START.md](GENERAL_APP_VERSION/1-setup/QUICK_START.md)
3. **Configuration:** [GENERAL_APP_VERSION/2-changes/WHAT_TO_CHANGE.md](GENERAL_APP_VERSION/2-changes/WHAT_TO_CHANGE.md)
4. **API Reference:** [GENERAL_APP_VERSION/3-api/ENDPOINTS.md](GENERAL_APP_VERSION/3-api/ENDPOINTS.md)

---

### For Health App Version (Period Tracker)

1. **Start Here:** [HEALTH_APP_VERSION/README.md](HEALTH_APP_VERSION/README.md)
2. **Quick Setup:** [HEALTH_APP_VERSION/1-setup/QUICK_START.md](HEALTH_APP_VERSION/1-setup/QUICK_START.md)
3. **Configuration:** [HEALTH_APP_VERSION/2-changes/WHAT_TO_CHANGE.md](HEALTH_APP_VERSION/2-changes/WHAT_TO_CHANGE.md)
4. **API Reference:** [HEALTH_APP_VERSION/3-api/ENDPOINTS.md](HEALTH_APP_VERSION/3-api/ENDPOINTS.md)

---

## 🔑 Key Differences

| Feature | General Version | Health Version |
|---------|----------------|----------------|
| **App Version** | `general` | `health` |
| **Period Tracking** | ❌ Not available | ✅ Available |
| **Wellness Features** | ✅ Available | ✅ Available |
| **Onboarding Questions** | Wellness only | Health + Wellness |
| **Backend Seeders** | WellnessQuestionSeeder | BOTH seeders |
| **API Endpoints** | Wellness only | ALL endpoints |
| **Target Users** | Wellness & lifestyle | Menstrual health |

---

## 🚀 Quick Start (Both Versions)

### General Version

```bash
# Backend
php artisan migrate
php artisan db:seed WellnessQuestionSeeder

# Frontend: Set app_version
'app_version': 'general',

# Run app
flutter run -d emulator-5554
```

### Health Version

```bash
# Backend
php artisan migrate
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder  # ← Important!

# Frontend: Set app_version
'app_version': 'health',

# Run app
flutter run -d emulator-5554
```

---

## 🔄 Auto-Upgrade Feature

Health app supports **auto-upgrade** for General version users:

```dart
// General user tries period tracking
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  autoUpgrade: true, // ← Auto-upgrade to health
);

// User is now health version!
```

**Documentation:** [HEALTH_APP_VERSION/3-api/ENDPOINTS.md](HEALTH_APP_VERSION/3-api/ENDPOINTS.md#auto-upgrade-feature)

---

## 📞 Support & Resources

### Service Files

| File | Purpose |
|------|---------|
| `lib/services/wellness_service.dart` | Wellness API operations |
| `lib/services/period_tracking_helper.dart` | Period tracking with auto-upgrade |
| `lib/components/upgrade_dialog.dart` | Upgrade prompts |
| `lib/config/api_config.dart` | API endpoint configuration |

### Root Documentation

| Document | Location |
|----------|----------|
| FRONTEND_AUTO_UPGRADE_INTEGRATION.md | `/FRONTEND_AUTO_UPGRADE_INTEGRATION.md` |
| AUTO_UPGRADE_INTEGRATION_SUMMARY.md | `/AUTO_UPGRADE_INTEGRATION_SUMMARY.md` |
| REGISTRATION_API_GUIDE.md | `/REGISTRATION_API_GUIDE.md` |
| WELLNESS_API_DOCUMENTATION.md | `/WELLNESS_API_DOCUMENTATION.md` |

---

## ✅ Verification Checklist

### Before Release (General Version)

- [ ] `app_version: 'general'` in registration
- [ ] WellnessQuestionSeeder run
- [ ] No period tracking in UI
- [ ] Wellness features work
- [ ] Upgrade prompt shows when needed

### Before Release (Health Version)

- [ ] `app_version: 'health'` in registration
- [ ] BOTH seeders run
- [ ] Period tracking UI visible
- [ ] Period data submission works
- [ ] All features accessible

---

## 🎯 Choosing the Right Version

### Choose General Version If:

- ✅ Building wellness-only app
- ✅ Target audience: lifestyle & fitness
- ✅ No menstrual health tracking needed
- ✅ Simpler feature set preferred

### Choose Health Version If:

- ✅ Building complete health app
- ✅ Target audience: women's health
- ✅ Period tracking is core feature
- ✅ Full feature set needed

---

## 📝 Recent Updates

| Date | Update |
|------|--------|
| March 8, 2026 | Complete documentation restructure |
| March 8, 2026 | Added Health App Version docs |
| March 8, 2026 | Added General App Version docs |
| March 8, 2026 | Added auto-upgrade documentation |

---

## 🆘 Need Help?

### Quick Troubleshooting

**Issue: Questions not loading**
```bash
php artisan db:seed WellnessQuestionSeeder
php artisan optimize:clear
```

**Issue: Wrong app version**
Check registration code:
```dart
'app_version': 'general', // or 'health'
```

**Issue: Period tracking blocked**
Use auto-upgrade:
```dart
autoUpgrade: true
```

### Debug Commands

```bash
# Backend: Check questions
php artisan tinker
>>> \App\Models\Question::where('question_type', 'wellness')->count();

# Frontend: Check logs
flutter logs | grep -E "REGISTRATION|ONBOARDING|PERIOD"

# Database: Check user version
SELECT app_version FROM users WHERE email = 'test@example.com';
```

---

**Version:** 1.0  
**Last Updated:** March 8, 2026  
**Maintained By:** Development Team
