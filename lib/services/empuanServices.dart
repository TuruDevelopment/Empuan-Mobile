import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:Empuan/config/api_config.dart';

class EmpuanServices {
  static Future<bool> Login(Map body) async {
    final url = '${ApiConfig.baseUrl}/login';
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body));

    return response.statusCode == 200;
  }
}
