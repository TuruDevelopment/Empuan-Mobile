import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? token;
  static const String _tokenKey = 'auth_token';

  // Load token from disk on app start
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
  }

  Future<bool> login(
      {required String username, required String password}) async {
    try {
      var response = await Dio().post(
          "http://192.168.8.83:8000/api/users/login",
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {"username": username, 'password': password});

      print('[AUTH_SERVICE] Response status: ${response.statusCode}');
      print('[AUTH_SERVICE] Response data: ${response.data}');

      // API returns: { "data": { "id": 1, "username": "...", "token": "..." } }
      Map obj = response.data;

      // Check if response has data and token
      if (obj['data'] != null && obj['data']['token'] != null) {
        token = obj['data']['token'];

        // Save token to disk for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token!);

        print(
            '[AUTH_SERVICE] ✅ Login successful! Token saved: ${token?.substring(0, 20)}...');
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
