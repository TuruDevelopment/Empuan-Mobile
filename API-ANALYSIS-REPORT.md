# API Analysis Report

## 📊 Current Status

**Date**: December 2, 2025

### ❌ Issues Found

1. **Base URL Mismatch**

   - **API Spec**: `https://192.168.8.52:8000/api`
   - **Flutter Code**: `http://192.168.1.7:8000/api` (hardcoded in 54+ locations)
   - **Issue**: Wrong IP address and protocol (https vs http)

2. **Endpoint Naming Inconsistencies**

   - **API Spec uses**: `/kontak-palsu`, `/kontak-aman`, `/catatan-haid`, `/suara-puan`, `/ruang-puan`
   - **Flutter code uses**: `/kontakpalsus`, `/kontakamans`, `/catatanhaids`, `/suarapuans`, `/ruangPuans`
   - **Issue**: Kebab-case vs camelCase mismatch

3. **Login Endpoint Different**
   - **API Spec**: `/login` (new auth system)
   - **Flutter code**: `/users/login` (legacy system)
   - **Note**: Both might work, but `/login` is the official endpoint

## 📝 Detailed Endpoint Comparison

### ✅ Correct Endpoints (API Spec)

| Resource          | Endpoint            | Method | Flutter Status            |
| ----------------- | ------------------- | ------ | ------------------------- |
| Auth Login        | `/login`            | POST   | ❌ Using `/users/login`   |
| Auth Register     | `/register`         | POST   | ❌ Using `/users`         |
| User Current      | `/me`               | GET    | ❌ Using `/users/current` |
| Catatan Haid List | `/catatan-haid`     | GET    | ❌ Using `/catatanhaids`  |
| Kontak Palsu List | `/kontak-palsu`     | GET    | ❌ Using `/kontakpalsus`  |
| Kontak Aman List  | `/kontak-aman`      | GET    | ❌ Using `/kontakamans`   |
| Her Voice List    | `/suara-puan`       | GET    | ❌ Using `/suarapuans`    |
| Her Space List    | `/ruang-puan`       | GET    | ❌ Using `/ruangPuans`    |
| For Her List      | `/untuk-puan`       | GET    | ❌ Using `/untukpuans`    |
| Chatbot Send      | `/chatbot/send`     | POST   | ✅ Correct                |
| Chatbot Sessions  | `/chatbot/sessions` | GET    | ✅ Correct                |

### 🔄 Endpoint Mapping Required

| Old (Flutter)         | New (API Spec)         | Files Affected                                                  |
| --------------------- | ---------------------- | --------------------------------------------------------------- |
| `/users/login`        | `/login`               | auth_service.dart                                               |
| `/users`              | `/register`            | tempSignUpPage.dart, accountCred.dart                           |
| `/users/current`      | `/me`                  | HomePage.dart, splash_page.dart, editProfile.dart, etc.         |
| `/catatanhaids`       | `/catatan-haid`        | questions.dart, question2.dart, catatanHaid.dart, HomePage.dart |
| `/kontakpalsus`       | `/kontak-palsu`        | addContact.dart, editContact.dart, contactBox.dart, etc.        |
| `/kontakamans`        | `/kontak-aman`         | addEmergencyContact.dart, editEmergencyContact.dart, etc.       |
| `/suarapuans`         | `/suara-puan`          | suaraPuan.dart, isiSuaraPuan.dart                               |
| `/ruangPuans`         | `/ruang-puan`          | more.dart, commentRuangPuan.dart                                |
| `/untukpuans`         | `/untuk-puan`          | newUntukPuan.dart                                               |
| `/kategorisuarapuans` | `/kategori-suara-puan` | content_suaraPuan.dart                                          |

## 🔧 Recommended Actions

### Priority 1: Create Configuration File ✅

Created `lib/config/api_config.dart` with:

- Centralized base URL
- All endpoint constants
- Helper methods for dynamic endpoints

### Priority 2: Update Base URL

**Option A**: HTTP (development)

```dart
static const String baseUrl = 'http://192.168.8.52:8000/api';
```

**Option B**: HTTPS (production - as per API spec)

```dart
static const String baseUrl = 'https://192.168.8.52:8000/api';
```

### Priority 3: Update All Endpoints

Need to update 54+ files to use:

1. `ApiConfig.baseUrl` instead of hardcoded URLs
2. Correct endpoint names (kebab-case)
3. `ApiConfig` helper methods

## 📋 Files Requiring Updates

### Critical Files (Auth & Core):

- ✅ `lib/config/api_config.dart` - Created
- ⚠️ `lib/services/auth_service.dart` - Update login endpoint
- ⚠️ `lib/services/chatbot_service.dart` - Update base URL
- ⚠️ `lib/splash_page.dart` - Update user current endpoint
- ⚠️ `lib/start_page.dart` - Update base URL

