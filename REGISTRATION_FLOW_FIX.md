# Registration Flow Fix - Summary

## Problem
The registration flow was not saving data to the backend because:
1. The registration API call was missing the `app_version` field
2. The onboarding answers were not being submitted to `/api/onboarding/submit`
3. The authentication token was not being passed through the flow
4. The registration logic had been moved to `_unused` folder

## Files Modified

### 1. `lib/signUp/tempSignUpPage.dart` (Restored from `_unused`)
**Changes:**
- Added `app_version: "general"` to registration body
- Updated `RegistrationUser()` to return token and user data
- Changed function signature to return `Future<Map<String, dynamic>?>`
- Updated button handler to await registration and handle success/failure
- Added loading indicator during registration
- Pass token to `questions` page

**Key Code:**
```dart
final body = {
  "name": name,
  "dob": dob,
  "email": email,
  "username": username,
  "password": password,
  "gender": "Perempuan",
  "app_version": "general", // IMPORTANT
};
```

### 2. `lib/signUp/questions.dart`
**Changes:**
- Added `token` parameter to widget
- Added imports for `http`, `api_config`, and `auth_service`
- Added `_submitOnboarding()` method to submit answers to backend
- Updated `_handleNext()` to call `_submitOnboarding()` on final page
- Added proper error handling and loading states
- Store token in `AuthService.token` for future API calls

**API Call:**
```dart
POST /api/onboarding/submit
Headers:
  - Authorization: Bearer {token}
  - Content-Type: application/json
  - Accept: application/json

Body:
{
  "answers": [
    {
      "question_id": 1,
      "option_id": ...,
      "answer_text": null,
      "answer_type": "wellness"
    }
  ],
  "activity_level": "Moderately active",
  "sleep_quality": "No, I sleep well",
  "wellness_concerns": ["Stress management"]
}
```

### 3. `lib/signUp/bridgetoQ.dart`
**Changes:**
- Added `token` parameter to widget
- Pass token to `questions` page

### 4. `lib/signUp/allSetPage.dart`
**Changes:**
- Added `onboardingCompleted` parameter
- Updated UI text based on onboarding status
- Shows "Onboarding Complete" when onboarding is done
- Shows "Registration Complete" for legacy flow

## Registration Flow (Fixed)

```
1. tempSignUpPage.dart
   └─> POST /api/register
       └─> Returns: { token, user }

2. questions.dart
   └─> User answers 4 questions
   └─> On Finish: POST /api/onboarding/submit
       └─> Saves activity_level, sleep_quality, wellness_concerns
       └─> Sets onboarding_completed = true

3. allSetPage.dart
   └─> Shows success message
   └─> User can now login
```

## API Endpoints Used

### Registration
```
POST /api/register
Content-Type: application/json

{
  "name": "Jane Doe",
  "username": "janedoe",
  "email": "jane@example.com",
  "password": "password123",
  "gender": "Perempuan",
  "dob": "1995-05-15",
  "app_version": "general"
}

Response (200/201):
{
  "user": { ... },
  "token": "1|abc123xyz..."
}
```

### Onboarding Submission
```
POST /api/onboarding/submit
Authorization: Bearer {token}
Content-Type: application/json

{
  "answers": [
    {
      "question_id": 1,
      "option_id": 2,
      "answer_text": null,
      "answer_type": "wellness"
    }
  ],
  "activity_level": "Moderately active",
  "sleep_quality": "No, I sleep well",
  "wellness_concerns": ["Stress management"]
}

Response (200/201):
{
  "message": "Onboarding completed successfully",
  "user": {
    "activity_level": "Moderately active",
    "sleep_quality": "No, I sleep well",
    "wellness_concerns": ["Stress management"],
    "app_version": "general",
    "onboarding_completed": true
  }
}
```

## Testing Checklist

- [ ] Register new user with unique email/username
- [ ] Verify registration API returns token
- [ ] Complete all 4 onboarding questions
- [ ] Verify onboarding submission API is called
- [ ] Check backend database for:
  - [ ] User created in `users` table
  - [ ] `app_version` = "general"
  - [ ] `activity_level`, `sleep_quality`, `wellness_concerns` saved
  - [ ] `onboarding_completed` = true
  - [ ] Answers saved in `user_answers` table
- [ ] Login with new credentials
- [ ] Verify token works for authenticated endpoints

## Notes

### Question ID Mapping
The frontend uses local IDs (0, 1, 2, 3) but backend expects actual question/option IDs. You may need to adjust the mapping in `_submitOnboarding()`:

```dart
// Current mapping (may need adjustment based on backend seeders)
{
  'question_id': 1,
  'option_id': selectedActivity['id'] + 1,
}
```

### Better Approach (Recommended)
Fetch questions from backend first:
```dart
GET /api/wellness/questions?type=wellness&limit=4
```

Then use the actual question/option IDs from the response.

### Token Storage
Token is now stored in:
1. `AuthService.token` (memory)
2. Will persist across app restarts via `SharedPreferences` (handled by `AuthService.init()`)

## Backend Requirements

Ensure these endpoints exist and work:
1. `POST /api/register` - Returns user + token
2. `POST /api/onboarding/submit` - Saves onboarding data
3. `GET /api/wellness/questions` - Returns questions (optional, for dynamic questions)

See documentation:
- `REGISTRATION_API_GUIDE.md`
- `WELLNESS_API_DOCUMENTATION.md`
- `QUICK_START_WELLNESS.md`
