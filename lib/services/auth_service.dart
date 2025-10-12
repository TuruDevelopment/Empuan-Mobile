import 'package:dio/dio.dart';

class AuthService {
  static String? token;
  Future<bool> login(
      {required String username, required String password}) async {
    try {
      var response = await Dio().post("http://10.0.2.2:8000/api/users/login",
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: {"username": username, 'password': password});
      Map obj = response.data;
      if (obj["errors"] == false) return false;
      token = obj['data']['token'];
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  static void logout() {
    token = null;
  }
}
