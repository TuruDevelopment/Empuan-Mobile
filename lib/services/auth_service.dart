import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwt_decoder.dart';
import '../config/api_config.dart';

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
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
  }

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
    token = null;

    // Clear token from disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
