# Authentication System Fix Documentation

**Date:** December 2, 2025  
**Project:** Empuan Mobile  
**Issue:** NoSuchMethodError in signup flow due to missing constructor parameters

---

## Error Encountered

```
NoSuchMethodError: No constructor 'questions.' with matching arguments declared in class 'questions'.
Receiver: questions
Tried calling: new questions.()
Found: new questions.({Key? key, required String username, required String email, required String password})
```

**Location:** `lib/signUp/bridgetoQ.dart:236`

---

## Root Cause Analysis

The error occurred because the `questions` widget constructor was being called without any arguments in `bridgetoQ.dart`, but the widget definition requires three parameters:

- `username` (String, required)
- `email` (String, required)
- `password` (String, required)

This was part of a larger authentication system overhaul where we had recently added the `email` parameter to the entire signup flow to support the new API specification that requires email-based login instead of username-based login.

---

## Background: Authentication System Changes

### API Specification Changes (api.json)

**Previous Authentication:**

- Login endpoint: `/users/login`
- Login parameter: `username`
- Response format: `{data: {id, username, token}}`

**New Authentication:**

- Login endpoint: `/login`
- Login parameter: `email` (NOT username)
- Response format: `{user: {...}, roles: "...", token: "..."}`

**Registration Changes:**

- Removed extra `token` field from request body
- Changed `gender` from int to string
- Endpoint: `/users` → `/register`

---

## Files Modified in Authentication Overhaul

### 1. Core Authentication Service

**File:** `lib/services/auth_service.dart`

**Changes:**

```dart
// OLD
Future<bool> login({required String username, required String password})
data: {"username": username, 'password': password}
if (obj['data'] != null && obj['data']['token'] != null) {
  token = obj['data']['token'];
}

// NEW
Future<bool> login({required String email, required String password})
data: {"email": email, 'password': password}
if (obj['token'] != null) {
  token = obj['token'];
  final userId = obj['user']?['id'];
  final username = obj['user']?['username'];
}
```

### 2. Login Screen

**File:** `lib/login_page.dart`

**Changes:**

- Field label: "Username" → "Email"
- Icon: `Icons.person_outline` → `Icons.email_outlined`
- Hint text: "enter your username" → "enter your email"
- Parameter: `username: username` → `email: emailOrUsername`

### 3. Registration Forms

**Files:**

- `lib/tempSignUpPage.dart`
- `lib/accountCred.dart`

**Changes:**

```dart
// REMOVED
final token = Uuid().v4();
"token": token,

// UPDATED
"gender": "1"  // Changed from int to string

// ADDED TO NAVIGATION
email: emailController.text
```

### 4. Signup Flow Widget Chain

The signup flow consists of 5 interconnected widgets that pass data through navigation:

**Registration Form** → **BridgetoQ** → **questions** → **Question1** → **Question2**

All widgets needed the `email` parameter added to support email-based auto-login after registration.

#### Widget Chain Updates

**File:** `lib/signUp/bridgetoQ.dart`

```dart
// ADDED
final String email;

const BridgetoQ({
  Key? key,
  required this.username,
  required this.email,  // NEW
  required this.password,
}) : super(key: key);

// Navigation updated to pass email
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => questions(
      username: widget.username,
      email: widget.email,  // NEW
      password: widget.password,
    ),
  ),
);
```

**File:** `lib/signUp/questions.dart`

```dart
// ADDED
final String email;

const questions({
  Key? key,
  required this.username,
  required this.email,  // NEW
  required this.password,
}) : super(key: key);

// Auto-login updated
Future<void> doLogin() async {
  final email2 = widget.email;  // Changed from username2
  bool isSuccess = await AuthService().login(
    email: email2,  // Changed from username
    password: password2
  );
}
```

**File:** `lib/signUp/question1.dart`

