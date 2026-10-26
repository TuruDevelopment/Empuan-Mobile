import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../features/update/update_gate.dart';
import '../services/app_info.dart';
import '../services/auth_service.dart';
import 'app_version_repository.dart';
import 'offline.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code, this.retryable = true, this.retryAfter, this.offline = false});

  /// The server couldn't be reached and nothing was saved for this screen.
  const ApiException.offline([this.message = offlineMessage])
      : statusCode = null,
        code = 'offline',
        retryable = true,
        retryAfter = null,
        offline = true;

  static const offlineMessage = 'You’re offline. Connect to the internet and try again.';

  /// Builds the exception for a non-2xx response. Reads Laravel's
  /// `message`/`errors` and, where the server sends them, `code`, `retryable`
  /// and `retry_after` (seconds, or the Retry-After header).
  factory ApiException.fromResponse(int statusCode, dynamic decoded, {Map<String, String> headers = const {}}) {
    final json = asMap(decoded);
    final code = asString(json['code']);
    final seconds = asInt(json['retry_after'] ?? headers['retry-after'], -1);
    return ApiException(
      _errorMessage(decoded, statusCode),
      statusCode: statusCode,
      code: code.isEmpty ? null : code,
      retryable: json.containsKey('retryable') ? asBool(json['retryable']) : true,
      retryAfter: seconds < 0 ? null : Duration(seconds: seconds),
    );
  }

  final String message;
  final int? statusCode;

  /// Machine-readable reason, e.g. `rate_limited`, when the server sends one.
  final String? code;

  /// False when sending the same request again won't help, e.g. `blocked`.
  final bool retryable;

  /// How long to wait before trying again, for `rate_limited`.
  final Duration? retryAfter;

  /// No response came back: no connection, or the server is unreachable.
  final bool offline;

  /// The backend has no route for this yet (see BACKEND_CHANGES.md). A 404
  /// that carries a [code] is a real "not found", not a missing route.
  bool get notAvailable => code == null && (statusCode == 404 || statusCode == 405 || statusCode == 501);

  @override
  String toString() => message;

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

/// Thin JSON client shared by the feature services.
///
/// Every call sends the bearer token and the app's version headers, signs the
/// user out on 401, shows the update screen on 426, and turns
/// network and server failures into [ApiException] with a message that can be
/// shown to the user as is.
///
/// Signed-in GETs are saved in [OfflineCache]. Without a connection the saved
/// copy comes back instead, and [OfflineStatus] notes that the app is offline.
class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 20);

  /// [cache] false for data that must not sit in the plain-file cache, such as
  /// contacts, which keep their own encrypted copy.
  Future<dynamic> get(String path, {Map<String, String>? query, bool cache = true}) => send('GET', path, query: query, cache: cache);

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
    bool cache = true,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(ApiConfig.getUrl(path)).replace(queryParameters: query == null || query.isEmpty ? null : query);
    final cacheKey = method == 'GET' && authenticated && cache ? uri.toString() : null;
    final status = OfflineStatus.instance;

    // With no network at all, don't wait for a timeout.
    if (status.noNetwork) return _fromCache(cacheKey);

    final request = http.Request(method, uri)
      ..headers.addAll(
        authenticated ? AuthService.getAuthHeaders() : {...AppInfo.headers, 'Content-Type': 'application/json', 'Accept': 'application/json'},
      );
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request).timeout(timeout ?? _timeout));
    } on TimeoutException {
      return _fromCache(cacheKey, message: 'The connection timed out. Check your internet and try again.');
    } catch (_) {
      return _fromCache(cacheKey, message: 'Can’t reach Empuan right now. Check your internet and try again.');
    }
    status.reportReachable();

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

    if (response.statusCode == 426) {
      UpdateGate.require(AppVersionStatus.fromUpgradeRequired(decoded));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response.statusCode, decoded, headers: response.headers);
    }
    if (cacheKey != null) unawaited(OfflineCache.instance.write(cacheKey, decoded));
    return decoded;
  }

  /// The saved copy for [key] when the server can't be reached, or an offline
  /// [ApiException] when there is none.
  Future<dynamic> _fromCache(String? key, {String message = ApiException.offlineMessage}) async {
    final saved = key == null ? null : await OfflineCache.instance.read(key);
    OfflineStatus.instance.reportUnreachable(servedFrom: saved?.savedAt);
    if (saved == null) throw ApiException.offline(message);
    return saved.data;
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
