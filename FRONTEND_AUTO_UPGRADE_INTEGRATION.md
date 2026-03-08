# Frontend Integration - Auto-Upgrade & Wellness Features

## 📋 Overview

This guide explains how to integrate the backend's **auto-upgrade** and **wellness** features into the Empuan mobile app.

### Key Features

1. **Two App Versions:**
   - `general` - Wellness & lifestyle features only
   - `health` - Period tracking + wellness features

2. **Auto-Upgrade:**
   - Users can be automatically upgraded from `general` to `health` when accessing period tracking
   - No manual intervention required
   - Seamless user experience

3. **Wellness Onboarding:**
   - Collect user preferences during registration
   - Activity level, sleep quality, wellness concerns

---

## 🚀 Quick Start

### 1. Import the Services

```dart
import 'package:Empuan/services/wellness_service.dart';
import 'package:Empuan/services/period_tracking_helper.dart';
```

### 2. Registration (Wellness App)

```dart
// In your registration flow
final registerResponse = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'name': 'Jane Doe',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'password': 'password123',
    'gender': 'Perempuan',
    'dob': '1995-05-15',
    'app_version': 'general', // ← Wellness app
  }),
);

final token = registerResponse.json()['token'];
```

### 3. Registration (Health App / Period Tracker)

```dart
// In your registration flow
final registerResponse = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'name': 'Jane Doe',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'password': 'password123',
    'gender': 'Perempuan',
    'dob': '1995-05-15',
    'app_version': 'health', // ← Health app
  }),
);

final token = registerResponse.json()['token'];
```

### 4. Submit Period Data with Auto-Upgrade

```dart
// Simple usage - auto-upgrade happens automatically
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  endDate: DateTime(2026, 2, 5),
  autoUpgrade: true, // ← Magic!
);

if (result != null) {
  print('✅ Period data saved');
  if (result['upgraded'] == true) {
    print('ℹ️ User was auto-upgraded to health version');
  }
} else {
  print('❌ Failed to save period data');
}
```

---

## 📖 Detailed Usage

### Wellness Service

The `WellnessService` provides methods for all wellness-related operations.

#### Get Questions

```dart
final questions = await WellnessService().getQuestions(
  type: 'wellness', // or 'health'
  limit: 4,
);

// Returns:
// [
//   {
//     "id": 1,
//     "question": "How active is your daily lifestyle?",
//     "options": [
//       {"id": 1, "text": "Very active"},
//       {"id": 2, "text": "Moderately active"},
//       ...
//     ]
//   },
//   ...
// ]
```

#### Submit Onboarding

```dart
final success = await WellnessService().submitOnboarding(
  answers: [
    {
      'question_id': 1,
      'option_id': 2,
      'answer_text': null,
      'answer_type': 'wellness',
    },
    {
      'question_id': 2,
      'option_id': 5,
      'answer_text': null,
      'answer_type': 'wellness',
    },
  ],
  activityLevel: 'Moderately active',
  sleepQuality: 'Difficulty falling asleep',
  wellnessConcerns: ['Stress management', 'Energy levels'],
);

if (success) {
  print('✅ Onboarding completed');
} else {
  print('❌ Onboarding failed');
}
```

#### Get Profile

```dart
final profile = await WellnessService().getProfile();

// Returns:
// {
//   "data": {
//     "user": {
//       "id": 1,
//       "name": "Jane Doe",
//       "app_version": "health",
//       "activity_level": "Moderately active",
//       "sleep_quality": "Difficulty falling asleep",
//       "wellness_concerns": ["Stress management"],
//       "onboarding_completed": true
//     },
//     "answers": [...]
//   }
// }

final appVersion = profile['data']['user']['app_version'];
```

#### Upgrade to Health (Manual)

```dart
final result = await WellnessService().upgradeToHealth();

if (result == 'upgraded') {
  print('✅ Successfully upgraded to health version');
} else if (result == 'already_upgraded') {
  print('ℹ️ User already has health version');
} else {
  print('❌ Upgrade failed');
}
```

---

### Period Tracking Helper

The `PeriodTrackingHelper` wraps period tracking APIs with auto-upgrade support.

#### Submit Period Data

```dart
// Basic usage
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  endDate: DateTime(2026, 2, 5),
  autoUpgrade: true,
);

// With upgrade callback
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: DateTime(2026, 2, 1),
  endDate: DateTime(2026, 2, 5),
  autoUpgrade: true,
  onUpgrade: () {
    print('🎉 User was upgraded! Show celebration message.');
    // Navigate to new screen, show toast, etc.
  },
);
```