```dart
// ADDED
final String email;

const Question1({
  Key? key,
  required this.username,
  required this.email,  // NEW
  required this.password,
}) : super(key: key);

// Navigation updated
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => Question2(
      username: widget.username,
      email: widget.email,  // NEW
      password: widget.password,
    ),
  ),
);
```

**File:** `lib/signUp/question2.dart`

```dart
// ADDED
final String email;

const Question2({
  Key? key,
  required this.username,
  required this.email,  // NEW
  required this.password,
}) : super(key: key);

// Auto-login updated
doLogin() async {
  final email = widget.email;  // Changed from username
  bool isSuccess = await AuthService().login(
    email: email,  // Changed from username
    password: password
  );
}
```

---

## The Missing Piece: bridgetoQ Navigation

### The Bug

In `lib/signUp/bridgetoQ.dart` at line 236, the code was calling the `questions` constructor without any arguments:

```dart
// INCORRECT - Missing all required parameters
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => questions(),  // ❌ ERROR
  ),
);
```

This likely happened because:

1. There were multiple places in the file where `questions` was instantiated
2. One instance was missed during the email parameter threading update
3. The app compiled initially but crashed at runtime when this navigation was triggered

### The Fix

The constructor call needed to pass all three required parameters:

```dart
// CORRECT - All required parameters provided
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => questions(
      username: widget.username,
      email: widget.email,
      password: widget.password,
    ),
  ),
);
```

---

## Complete File Update

**File:** `lib/signUp/bridgetoQ.dart` (around line 236)

**Before:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => questions(),
  ),
);
```

**After:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => questions(
      username: widget.username,
      email: widget.email,
      password: widget.password,
    ),
  ),
);
```

---

## Testing Checklist

### ✅ Pre-Flight Checks

- [ ] All widgets in signup chain have `email` parameter defined
- [ ] All widget constructors require `email` parameter
- [ ] All navigation calls pass `email` parameter
- [ ] All auto-login calls use `email` not `username`

### 🧪 Integration Testing

#### Test 1: Login Flow

1. Launch app on emulator
2. Navigate to login screen
3. Enter **email** (not username) and password
4. Verify successful login
5. Check token stored in SharedPreferences
6. Restart app and verify token persistence

#### Test 2: Registration Flow

1. Start registration from signup screen
2. Fill all required fields (name, email, username, password, dob, gender)
3. Navigate through BridgetoQ screen
4. Complete questions flow (Question1 → Question2)
5. Verify auto-login triggers successfully
6. Check user is redirected to main screen
7. Verify catatan-haid is created

#### Test 3: API Communication

- [ ] Login endpoint: POST `/login` with `{email, password}`
- [ ] Registration endpoint: POST `/register` with `{name, email, username, password, gender, dob}`
- [ ] Token received and stored correctly
- [ ] Bearer token included in authenticated requests
- [ ] Response format matches: `{user: {...}, roles, token}`

---

## API Endpoints Summary

### Authentication Endpoints

| Old Endpoint     | New Endpoint | Method | Request Body                                     |
| ---------------- | ------------ | ------ | ------------------------------------------------ |
| `/users/login`   | `/login`     | POST   | `{email, password}`                              |
| `/users`         | `/register`  | POST   | `{name, email, username, password, gender, dob}` |
| `/users/current` | `/me`        | GET    | Headers: `Bearer {token}`                        |

### Response Formats

**Login Response (New):**

