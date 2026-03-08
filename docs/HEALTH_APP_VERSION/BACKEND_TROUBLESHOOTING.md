# 🔍 Backend Endpoint Troubleshooting Guide

## Issue: Auto-Upgrade Not Working

Backend developer says the endpoint exists, but the app is still failing to auto-upgrade general users.

---

## 🎯 What's Happening

**Frontend Logs:**
```
[HOME] User app version: general
[HOME] User is general version, attempting auto-upgrade...
[HOME] Auto-upgrade failed, skipping period tracking
```

This means the frontend is calling the endpoint, but it's **failing or returning an error**.

---

## ✅ Step-by-Step Troubleshooting

### Step 1: Verify Endpoint Exists

**Run in backend terminal:**
```bash
cd path/to/your/backend
php artisan route:list --path=wellness
```

**Look for:**
```
POST | api/wellness/upgrade-to-health
```

**If NOT found:** The route is missing - add it to `routes/api.php`

---

### Step 2: Test Endpoint with cURL

**Get a valid token first** (login as a user), then:

```bash
curl -X POST http://localhost:8000/api/wellness/upgrade-to-health \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -v
```

**Expected Response (200 OK):**
```json
{
  "message": "Successfully upgraded to health version",
  "already_upgraded": false,
  "data": {
    "app_version": "health",
    "previous_version": "general"
  }
}
```

**If 404:** Route doesn't exist  
**If 401/403:** Authentication issue  
**If 500:** Server error - check logs

---

### Step 3: Check Backend Logs

```bash
tail -f storage/logs/laravel.log
```

Then test the endpoint again and watch for errors.

**Common errors:**
- `RouteNotFoundException` - Route not defined
- `AuthenticationException` - Sanctum issue
- `SQLSTATE[Column not found]` - Missing `app_version` column

---

### Step 4: Check Database Column

```bash
php artisan tinker
```

```php
// Check if column exists
Schema::hasColumn('users', 'app_version');
// Should return: true

// Check a user's app_version
App\Models\User::find(14)->app_version;
// Should return: 'general' or 'health'
```

**If column missing:** Run migration
```bash
php artisan migrate
```

---

## 🔧 Quick Fixes

### Fix 1: Manually Upgrade User (Immediate)

```sql
-- Upgrade specific user (ID 14 from logs)
UPDATE users SET app_version = 'health' WHERE id = 14;

-- Verify
SELECT id, email, app_version FROM users WHERE id = 14;
```

Then login again - should work!

---

### Fix 2: Clear All Caches

```bash
cd path/to/your/backend

# Clear everything
php artisan optimize:clear

# Clear specific caches
php artisan route:clear
php artisan config:clear
php artisan cache:clear
php artisan view:clear
```

---

### Fix 3: Re-create the Route

If route is missing, add to `routes/api.php`:

```php
Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('/wellness/upgrade-to-health', [WellnessController::class, 'upgradeToHealth']);
});
```

Then clear cache and test again.

---

## 📊 Frontend Changes Made

I've updated the frontend to:

1. **Use `http.post` directly** instead of `ApiClient` (to avoid auto-logout on 403)
2. **Add detailed logging** to see exactly what's happening
3. **Handle all error cases** gracefully

**File:** `lib/screens/HomePage.dart`  
**Function:** `_autoUpgradeToHealth()`

**New logs you'll see:**
```
[HOME] Calling upgrade endpoint: http://192.168.1.4:8000/api/wellness/upgrade-to-health
[HOME] Upgrade response status: 200
[HOME] Upgrade response body: {...}
[HOME] Already upgraded: false
[HOME] Successfully auto-upgraded to health version
```

---

## 🎯 Test After Fix

1. **Hot reload** Flutter app: Press `r` in terminal
2. **Login** with general user (`ms@m.com`)
3. **Check logs** - should see:

```
[HOME] User app version: general
[HOME] Calling upgrade endpoint: ...
[HOME] Upgrade response status: 200
[HOME] Upgrade response body: {"message":"Successfully upgraded...","already_upgraded":false}
[HOME] Already upgraded: false
[HOME] Successfully auto-upgraded to health version
[HOME] Fetching period data...
```

4. **User stays logged in!** ✅

---

## ✅ Checklist for Backend Dev

- [ ] Run `php artisan route:list --path=wellness`
- [ ] Verify endpoint is listed
- [ ] Test with cURL (get 200 response)
- [ ] Check `users` table has `app_version` column
- [ ] Check backend logs for errors
- [ ] Clear all caches
- [ ] Test with a general user account

---

## 📞 Common Issues

### "Endpoint returns 404"
**Solution:** Add route to `routes/api.php`

### "Endpoint returns 401/403"
**Solution:** Check Sanctum authentication, verify token is valid

### "Endpoint returns 500"
**Solution:** Check `storage/logs/laravel.log` for exact error

### "Endpoint returns 200 but user not upgraded"
**Solution:** Check if `app_version` column is being updated in controller

### "Can't modify backend right now"
**Solution:** Manually upgrade user in database:
```sql
UPDATE users SET app_version = 'health' WHERE id = 14;
```

---

**Status:** 🔍 Troubleshooting  
**Priority:** High  
**Next Step:** Backend dev should run Step 1 & Step 2 above

---

**Last Updated:** March 8, 2026  
**Issue:** Auto-upgrade endpoint not responding correctly  
**Frontend:** Updated with better error handling