#### Get Period History

```dart
final periods = await PeriodTrackingHelper.getPeriodHistory(
  history: true,
  months: 6,
  autoUpgrade: true,
);

if (periods != null) {
  for (var period in periods) {
    print('Period: ${period['start_date']} to ${period['end_date']}');
  }
}
```

#### Get Period Stats

```dart
final stats = await PeriodTrackingHelper.getPeriodStats(
  months: 6,
  autoUpgrade: true,
);

if (stats != null) {
  print('Next period prediction: ${stats['prediction']['predicted_date']}');
  print('Days remaining: ${stats['prediction']['days_remaining']}');
}
```

---

## 🎯 Complete Examples

### Example 1: Wellness App Registration Flow

```dart
class RegistrationService {
  Future<bool> registerAndOnboard({
    required String name,
    required String email,
    required String password,
    required String gender,
    required DateTime dob,
    required List<Map<String, dynamic>> answers,
  }) async {
    // Step 1: Register
    final registerResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': name.replaceAll(' ', '').toLowerCase(),
        'email': email,
        'password': password,
        'gender': gender,
        'dob': dob.toIso8601String().split('T')[0],
        'app_version': 'general', // Wellness app
      }),
    );

    if (registerResponse.statusCode != 200) {
      return false;
    }

    final token = jsonDecode(registerResponse.body)['token'];
    AuthService.token = token;

    // Step 2: Submit onboarding
    final success = await WellnessService().submitOnboarding(
      answers: answers,
      activityLevel: answers[0]['title'],
      sleepQuality: answers[1]['title'],
      wellnessConcerns: [answers[2]['title']],
    );

    return success;
  }
}
```

### Example 2: Health App - First Period Entry

```dart
class PeriodTrackerService {
  Future<void> logFirstPeriod({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    // Check current version
    final appVersion = await WellnessService().getAppVersion();
    
    print('Current app version: $appVersion');

    // Submit with auto-upgrade
    final result = await PeriodTrackingHelper.submitPeriodData(
      startDate: startDate,
      endDate: endDate,
      autoUpgrade: true,
      onUpgrade: () {
        // Show upgrade success message
        print('🎉 Upgraded to health version!');
        // You can show a toast, dialog, or navigate here
      },
    );

    if (result != null) {
      print('✅ Period logged successfully');
      
      // Show success message
      if (result['upgraded'] == true) {
        // First time accessing period tracking - show tutorial
        showPeriodTrackingTutorial();
      }
    } else {
      print('❌ Failed to log period');
      showError('Failed to save period data');
    }
  }

  void showPeriodTrackingTutorial() {
    // Show tutorial for new health version users
  }
}
```

### Example 3: Manual Upgrade with Confirmation Dialog

```dart
class UpgradeService {
  Future<bool> requestUpgrade(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upgrade, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Unlock Period Tracking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upgrade to health version to access period tracking features.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '✨ Benefits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            BulletPoint('Track your menstrual cycle'),
            BulletPoint('Get period predictions'),
            BulletPoint('View health statistics'),
            BulletPoint('All wellness features included'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Upgrade Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Perform upgrade
      final result = await WellnessService().upgradeToHealth();

      if (result == 'upgraded' || result == 'already_upgraded') {
        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully upgraded to health version!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        return true;
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upgrade failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    return false;
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
```

---

## ⚠️ Error Handling

### Handle 403 Forbidden (Upgrade Required)

```dart
Future<void> handleApiError(dynamic error, BuildContext context) async {
  if (error is http.Response) {
    final statusCode = error.statusCode;
    final body = jsonDecode(error.body);

    if (statusCode == 403) {
      if (body['upgrade_available'] == true) {
        // Show upgrade prompt
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Upgrade Required'),
            content: Text(body['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Upgrade'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await WellnessService().upgradeToHealth();
        }
      }
    }
  }
}
```

### Network Errors

```dart
try {
  await PeriodTrackingHelper.submitPeriodData(
    startDate: DateTime.now(),
  );
} on SocketException {
  showError('No internet connection');
} on TimeoutException {
  showError('Request timed out');
} catch (e) {
  showError('Something went wrong: $e');
}
```

---

## 🧪 Testing

### Test Auto-Upgrade Flow

