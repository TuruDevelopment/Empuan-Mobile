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
    expect(requestUri.toString(), '${ApiConfig.baseUrl}${ApiConfig.userProfile}');
    expect(requestBody, {'dob': '2000-01-02'});
  });

  test('reads earned certificates and skips malformed entries', () async {
    Uri? requestUri;
    final client = MockClient((request) async {
      requestUri = request.url;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'public_id': 'abc',
              'certificate_number': 'EMP-2026-00123',
              'recipient_name': 'Ayu Lestari',
              'course_title': 'Budgeting basics',
              'course_slug': 'budgeting',
              'issued_at': '2026-10-20T08:00:00Z',
            },
            'not a certificate',
            {
              'certificate_number': 'EMP-2026-00124',
              'course': {'slug': 'salary', 'title': 'Negotiating your salary'},
            },
          ],
        }),
        200,
      );
    });

    final certificates = await LearningService(client: client).getCertificates();

    expect(requestUri.toString(), '${ApiConfig.baseUrl}${ApiConfig.learningCertificates}');
    expect(certificates, hasLength(2));
    expect(certificates.first.courseSlug, 'budgeting');
    expect(certificates.first.issuedAt, DateTime.utc(2026, 10, 20, 8));
    expect(certificates.last.courseSlug, 'salary');
    expect(certificates.last.courseTitle, 'Negotiating your salary');
  });

  test('treats an unexpected certificates payload as an empty list', () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({
          'data': {'total': 0}
        }),
        200));

    expect(await LearningService(client: client).getCertificates(), isEmpty);
  });
}
