# Auto-Upgrade Feature - Summary

## ✅ Implementation Complete

The auto-upgrade feature (Option 1) has been successfully implemented!

---

## What Was Implemented

### 1. New Endpoint: Manual Upgrade

**POST** `/api/wellness/upgrade-to-health`

Explicitly upgrade user from general to health version.

### 2. Auto-Upgrade in Period Tracking Endpoints

All period tracking endpoints now support `auto_upgrade: true` flag:

- `POST /api/catatan-haid` - Submit period data
- `GET /api/catatan-haid` - Get period list
- `GET /api/catatan-haid/stats` - Get statistics

---

## How It Works

### Without Auto-Upgrade (Old Behavior)

```dart
// User is "general" version
POST /api/catatan-haid
{
  "start_date": "2026-02-01"
}

// Response: 403 Forbidden
{
  "message": "Period tracking is only available for health version users",
  "upgrade_available": true,
  "upgrade_endpoint": "POST /api/wellness/upgrade-to-health"
}
```

### With Auto-Upgrade (New Behavior)

```dart
// User is "general" version
POST /api/catatan-haid
{
  "auto_upgrade": true,  // ← NEW FLAG
  "start_date": "2026-02-01"
}

// Response: 201 Created (user auto-upgraded to "health")
{
  "message": "Data haid berhasil ditambahkan",
  "data": { ... }
}
```

---

## Frontend Usage

### Simplest Implementation (Recommended)

```dart
// Just add auto_upgrade: true to any period tracking request
final response = await http.post(
  Uri.parse('$baseUrl/catatan-haid'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'auto_upgrade': true,  // ← That's it!
    'start_date': '2026-02-01',
    'end_date': '2026-02-05',
  }),
);

// User is automatically upgraded from "general" to "health"
// No extra code needed!
```

### Manual Upgrade (Alternative)

```dart
// Explicitly upgrade before accessing features
final response = await http.post(
  Uri.parse('$baseUrl/wellness/upgrade-to-health'),
  headers: {'Authorization': 'Bearer $token'},
);

// Now user can access all period tracking features
```

---

## Files Modified

| File | Changes |
|------|---------|
| `WellnessController.php` | Added `upgradeToHealth()` method |
| `CatatanHaidController.php` | Added auto-upgrade logic to `create()`, `list()`, `stats()` |
| `routes/api.php` | Added `/api/wellness/upgrade-to-health` route |

---

## API Endpoints

### Upgrade Endpoint

```
POST /api/wellness/upgrade-to-health
Authorization: Bearer {token}

Response (200):
{
  "message": "Successfully upgraded to health version",
  "already_upgraded": false,
  "data": {
    "app_version": "health",
    "previous_version": "general"
  }
}
```

### Period Tracking with Auto-Upgrade

```
POST /api/catatan-haid
Authorization: Bearer {token}
Content-Type: application/json

{
  "auto_upgrade": true,
  "start_date": "2026-02-01",
  "end_date": "2026-02-05"
}

Response (201):
{
  "message": "Data haid berhasil ditambahkan",
  "data": { ... }
}
```

---

## Testing

### Test Auto-Upgrade

```bash
# 1. Register as general user
curl -X POST http://localhost:8000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "gender": "female",
    "dob": "1995-05-15",
    "app_version": "general"
  }'

# 2. Submit period data with auto-upgrade
curl -X POST http://localhost:8000/api/catatan-haid \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "auto_upgrade": true,
    "start_date": "2026-02-01",
    "end_date": "2026-02-05"
  }'

# 3. Verify user was upgraded
curl -X GET http://localhost:8000/api/wellness/profile \
  -H "Authorization: Bearer TOKEN"

# Should show: "app_version": "health"
```

---

## Behavior Matrix

| User Version | Request | Result |
|--------------|---------|--------|
| `general` | `auto_upgrade: false` (or omitted) | ❌ 403 Error + upgrade hint |
| `general` | `auto_upgrade: true` | ✅ Auto-upgrade to `health` + success |
| `health` | `auto_upgrade: true` or `false` | ✅ Works (no upgrade needed) |

---

## Benefits

### For Users
- ✅ **Seamless experience** - No manual upgrade needed
- ✅ **No interruption** - Continue using app without restart
- ✅ **Instant access** - Get period tracking immediately
- ✅ **Data preserved** - All wellness data stays intact

### For Developers
- ✅ **Simple implementation** - Just add one flag
- ✅ **Backward compatible** - Old code still works
- ✅ **Flexible** - Can use manual upgrade if needed
- ✅ **Clear error messages** - 403 response includes upgrade hint

---

## Migration Path

### For Existing Users

Run this migration to set existing users to 'health':

```bash
php artisan migrate
```

This ensures existing users can still access period tracking.

### For New Users

- **Wellness app:** Register with `app_version: "general"`
- **Health app:** Register with `app_version: "health"` (or let them auto-upgrade)

---

## Recommended Frontend Flow

### Health App (Period Tracker)

```dart
// On first period tracking usage
Future<void> submitPeriodData(DateTime start, DateTime end) async {
  final response = await http.post(
    Uri.parse('$baseUrl/catatan-haid'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'auto_upgrade': true,  // Always include this
      'start_date': start.toIso8601String().split('T')[0],
      'end_date': end.toIso8601String().split('T')[0],
    }),
  );
  
  if (response.statusCode == 201) {
    // Success!
    print('Period data saved');
  } else {
    // Handle error
    print('Error: ${response.body}');
  }
}

// That's it! No need to check app_version or handle upgrade separately.
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| `AUTO_UPGRADE_IMPLEMENTATION.md` | Complete implementation guide |
| `CROSS_APP_USAGE.md` | Cross-app usage scenarios |
| `COMPATIBILITY_GUIDE.md` | Backward compatibility details |
| `REGISTRATION_API_GUIDE.md` | Registration API reference |
| `BOTH_APPS_SUPPORT.md` | Quick summary for both apps |

---

## Next Steps

### For Backend
- ✅ Done! Auto-upgrade is implemented
- ✅ Run migrations: `php artisan migrate`
- ✅ Test with both app versions

### For Frontend (Health App)
1. Add `auto_upgrade: true` to period tracking requests
2. Test with existing general version users
3. Verify upgrade happens seamlessly

### For Frontend (Wellness App)
1. No changes needed (wellness app doesn't use period tracking)
2. Continue using wellness endpoints as before

---

## Quick Reference

### Auto-Upgrade Flag
```json
{
  "auto_upgrade": true
}
```

### Manual Upgrade Endpoint
```
POST /api/wellness/upgrade-to-health
```

### Error Response (with upgrade hint)
```json
{
  "message": "Period tracking is only available for health version users",
  "upgrade_available": true,
  "upgrade_endpoint": "POST /api/wellness/upgrade-to-health"
}
```

---

## TL;DR

**Auto-upgrade is now live!** 🎉

Just add `'auto_upgrade': true` to period tracking requests:

```dart
await http.post(
  Uri.parse('$baseUrl/catatan-haid'),
  body: jsonEncode({
    'auto_upgrade': true,  // ← Magic!
    'start_date': '2026-02-01',
  }),
);
```

Wellness users will be automatically upgraded to health version when they try to access period tracking. **No extra code needed!**

---

## Support

Check logs for debugging:
```bash
tail -f storage/logs/laravel.log
```

Clear cache if needed:
```bash
php artisan optimize:clear
```

Test endpoints:
```bash
php artisan route:list --path=wellness
php artisan route:list --path=catatan-haid
```
