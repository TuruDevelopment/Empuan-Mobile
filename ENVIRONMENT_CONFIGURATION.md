# Environment Configuration Guide

## Overview

The Empuan Mobile app now uses a centralized configuration system for managing API URLs across different environments (development, staging, production).

## Configuration File

**Location:** `lib/config/api_config.dart`

The API configuration automatically detects the environment and uses the appropriate base URL:

```dart
class ApiConfig {
  // Environment: 'development', 'staging', or 'production'
  static const String _environment = String.fromEnvironment('ENV', defaultValue: 'development');

  // Base URLs
  static const String _developmentUrl = 'http://192.168.1.5:8000/api';
  static const String _productionUrl = 'https://api.empuan.com/api';
  static const String _stagingUrl = 'https://staging-api.empuan.com/api';

  // Dynamically get base URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return _productionUrl;
      case 'staging':
        return _stagingUrl;
      case 'development':
      default:
        return _developmentUrl;
    }
  }
}
```

## Running the App

### Development (Default)

```bash
flutter run
# or explicitly
flutter run --dart-define=ENV=development
```

Uses: `http://192.168.1.5:8000/api`

### Staging

```bash
flutter run --dart-define=ENV=staging
```

Uses: `https://staging-api.empuan.com/api`

### Production

```bash
flutter run --dart-define=ENV=production
```

Uses: `https://api.empuan.com/api`

## Building for Release

### Android APK

```bash
# Development
flutter build apk --dart-define=ENV=development

# Staging
flutter build apk --dart-define=ENV=staging

# Production
flutter build apk --dart-define=ENV=production
```

### iOS

```bash
# Production
flutter build ios --dart-define=ENV=production
```

### App Bundle (for Google Play)

```bash
flutter build appbundle --dart-define=ENV=production
```

## Usage in Code

All API calls now use the centralized configuration:

```dart
import 'package:Empuan/config/api_config.dart';

// Get full API endpoint
final url = '${ApiConfig.baseUrl}/ruang-puan';

// Example: Fetching posts
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/ruang-puan'),
  headers: AuthService.getAuthHeaders(),
);
```

## Utility Methods

The `ApiConfig` class provides several utility methods:

```dart
// Get current environment name
String env = ApiConfig.environment; // 'development', 'staging', or 'production'

// Check if production
bool isProd = ApiConfig.isProduction;

// Get full URL from endpoint
String fullUrl = ApiConfig.getUrl('/ruang-puan');
// Returns: 'http://192.168.1.5:8000/api/ruang-puan' (in dev)
```

## Available Endpoints

The config file includes pre-defined endpoint paths:

### Authentication

- `ApiConfig.login` → `/login`
- `ApiConfig.register` → `/register`
- `ApiConfig.me` → `/me`
- `ApiConfig.logout` → `/logout`

### Period Tracking

- `ApiConfig.catatanHaid` → `/catatan-haid`

### Contacts

- `ApiConfig.kontakPalsu` → `/kontak-palsu`
- `ApiConfig.kontakAman` → `/kontak-aman`

### Forums

- `ApiConfig.ruangPuan` → `/ruang-puan`
- `ApiConfig.suaraPuan` → `/suara-puan`
- `ApiConfig.ruangPuanComments(id)` → `/ruang-puan/{id}/comments`
- `ApiConfig.suaraPuanComments(id)` → `/suara-puan/{id}/comments`

### Recommendations

- `ApiConfig.untukPuan` → `/untuk-puan`

### Questions

- `ApiConfig.questionsEndpoint` → `/questions`
- `ApiConfig.questionOptions(id)` → `/questions/{id}/options`

### Chatbot

- `ApiConfig.chatbotSend` → `/chatbot/send`
- `ApiConfig.chatbotSessions` → `/chatbot/sessions`
- `ApiConfig.chatbotNewSession` → `/chatbot/sessions/new`

## Changing URLs

### For Development

Edit the `_developmentUrl` constant in `lib/config/api_config.dart`:

```dart
static const String _developmentUrl = 'http://YOUR_LOCAL_IP:8000/api';
```

### For Production

Update the `_productionUrl` constant with your production API URL:

```dart
static const String _productionUrl = 'https://api.empuan.com/api';
```

### For Staging

Update the `_stagingUrl` constant:

```dart
static const String _stagingUrl = 'https://staging-api.empuan.com/api';
```

## Testing Different Environments

### In VS Code

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Development",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=development"]
    },
    {
      "name": "Staging",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=staging"]
    },
    {
      "name": "Production",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=production"]
    }
  ]
}
```

### In Android Studio

1. Edit Run Configuration
2. Add to "Additional run args": `--dart-define=ENV=production`

## Debugging

To verify which environment is active, check the console output:

```dart
print('Current environment: ${ApiConfig.environment}');
print('API Base URL: ${ApiConfig.baseUrl}');
print('Is Production: ${ApiConfig.isProduction}');
```

## Migration Notes

✅ **All hardcoded URLs have been replaced** with `${ApiConfig.baseUrl}` references

The following files were updated:

- All screens in `lib/screens/`
- All components in `lib/components/`
- Auth service and other services
- Sign-up flow files

## Best Practices

1. ✅ **Always use** `ApiConfig.baseUrl` instead of hardcoding URLs
2. ✅ **Never commit** production URLs in development code
3. ✅ **Use environment variables** for sensitive configuration
4. ✅ **Test** each environment before release
5. ✅ **Document** API changes in the team

## Troubleshooting

### "Connection refused" error

- Check that the API server is running
- Verify the IP address is correct for your network
- Ensure your device/emulator can reach the server

### "Invalid host" error

- Make sure you're using the correct environment flag
- Check that the URL doesn't have trailing slashes

### API returns 404

- Verify the endpoint path is correct
- Check that the base URL includes `/api` if needed

## Security Notes

⚠️ **Important for Production:**

1. Use HTTPS URLs only in production
2. Never log sensitive data in production builds
3. Implement certificate pinning for additional security
4. Use secure token storage (flutter_secure_storage)

## Next Steps

Consider implementing:

1. **Environment-specific app flavors** (Android/iOS)
2. **Remote configuration** (Firebase Remote Config)
3. **Feature flags** per environment
4. **Automated environment detection** based on build type

---

**Last Updated:** December 6, 2025  
**Version:** 1.0.0
