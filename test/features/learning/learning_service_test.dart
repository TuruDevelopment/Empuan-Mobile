import 'dart:convert';

import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('updates DOB through the user profile endpoint', () async {
    String? method;
    Uri? requestUri;
    Map<String, dynamic>? requestBody;

    final client = MockClient((request) async {
      method = request.method;
      requestUri = request.url;
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'data': {}}), 200);
    });

    await LearningService(client: client).updateDateOfBirth(
      DateTime(2000, 1, 2),
    );

    expect(method, 'PATCH');
    expect(
        requestUri.toString(), '${ApiConfig.baseUrl}${ApiConfig.userProfile}');
    expect(requestBody, {'dob': '2000-01-02'});
  });
}
