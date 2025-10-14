import 'dart:convert';

import 'package:http/http.dart' as http;

class EmpuanServices {
  static Future<bool> Login(Map body) async {
    final url = 'http://192.168.8.83:8000/api/api/users/login';
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body));

    return response.statusCode == 200;
  }
}