```dart
void testAutoUpgrade() async {
  // 1. Register as general user
  final registerResponse = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': 'Test User',
      'username': 'testuser',
      'email': 'test@example.com',
      'password': 'password123',
      'gender': 'Perempuan',
      'dob': '1995-05-15',
      'app_version': 'general',
    }),
  );

  final token = jsonDecode(registerResponse.body)['token'];
  AuthService.token = token;

  // 2. Check initial version
  final initialVersion = await WellnessService().getAppVersion();
  print('Initial version: $initialVersion'); // Should be 'general'

  // 3. Submit period data with auto-upgrade
  final result = await PeriodTrackingHelper.submitPeriodData(
    startDate: DateTime(2026, 2, 1),
    autoUpgrade: true,
  );

  // 4. Verify upgrade
  final upgradedVersion = await WellnessService().getAppVersion();
  print('Upgraded version: $upgradedVersion'); // Should be 'health'

  // 5. Verify period data was saved
  final periods = await PeriodTrackingHelper.getPeriodHistory();
  print('Period records: ${periods?.length}'); // Should be 1
}
```

---

## 📊 API Endpoints Reference

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/register` | ❌ | Register (add `app_version`) |
| GET | `/api/wellness/questions` | ✅ | Get questions |
| POST | `/api/onboarding/submit` | ✅ | Submit onboarding |
| GET | `/api/wellness/profile` | ✅ | Get profile |
| PUT | `/api/wellness/profile` | ✅ | Update profile |
| POST | `/api/wellness/upgrade-to-health` | ✅ | Manual upgrade |
| POST | `/api/catatan-haid` | ✅ | Submit period data |
| GET | `/api/catatan-haid` | ✅ | Get period list |
| GET | `/api/catatan-haid/stats` | ✅ | Get stats |

---

## 📝 Migration Notes

### For Existing Users

Existing users without `app_version` field will default to `'general'`.

To upgrade all existing users to `'health'`:

```sql
UPDATE users SET app_version = 'health' WHERE app_version IS NULL;
```

Or run the Laravel migration:

```bash
php artisan migrate
```

### For New Users

- **Wellness app:** Register with `'app_version': 'general'`
- **Health app:** Register with `'app_version': 'health'` (or use auto-upgrade)

---

## 🎨 UI/UX Recommendations

### 1. Show Upgrade Success

```dart
if (result['upgraded'] == true) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.celebration, color: Colors.white),
          SizedBox(width: 12),
          Text('🎉 Welcome to Health Version!'),
        ],
      ),
      backgroundColor: AppColors.secondary,
      duration: Duration(seconds: 3),
    ),
  );
}
```

### 2. Loading State During Auto-Upgrade

```dart
final result = await PeriodTrackingHelper.submitPeriodData(
  startDate: startDate,
  autoUpgrade: true,
  onUpgrade: () {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Upgrading your account...'),
          ],
        ),
      ),
    );
  },
);
```

### 3. Feature Gating

```dart
// Show period tracking feature only to health users
final isHealth = await WellnessService().isHealthVersion();

if (isHealth) {
  // Show period tracking UI
  PeriodTrackerWidget();
} else {
  // Show upgrade prompt
  UpgradePromptWidget();
}
```

---

## 🔐 Security Notes

- Always validate token before API calls
- Store token securely (use `SharedPreferences` or `flutter_secure_storage`)
- Handle token expiration (401 responses)
- Use HTTPS in production

---

## 📞 Support

### Debugging

Check Flutter logs:
```
flutter logs | grep -E "WELLNESS|PERIOD_TRACKING"
```

Check backend logs:
```bash
tail -f storage/logs/laravel.log
```

### Common Issues

**Issue: 403 Forbidden**
- Solution: Add `auto_upgrade: true` to request

**Issue: Questions not loading**
- Solution: Run seeder: `php artisan db:seed WellnessQuestionSeeder`

**Issue: Token expired**
- Solution: Re-login and get new token

---

## ✅ Checklist

- [ ] Import services
- [ ] Update registration to include `app_version`
- [ ] Update onboarding to use `WellnessService.submitOnboarding()`
- [ ] Add auto-upgrade to period tracking calls
- [ ] Handle upgrade success/error states
- [ ] Test with both general and health versions
- [ ] Update UI to show/hide features based on version

---

## Document Info

- **Version:** 1.0
- **Last Updated:** March 8, 2026
- **Author:** Backend Team
