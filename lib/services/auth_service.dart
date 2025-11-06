import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwt_decoder.dart';

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

  Future<bool> login(
      {required String username, required String password}) async {
    try {
      var response = await Dio().post(
          "http://192.168.8.48:8000/api/users/login",
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {"username": username, 'password': password});

      print('[AUTH_SERVICE] Response status: ${response.statusCode}');
      print('[AUTH_SERVICE] Response data: ${response.data}');

      // API returns: { "data": { "id": 1, "username": "...", "token": "..." } }
      Map obj = response.data;

      // Check if response has data and token
      if (obj['data'] != null && obj['data']['token'] != null) {
        token = obj['data']['token'];

        final userId = obj['data']['id'];
        final username = obj['data']['username'];

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
        return false;
      }
    } on Exception catch (_) {
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
