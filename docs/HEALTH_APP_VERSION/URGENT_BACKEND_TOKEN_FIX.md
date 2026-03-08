# 🚨 URGENT: Backend Token Authentication Issue

## Problem

The auto-upgrade endpoint is returning **401 Unauthenticated** even though we're sending a valid Bearer token.

**Frontend Logs:**
```
[HOME] Current token: 50|idToAVkQqIOHhV3Td...
[HOME] Calling upgrade endpoint: http://192.168.1.4:8000/api/wellness/upgrade-to-health
[HOME] Upgrade response status: 401
[HOME] Upgrade response body: {"message":"Unauthenticated."}
```

---

## ✅ Backend Fix Required

### Issue: Sanctum Not Accepting Token

The backend Sanctum middleware is rejecting the token. This could be because:

1. **Wrong middleware** - Using `auth:api` instead of `auth:sanctum`
2. **Token format issue** - Sanctum tokens need special handling
3. **Guard configuration** - Wrong auth guard

---

## 🔧 Solution

### Option 1: Fix Middleware (Recommended)

**File:** `routes/api.php`

**Check your route definition:**

```php
// ❌ WRONG - This might not work with Sanctum
Route::middleware(['auth:api'])->group(function () {
    Route::post('/wellness/upgrade-to-health', [WellnessController::class, 'upgradeToHealth']);
});

// ✅ CORRECT - Use sanctum middleware
Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('/wellness/upgrade-to-health', [WellnessController::class, 'upgradeToHealth']);
});
```

---

### Option 2: Make Endpoint Public (Quick Fix)

Since auto-upgrade is optional, make the endpoint accept unauthenticated requests and get user from token in controller:

**File:** `routes/api.php`

```php
// Make it public (no auth middleware)
Route::post('/wellness/upgrade-to-health', [WellnessController::class, 'upgradeToHealth']);
```

**File:** `app/Http/Controllers/WellnessController.php`

```php
public function upgradeToHealth(Request $request)
{
    // Manually authenticate user from token
    $user = $request->user('sanctum');
    
    if (!$user) {
        return response()->json([
            'message' => 'Unauthenticated',
            'already_upgraded' => false
        ], 401);
    }
    
    // ... rest of the code
}
```

---

### Option 3: Manual Database Upgrade (Immediate Fix)

Until backend is fixed, manually upgrade users:

```sql
-- Upgrade user ID 14 (from logs)
UPDATE users SET app_version = 'health' WHERE id = 14;

-- Verify
SELECT id, email, app_version, token FROM users WHERE id = 14;
```

Then login again - user will be health version and won't need upgrade!

---

## 🧪 Test the Fix

After applying Option 1 or 2:

**Using cURL:**
```bash
curl -X POST http://localhost:8000/api/wellness/upgrade-to-health \
  -H "Authorization: Bearer 50|idToAVkQqIOHhV3TdJbJe9BxtTTWO3aJmleRtrp6a76c3c97" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -v
```

**Expected:** 200 OK with upgrade response

---

## 📝 Sanctum Configuration Check

**File:** `config/sanctum.php`

Ensure Sanctum is configured correctly:

```php
return [
    'guard' => ['sanctum'],
    'expiration' => null,
    'tokenable' => Laravel\Sanctum\PersonalAccessToken::class,
    // ...
];
```

**File:** `app/Http/Kernel.php`

Ensure sanctum middleware exists:

```php
protected $middlewareAliases = [
    // ...
    'auth:sanctum' => \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
];
```

---

## 🎯 Why This Happens

Sanctum uses **token-based authentication** which is different from session-based auth.

**Token format:**
```
50|idToAVkQqIOHhV3TdJbJe9BxtTTWO3aJmleRtrp6a76c3c97
```

**Header format:**
```
Authorization: Bearer 50|idToAVkQqIOHhV3TdJbJe9BxtTTWO3aJmleRtrp6a76c3c97
```

If middleware is wrong (`auth:api` vs `auth:sanctum`), token won't be validated correctly.

---

## ✅ Quick Checklist for Backend Dev

- [ ] Check route middleware: `auth:sanctum` (not `auth:api`)
- [ ] Test endpoint with cURL
- [ ] Check Sanctum configuration
- [ ] Verify token in database matches what frontend sends
- [ ] Clear cache: `php artisan optimize:clear`

---

## 🚀 Immediate Workaround

Until backend is fixed, **manually upgrade the user**:

```sql
UPDATE users SET app_version = 'health' WHERE id = 14;
```

Then:
1. Clear app data or logout
2. Login again
3. User is now health version - no upgrade needed!

---

**Status:** 🚨 Backend Fix Required  
**Priority:** Critical  
**Impact:** General users can't auto-upgrade to health version

---

**Last Updated:** March 8, 2026  
**Issue:** 401 Unauthenticated on upgrade endpoint  
**Root Cause:** Sanctum middleware configuration
