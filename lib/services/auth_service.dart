import 'package:dio/dio.dart';

class AuthService {
  static String? token;
  Future<bool> login(
      {required String username, required String password}) async {
    try {
      var response = await Dio().post(
          "http://192.168.8.96:8000/api/users/login",
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {"username": username, 'password': password});

      print('[AUTH_SERVICE] Response status: ${response.statusCode}');
      print('[AUTH_SERVICE] Response data: ${response.data}');

      // API returns: { "data": { "id": 1, "username": "...", "token": "..." } }
      Map obj = response.data;

      // Check if response has data and token
      if (obj['data'] != null && obj['data']['token'] != null) {
        token = obj['data']['token'];
        print(
            '[AUTH_SERVICE] ✅ Login successful! Token: ${token?.substring(0, 20)}...');
        return true;
      } else {
        print('[AUTH_SERVICE] ❌ Login failed - token not found in response');
        return false;
      }
    } on Exception catch (_) {
      return false;
    }
  }

  static void logout() {
    token = null;
  }
}
