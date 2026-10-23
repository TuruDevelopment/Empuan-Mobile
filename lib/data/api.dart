import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// The backend has no route for this yet (see BACKEND_CHANGES.md).
  bool get notAvailable => statusCode == 404 || statusCode == 405 || statusCode == 501;

  @override
  String toString() => message;
}

/// Thin JSON client shared by the feature services.
///
/// Every call sends the bearer token, signs the user out on 401, and turns
/// network and server failures into [ApiException] with a message that can be
/// shown to the user as is.
class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 20);

  Future<dynamic> get(String path, {Map<String, String>? query}) => send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) => send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) => send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) => send('PATCH', path, body: body);

  Future<dynamic> delete(String path, {Object? body}) => send('DELETE', path, body: body);

  Future<dynamic> send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse(ApiConfig.getUrl(path)).replace(queryParameters: query == null || query.isEmpty ? null : query);
    final request = http.Request(method, uri)
      ..headers.addAll(
        authenticated
            ? AuthService.getAuthHeaders()
            : const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(_timeout));
    } on TimeoutException {
      throw const ApiException('The connection timed out. Check your internet and try again.');
    } catch (_) {
      throw const ApiException('Can’t reach Empuan right now. Check your internet and try again.');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode == 401 && authenticated) {
      await AuthService.handleSessionExpired();
      throw const ApiException('Your session has ended. Please log in again.', statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(decoded, response.statusCode), statusCode: response.statusCode);
    }
    return decoded;
  }

  static String _errorMessage(dynamic decoded, int status) {
    if (decoded is Map) {
      final errors = decoded['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    if (status >= 500) return 'Something went wrong on our side. Please try again in a moment.';
    if (status == 404) return 'This isn’t available yet.';
    return 'Something went wrong. Please try again.';
  }
}

/// Helpers for reading loosely typed JSON.
Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return <String, dynamic>{};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is Map && value['data'] != null) value = value['data'];
  if (value is List) return value.map(asMap).toList();
  return const [];
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool asBool(dynamic value) => value == true || value == 1 || value == '1' || value == 'true';

String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}
