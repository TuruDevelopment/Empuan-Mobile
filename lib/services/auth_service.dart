import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwt_decoder.dart';
import '../config/api_config.dart';
import '../start_page.dart';
import 'api_client.dart';

class AuthService {
  static String? token;
  static const String _tokenKey = 'auth_token';
  static final _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Get authorization headers with Bearer token
  static Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Load token from disk on app start
  static Future<void> init() async {
    String? storedToken = await _secureStorage.read(key: _tokenKey);

    // One-time migration from SharedPreferences to secure storage.
    if (storedToken == null || storedToken.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_tokenKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: legacyToken);
        await prefs.remove(_tokenKey);
        storedToken = legacyToken;
      }
    }

    token = storedToken;
    debugPrint('[AUTH_SERVICE] Token loaded: ${token != null && token!.isNotEmpty}');
  }

  Future<bool> login({required String email, required String password}) async {
    debugPrint('[AUTH_SERVICE] Login attempt');

    try {
      final dio = Dio(BaseOptions(
        followRedirects: false,
        validateStatus: (status) => status! < 400,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final response = await dio.post(
        ApiConfig.getUrl(ApiConfig.login),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {"email": email, 'password': password},
      );

      debugPrint('[AUTH_SERVICE] Login status: ${response.statusCode}');

      final Map obj = response.data is Map ? response.data as Map : {};

      if (obj['token'] != null) {
        token = obj['token'] as String;

        await _secureStorage.write(key: _tokenKey, value: token);

        debugToken(token);

        debugPrint('[AUTH_SERVICE] Login successful');
        return true;
      }

      debugPrint('[AUTH_SERVICE] Login failed: token missing in response');
      return false;
    } on DioException catch (e) {
      debugPrint('[AUTH_SERVICE] DioException status=${e.response?.statusCode} type=${e.type}');
      return false;
    } on Exception catch (e) {
      debugPrint('[AUTH_SERVICE] Exception type=${e.runtimeType}');
      return false;
    }
  }

  static Future<void> logout() async {
    debugPrint('[LOGOUT] Clearing session');
    token = null;
    await _secureStorage.delete(key: _tokenKey);
    // Also clear any legacy copy.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    debugPrint('[LOGOUT] Done');
  }

  /// Handle session expiration - logout and navigate to login with notification
  /// This is called when API returns 401/403
  static Future<void> handleSessionExpired() async {
    debugPrint('[SESSION_EXPIRED] Auto logout');

    await logout();

    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const StartPage(sessionExpired: true),
        ),
        (route) => false,
      );
    }
  }
}
