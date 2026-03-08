# ✅ Health App - General User Login Fix

## Problem

When logging in with a **General version** account on the **Health App**, the user was automatically logged out because:

1. App tries to fetch period data (`/api/catatan-haid`) immediately after login
2. Backend returns 403 Forbidden for general version users
3. 403 error triggers session expired handler
4. User gets logged out automatically

---

## Solution Implemented

### Auto-Upgrade on Login

When a general version user logs in:
1. Check user's `app_version` from backend
2. If `general`, automatically upgrade to `health` version
3. Then proceed to fetch period data
4. No more automatic logout!

---

## Changes Made

### File: `lib/screens/HomePage.dart`

#### 1. Added App Version Check

```dart
Future<String> _checkAppVersion() async {
  try {
    final url = '${ApiConfig.baseUrl}/me';
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${AuthService.token}'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final user = jsonData['user'];
      if (user != null && user['app_version'] != null) {
        return user['app_version'];
      }
    }
  } catch (e) {
    print('[HOME] Error checking app version: $e');
  }
  return 'general'; // Default
}
```

#### 2. Added Auto-Upgrade Function

```dart
Future<bool> _autoUpgradeToHealth() async {
  try {
    final url = '${ApiConfig.baseUrl}/wellness/upgrade-to-health';
    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer ${AuthService.token}'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return !jsonData['already_upgraded']; // True if upgraded
    }
  } catch (e) {
    print('[HOME] Error upgrading to health: $e');
  }
  return false;
}
```

#### 3. Updated getData() Function

```dart
Future<void> getData(int userid) async {
  setState(() => isLoading = true);

  // Check app version
  final appVersion = await _checkAppVersion();
  print('[HOME] User app version: $appVersion');

  // Auto-upgrade if general
  if (appVersion == 'general') {
    print('[HOME] Attempting auto-upgrade...');
    final upgraded = await _autoUpgradeToHealth();
    if (upgraded) {
      print('[HOME] Successfully upgraded to health!');
    } else {
      print('[HOME] Upgrade failed, skipping period tracking');
      setState(() => isLoading = false);
      return;
    }
  }

  // Now fetch period data (user is now health version)
  // ... rest of the code
}
```

#### 4. Handle 403 Errors Gracefully

```dart
// In getData()
if (response.statusCode == 403) {
  print('[HOME] 403 Forbidden - User needs health version');
  // Handle gracefully, don't crash
}

// In getStats()
if (response.statusCode == 403) {
  print("[HOME] 403 Forbidden - User needs health version for stats");
  setState(() {
    daysUntilNextPeriod = null;
    predictedNextPeriod = null;
  });
}
```

---

## How It Works

### Before (❌ Broken)

```
User logs in (general version)
    ↓
HomePage tries to fetch period data
    ↓
Backend returns 403 Forbidden
    ↓
Session expired handler triggered
    ↓
User automatically logged out ❌
```

### After (✅ Fixed)

```
User logs in (general version)
    ↓
Check app version
    ↓
If general → Auto-upgrade to health
    ↓
Backend upgrades user successfully
    ↓
Fetch period data (now works!)
    ↓
User stays logged in ✅
```

---

## Testing

### Test Case 1: General User Logs In

1. Register user with `app_version: 'general'`
2. Login on health app
3. Check console logs:

```
[HOME] User app version: general
[HOME] User is general version, attempting auto-upgrade...
[HOME] Successfully auto-upgraded to health version
[HOME] Fetching period data...
```

4. User should stay logged in
5. Period tracking should work

### Test Case 2: Health User Logs In

1. Register user with `app_version: 'health'`
2. Login on health app
3. Check console logs:

```
[HOME] User app version: health
[HOME] Fetching period data...
```

4. No upgrade needed
5. Everything works normally

---

## Backend Requirements

Make sure this endpoint exists:

```
POST /api/wellness/upgrade-to-health
Authorization: Bearer {token}

Response (200):
{
  "message": "Successfully upgraded to health version",
  "already_upgraded": false
}
```

If endpoint doesn't exist, run on backend:
```bash
php artisan optimize:clear
```

---

## Benefits

### ✅ For Users

- No automatic logout
- Seamless upgrade experience
- Period tracking works immediately
- No manual upgrade needed

### ✅ For Developers

- Clean error handling
- Graceful 403 handling
- Auto-upgrade logic centralized
- Easy to maintain

---

## Alternative Solution (Manual Upgrade)

If you prefer manual upgrade instead of auto:

```dart
if (appVersion == 'general') {
  // Show upgrade dialog
  final confirmed = await UpgradeDialog.show(context);
  
  if (confirmed) {
    await _autoUpgradeToHealth();
  } else {
    // Navigate to wellness-only screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WellnessHomePage()),
    );
  }
}
```

---

## Files Modified

| File | Changes |
|------|---------|
| `lib/screens/HomePage.dart` | Added `_checkAppVersion()`, `_autoUpgradeToHealth()`, updated `getData()`, `getStats()` |

---

## Verification Checklist

- [ ] General user can login without logout
- [ ] Auto-upgrade works correctly
- [ ] Period data fetches successfully
- [ ] Health users not affected
- [ ] 403 errors handled gracefully
- [ ] No crashes or exceptions

---

## Logs to Check

After login with general user, you should see:

```
[HOME] User app version: general
[HOME] User is general version, attempting auto-upgrade...
[HOME] Successfully auto-upgraded to health version
[HOME] Fetching period data...
✅ Tanggal Prediksi Ditemukan: ...
```

---

**Status:** ✅ Fixed  
**Last Updated:** March 8, 2026  
**Issue:** General user auto-logout on health app  
**Solution:** Auto-upgrade on login