```json
{
  "user": {
    "id": 123,
    "username": "johndoe",
    "email": "john@example.com",
    "name": "John Doe"
  },
  "roles": "user",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Registration Response:**

```json
{
  "user": {
    "id": 124,
    "username": "janedoe",
    "email": "jane@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## Lessons Learned

### 1. **Widget Parameter Threading**

When adding parameters to widget chains, systematically verify:

- Widget class definition has parameter
- Constructor requires parameter
- All navigation calls pass parameter
- Use grep/search to find ALL instantiation points

### 2. **Runtime vs Compile-Time Errors**

- Flutter may compile successfully even with constructor mismatches
- Errors only appear when navigation is triggered at runtime
- Always test all user flows after parameter changes

### 3. **API Contract Changes**

- Email vs username authentication is a breaking change
- Response format changes require careful parsing updates
- Frontend and backend must be synchronized on API spec

### 4. **Multi-File Refactoring**

When changing authentication:

- Update service layer first (auth_service.dart)
- Update all call sites (grep for `.login(`)
- Thread parameters through widget chains
- Update UI labels to match new requirements
- Test complete flows end-to-end

---

## Future Improvements

### 1. **Centralized API Configuration**

Currently only `auth_service.dart` uses `ApiConfig.getUrl()`. Consider migrating all 50+ files with hardcoded URLs to use centralized configuration.

### 2. **Enhanced Error Handling**

Add user-friendly error messages:

- Invalid email format validation
- Wrong password feedback
- Email not registered notification
- Network error handling

### 3. **Type Safety**

Consider using a data class for credentials:

```dart
class AuthCredentials {
  final String email;
  final String password;
  final String? username; // For display

  const AuthCredentials({
    required this.email,
    required this.password,
    this.username,
  });
}
```

### 4. **Automated Testing**

Create integration tests for:

- Complete signup flow
- Login with email
- Token persistence
- Auto-login after registration

---

## Debugging Tips

### Finding Constructor Calls

```bash
# Search for all widget instantiations
grep -r "questions(" lib/

# Search for all navigation calls
grep -r "MaterialPageRoute" lib/signUp/

# Check widget definitions
grep -r "class questions extends" lib/
```

### Common Issues

1. **Missing parameters in navigation**: Use grep to find all `questions(` calls
2. **Wrong parameter names**: Check widget constructor definition
3. **Type mismatches**: Ensure email is String, not dynamic
4. **Null values**: Verify emailController.text is not empty

### Console Debug Logs

Add debug prints to track parameter flow:

```dart
print('[DEBUG] Email passed to questions: ${widget.email}');
print('[DEBUG] Attempting login with email: $email');
print('[AUTH_SERVICE] Login response: ${response.data}');
```

---

## Related Files

### Core Files Modified

- `lib/services/auth_service.dart` - Authentication service
- `lib/login_page.dart` - Login screen
- `lib/tempSignUpPage.dart` - Registration form
- `lib/accountCred.dart` - Alternate registration

### Signup Flow Chain

- `lib/signUp/bridgetoQ.dart` - Bridge screen
- `lib/signUp/questions.dart` - Questions main widget
- `lib/signUp/question1.dart` - First question screen
- `lib/signUp/question2.dart` - Second question screen

### Configuration

- `lib/config/api_config.dart` - API configuration
- `api.json` - OpenAPI 3.1.0 specification

### Documentation

- `API-ANALYSIS-REPORT.md` - Comprehensive API analysis
- `SECURITY-FIX-README.md` - Security updates
- `AUTH-FIX-DOCUMENTATION.md` - This file

---

## Summary

This fix resolved a critical runtime error in the signup flow caused by incomplete parameter threading during the email-based authentication migration. The root cause was a missed constructor call in `bridgetoQ.dart` that needed to pass the newly required `email` parameter to the `questions` widget.

The fix was part of a larger authentication system overhaul to align with new API specifications requiring email-based login instead of username-based login, along with response format changes and registration schema updates.

**Status:** ✅ Fixed  
**Impact:** Critical - Signup flow completely broken  
**Solution:** Added missing parameters to questions() constructor call in bridgetoQ.dart  
**Testing:** Requires full integration testing of signup → auto-login flow

---

## Support

For issues or questions about this fix:

1. Check console logs for detailed error messages
2. Verify API specification matches backend implementation
3. Test with real credentials on emulator
4. Review related documentation files

**Last Updated:** December 2, 2025
