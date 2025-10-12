import 'dart:convert';

import 'package:http/http.dart' as http;

class TumpuanServices {
  static Future<bool> Login(Map body) async {
    final url = 'https://n47101lw-8000.asse.devtunnels.ms/api/users/login';
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body));

    return response.statusCode == 200;
  }
}