### User Management:

- ⚠️ `lib/tempSignUpPage.dart`
- ⚠️ `lib/accountCred.dart`
- ⚠️ `lib/screens/editProfile.dart`

### Catatan Haid:

- ⚠️ `lib/screens/catatanHaid.dart` (3 occurrences)
- ⚠️ `lib/screens/HomePage.dart` (2 occurrences)
- ⚠️ `lib/signUp/questions.dart` (2 occurrences)
- ⚠️ `lib/signUp/question2.dart` (2 occurrences)

### Kontak System:

- ⚠️ `lib/screens/addContact.dart` (2 occurrences)
- ⚠️ `lib/screens/addEmergencyContact.dart` (2 occurrences)
- ⚠️ `lib/screens/emergencyContact.dart`
- ⚠️ `lib/components/editContact.dart` (2 occurrences)
- ⚠️ `lib/components/editEmergencyContact.dart` (2 occurrences)
- ⚠️ `lib/components/contactBox.dart`
- ⚠️ `lib/components/emergencyContactBox.dart`

### Forum (Her Voice & Her Space):

- ⚠️ `lib/screens/suaraPuan.dart`
- ⚠️ `lib/screens/isiSuaraPuan.dart` (4 occurrences)
- ⚠️ `lib/screens/more.dart` (3 occurrences)
- ⚠️ `lib/screens/commentRuangPuan.dart` (5 occurrences)

### For Her:

- ⚠️ `lib/screens/newUntukPuan.dart`
- ⚠️ `lib/components/content_suaraPuan.dart`

### Questions/Quiz:

- ⚠️ `lib/components/dailyQuiz.dart` (2 occurrences)
- ⚠️ `lib/components/jawabanDailyQuiz.dart` (2 occurrences)

### Navigation:

- ⚠️ `lib/screens/navScreen.dart` (3 occurrences)
- ⚠️ `lib/screens/panggilPuan.dart`

### Others:

- ⚠️ `lib/login_page.dart`
- ⚠️ `lib/services/empuanServices.dart`

## 🚀 Implementation Plan

### Phase 1: Configuration (✅ DONE)

1. Create `api_config.dart` with centralized configuration
2. Define all endpoint constants
3. Add helper methods

### Phase 2: Critical Updates (NEXT)

1. Update auth_service.dart to use `/login` endpoint
2. Update chatbot_service.dart to use ApiConfig
3. Update splash_page.dart to use `/me` endpoint
4. Test authentication flow

### Phase 3: Systematic Updates

1. Update all catatan haid endpoints
2. Update all kontak endpoints
3. Update all forum endpoints
4. Update all For Her endpoints
5. Update quiz endpoints

### Phase 4: Testing

1. Test authentication (login/register/logout)
2. Test period tracking (catatan haid)
3. Test contacts (kontak palsu & aman)
4. Test forum features
5. Test chatbot
6. Test quiz system

## ⚠️ Breaking Changes Alert

**IMPORTANT**: After updating to correct endpoints, users may experience:

1. Login failures if backend isn't updated
2. Data not loading if endpoints don't match
3. 404 errors on old endpoints

**Solution**: Ensure backend supports both:

- New endpoints: `/login`, `/kontak-palsu`, etc.
- Old endpoints: `/users/login`, `/kontakpalsus`, etc.

Or coordinate deployment so both backend and mobile update together.

## 🔐 Security Note

API spec shows `https://` but Flutter code uses `http://`. For production:

- Use HTTPS for secure communication
- Configure SSL certificates properly
- Never send credentials over HTTP in production

## 📱 Testing Checklist

After updates, test:

- [ ] Login with correct credentials
- [ ] Register new user
- [ ] View period tracking data
- [ ] Create fake contact
- [ ] Create emergency contact
- [ ] Post to Her Voice forum
- [ ] Post to Her Space forum
- [ ] View For Her articles
- [ ] Take daily quiz
- [ ] Chat with AI bot
- [ ] Logout

## 🎯 Next Steps

1. **Review IP Address**: Confirm `192.168.8.52` is the correct backend server
2. **Choose Protocol**: Decide between HTTP (dev) or HTTPS (prod)
3. **Update ApiConfig**: Set correct baseUrl in api_config.dart
4. **Mass Update**: Update all 54 files to use ApiConfig
5. **Backend Coordination**: Ensure backend supports new endpoint structure
6. **Test**: Run comprehensive testing after updates

---

**Status**: Configuration created, awaiting approval for mass endpoint updates  
**Risk Level**: HIGH - Will break app if not coordinated with backend  
**Estimated Time**: 2-3 hours for complete update and testing
