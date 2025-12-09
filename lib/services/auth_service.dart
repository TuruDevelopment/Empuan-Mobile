import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwt_decoder.dart';
import '../config/api_config.dart';
import '../start_page.dart';
import 'api_client.dart';

class AuthService {
  static String? token;
  static const String _tokenKey = 'auth_token';

  /// Get authorization headers with Bearer token
  static Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token', // ← Dengan "Bearer" prefix!
    };
  }

  // Load token from disk on app start
  static Future<void> init() async {
    print('[AUTH_SERVICE] 🔍 Checking SharedPreferences for stored token...');

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);

    print('[AUTH_SERVICE] 📦 Raw value from SharedPreferences:');
    print('[AUTH_SERVICE]    Key: $_tokenKey');
    print('[AUTH_SERVICE]    Value exists: ${storedToken != null}');
    print('[AUTH_SERVICE]    Value length: ${storedToken?.length ?? 0}');

    token = storedToken;

    if (token != null && token!.isNotEmpty) {
      print('[AUTH_SERVICE] ✅ Token loaded from storage');
      print(
          '[AUTH_SERVICE] Token preview: ${token!.substring(0, min(30, token!.length))}...');
      print('[AUTH_SERVICE] Token length: ${token!.length} characters');
    } else {
      print('[AUTH_SERVICE] ❌ No token found in storage');
      print('[AUTH_SERVICE] All keys in SharedPreferences: ${prefs.getKeys()}');
    }
  }

  static int min(int a, int b) => a < b ? a : b;

  Future<bool> login({required String email, required String password}) async {
    print('[AUTH_SERVICE] Starting login for email: $email');
    print('[AUTH_SERVICE] API URL: ${ApiConfig.getUrl(ApiConfig.login)}');

    try {
      // Configure Dio to NOT follow redirects automatically
      final dio = Dio(BaseOptions(
        followRedirects: false,
        validateStatus: (status) => status! < 400, // Accept any status < 400
      ));

      var response = await dio.post(
        ApiConfig.getUrl(ApiConfig.login),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json', // Important for API requests
          },
        ),
        data: {"email": email, 'password': password},
      );

      print('[AUTH_SERVICE] Response status: ${response.statusCode}');
      print('[AUTH_SERVICE] Response data: ${response.data}');
      print('[AUTH_SERVICE] Response type: ${response.data.runtimeType}');

      // API returns: { "user": {...}, "roles": "...", "token": "..." }
      Map obj = response.data;

      // Check if response has token
      if (obj['token'] != null) {
        token = obj['token'];

        final userId = obj['user']?['id'];
        final username = obj['user']?['username'];

        // Save token to disk for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token!);

        print('╔════════════════════════════════════════════════════════╗');
        print('║           ✅ LOGIN SUCCESSFUL                          ║');
        print('╠════════════════════════════════════════════════════════╣');
        print('║  Username: $username');
        print('║  User ID:  $userId');
        print('║  Token:    ${token?.substring(0, 30)}...');
        print('╠════════════════════════════════════════════════════════╣');

        // Decode JWT token to verify user_id inside token
        debugToken(token);

        if (userId == 1 || userId == 2) {
          print('║  ⚠️  WARNING: OLD USER DETECTED!                       ║');
          print(
              '║  ⚠️  User ID $userId is from old system                   ║');
          print(
              '║  ⚠️  Data will be saved with user_id $userId               ║');
          print('║                                                        ║');
          print('║  ✅ Please logout and use:                             ║');
          print('║     - Michael (user_id: 7)                            ║');
          print('║     - Yongky (user_id: 8)                             ║');
        } else {
          print('║  ✅ CORRECT USER! Data will save with user_id $userId     ║');
        }
        print('╚════════════════════════════════════════════════════════╝');

        return true;
      } else {
        print('[AUTH_SERVICE] ❌ Login failed - token not found in response');
        print('[AUTH_SERVICE] Response keys: ${obj.keys.toList()}');
        return false;
      }
    } on DioException catch (e) {
      print('[AUTH_SERVICE] ❌ DioException occurred:');
      print('[AUTH_SERVICE] Status code: ${e.response?.statusCode}');
      print('[AUTH_SERVICE] Response data: ${e.response?.data}');
      print('[AUTH_SERVICE] Error message: ${e.message}');
      print('[AUTH_SERVICE] Error type: ${e.type}');
      return false;
    } on Exception catch (e) {
      print('[AUTH_SERVICE] ❌ Exception occurred: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    print('\n[LOGOUT] ═══════════════════════════════════════════════');
    print('[LOGOUT] 🚪 LOGOUT INITIATED');
    print('[LOGOUT] Stack trace:');
    print(StackTrace.current.toString().split('\n').take(5).join('\n'));
    print('[LOGOUT] ═══════════════════════════════════════════════');

    print('[LOGOUT] Step 1: Clearing token from memory...');
    print(
        '[LOGOUT]    Before: token = ${token?.substring(0, min(20, token?.length ?? 0))}...');

    // Clear token from memory
    token = null;
    print('[LOGOUT]    After: token = $token');

    print('[LOGOUT] Step 2: Clearing token from disk...');
    // Clear token from disk
    final prefs = await SharedPreferences.getInstance();
    final beforeRemove = prefs.getString(_tokenKey);
    print(
        '[LOGOUT]    Before remove: ${beforeRemove?.substring(0, min(20, beforeRemove?.length ?? 0))}...');

    await prefs.remove(_tokenKey);

    final afterRemove = prefs.getString(_tokenKey);
    print('[LOGOUT]    After remove: $afterRemove');
    print('[LOGOUT]    All remaining keys: ${prefs.getKeys()}');

    print('[LOGOUT] ✅ LOGOUT COMPLETE');
    print('[LOGOUT] ═══════════════════════════════════════════════\n');
  }

  /// Handle session expiration - logout and navigate to login with notification
  /// This is called when API returns 401/403
  static Future<void> handleSessionExpired() async {
    print(
        '\n[SESSION_EXPIRED] ═══════════════════════════════════════════════');
    print('[SESSION_EXPIRED] ⚠️ SESSION EXPIRED - AUTO LOGOUT');
    print('[SESSION_EXPIRED] ═══════════════════════════════════════════════');

    // Logout first
    await logout();

    // Navigate to start page with session expired flag
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Use pushAndRemoveUntil to clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const StartPage(sessionExpired: true),
        ),
        (route) => false, // Remove all previous routes
      );
      print('[SESSION_EXPIRED] ✅ Navigated to login page');
    } else {
      print('[SESSION_EXPIRED] ❌ No context available for navigation');
    }

    print(
        '[SESSION_EXPIRED] ═══════════════════════════════════════════════\n');
  }
}
