import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Global navigator key for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Centralized API client that handles all HTTP requests
/// and automatically handles token expiration (401/403 responses).
class ApiClient {
  static const Duration _defaultTimeout = Duration(seconds: 20);

  /// Make a GET request with automatic token expiration handling
  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final response = await http
        .get(
          Uri.parse(url),
          headers: headers ?? AuthService.getAuthHeaders(),
        )
        .timeout(timeout ?? _defaultTimeout);

    await _handleResponse(response);
    return response;
  }

  /// Make a POST request with automatic token expiration handling
  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: headers ?? AuthService.getAuthHeaders(),
          body: body == null
              ? null
              : (body is String ? body : jsonEncode(body)),
        )
        .timeout(timeout ?? _defaultTimeout);

    await _handleResponse(response);
    return response;
  }

  /// Make a PUT request with automatic token expiration handling
  static Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final response = await http
        .put(
          Uri.parse(url),
          headers: headers ?? AuthService.getAuthHeaders(),
          body: body == null
              ? null
              : (body is String ? body : jsonEncode(body)),
        )
        .timeout(timeout ?? _defaultTimeout);

    await _handleResponse(response);
    return response;
  }

  /// Make a DELETE request with automatic token expiration handling
  static Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final response = await http
        .delete(
          Uri.parse(url),
          headers: headers ?? AuthService.getAuthHeaders(),
        )
        .timeout(timeout ?? _defaultTimeout);

    await _handleResponse(response);
    return response;
  }

  /// Handle API response and check for token expiration
  static Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint('[API_CLIENT] Session invalid (${response.statusCode})');
      await AuthService.handleSessionExpired();
    }
  }
}
