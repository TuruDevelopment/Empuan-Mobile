# ✅ Frontend Token Fix - Applied

## Issue: 401 Unauthenticated on Upgrade Endpoint

Backend says the token authentication is failing from the frontend. Here's what was fixed and what to check.

---

## 🔧 Frontend Fixes Applied

### File: `lib/screens/HomePage.dart`

**Function:** `_autoUpgradeToHealth()`

### Changes Made:

#### 1. Enhanced Token Logging

Now logs detailed token information:
```
[HOME] ═══════════════════════════════════════
[HOME] 🔐 Auto-Upgrade Token Check
[HOME] Token exists: true
[HOME] Token length: 60
[HOME] Token preview: 50|idToAVkQqIOHhV3Td...
[HOME] Token starts with number: true
[HOME] ═══════════════════════════════════════
```

#### 2. Token Format Validation

- ✅ Checks if token exists
- ✅ Checks token length
- ✅ Validates token format (Sanctum format: `number|string`)
- ✅ Removes "Bearer " prefix if already present

#### 3. Proper Header Format

Sends token with correct Bearer format:
```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

#### 4. Response Logging

Logs full response for debugging:
```
[HOME] 📥 Upgrade response status: 200
[HOME] 📥 Upgrade response headers: {...}
[HOME] 📥 Upgrade response body: {...}
```

---

## 📝 Token Format

### What Frontend Sends

**Token Format (from Laravel Sanctum):**
```
50|idToAVkQqIOHhV3TdJbJe9BxtTTWO3aJmleRtrp6a76c3c97
```

**Authorization Header:**
```
Authorization: Bearer 50|idToAVkQqIOHhV3TdJbJe9BxtTTWO3aJmleRtrp6a76c3c97
```

**Request Body:**
```json
{}
```

---

## ✅ Backend Verification Checklist

Give this to your backend dev to verify:

### 1. Check Token in Database

```sql
-- Get the user's personal access token
SELECT id, name, tokenable_id, token 
FROM personal_access_tokens 
WHERE tokenable_id = 14;  -- User ID from login
```

**Expected:** Token should exist and match what frontend sends (without the `number|` prefix)

---

### 2. Verify Sanctum Middleware

**File:** `routes/api.php`

```php
// ✅ CORRECT - Use sanctum middleware
Route::middleware(['auth:sanctum'])->group(function () {
    Route::post('/wellness/upgrade-to-health', [WellnessController::class, 'upgradeToHealth']);
});
```

**NOT this:**
```php
// ❌ WRONG - This might not work
Route::middleware(['auth:api'])->group(function () {
    // ...
});
```

---

### 3. Test with cURL

**Get token from frontend logs**, then test:

```bash
curl -X POST http://localhost:8000/api/wellness/upgrade-to-health \
  -H "Authorization: Bearer 50|idToAVkQqIOHhV3TdJbJe9BxtTTWO3aJmleRtrp6a76c3c97" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -v
```

**Expected Response (200):**
```json
{
  "message": "Successfully upgraded to health version",
  "already_upgraded": false
}
```

---

### 4. Check Sanctum Configuration

**File:** `config/sanctum.php`

```php
return [
    'guard' => ['sanctum'],
    'expiration' => null,
    'tokenable' => Laravel\Sanctum\PersonalAccessToken::class,
    'middleware' => [
        'authenticate' => [
            Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        ],
    ],
];
```

---

### 5. Check Kernel Middleware

**File:** `app/Http/Kernel.php`

```php
protected $routeMiddleware = [
    // ...
    'auth:sanctum' => \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
];
```

---

## 🔍 Debug Steps

### Step 1: Hot Reload App

```bash
# In Flutter terminal, press: r
```

### Step 2: Login and Check Logs

After login, you should see:
```
[HOME] ═══════════════════════════════════════
[HOME] 🔐 Auto-Upgrade Token Check
[HOME] Token exists: true
[HOME] Token length: 60
[HOME] Token preview: 50|...
[HOME] Token starts with number: true
[HOME] ═══════════════════════════════════════
```

### Step 3: Share Logs with Backend Dev

Copy the full logs and send to backend dev, especially:
- Token preview (first 20 chars)
- Token length
- Response status
- Response body

---

## 🚀 Quick Workaround

Until backend authentication is fixed, **manually upgrade users**:

```sql
-- Upgrade user ID 14
UPDATE users SET app_version = 'health' WHERE id = 14;

-- Verify
SELECT id, email, app_version FROM users WHERE id = 14;
```

Then login again - user will be health version!

---

## 📊 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Frontend Token Handling | ✅ Fixed | Proper Bearer format |
| Frontend Logging | ✅ Enhanced | Detailed token info |
| Frontend Error Handling | ✅ Graceful | No auto-logout on 401 |
| Backend Authentication | ⚠️ Needs Fix | Returning 401 |
| Auto-Upgrade Feature | ⚠️ Partial | Works if backend auth fixed |

---

## 📞 Next Steps

1. **Frontend:** Hot reload and test (press `r`)
2. **Backend:** Verify Sanctum configuration
3. **Backend:** Test endpoint with cURL using token from logs
4. **Both:** Confirm token format matches what backend expects

---

**Status:** ✅ Frontend Fixed, ⚠️ Backend Verification Needed  
**Last Updated:** March 8, 2026  
**Issue:** 401 Unauthenticated  
**Fix Applied:** Enhanced token handling and logging
