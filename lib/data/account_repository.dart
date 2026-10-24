import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../ui/em_ui.dart' show apiDate, parseDate;
import 'api.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.dob,
    this.interests = const [],
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final DateTime? dob;

  /// Picked topics plus the free-text "something else", as InterestsScreen expects.
  final List<String> interests;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: asInt(json['id']),
        name: asString(json['name'], 'Empuan member'),
        username: asString(json['username']),
        email: asString(json['email']),
        dob: parseDate(json['dob']),
        interests: [
          if (json['interests'] is List) ...(json['interests'] as List).map((e) => '$e').where((e) => e.isNotEmpty),
          if (asString(json['interests_other']).trim().isNotEmpty) asString(json['interests_other']).trim(),
        ],
      );

  UserProfile withInterests(List<String> value) =>
      UserProfile(id: id, name: name, username: username, email: email, dob: dob, interests: value);
}

/// Holds the signed-in user so screens can show their name without refetching.
class Session {
  static final ValueNotifier<UserProfile?> user = ValueNotifier(null);
}

class AccountRepository {
  AccountRepository({Api? api}) : _api = api ?? Api();

  final Api _api;

  Future<UserProfile> fetchMe() async {
    final json = asMap(await _api.get(ApiConfig.me));
    final profile = UserProfile.fromJson(asMap(json['user'] ?? json['data']));
    Session.user.value = profile;
    return profile;
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String username,
    required String email,
    DateTime? dob,
  }) async {
    await _api.patch(ApiConfig.userProfile, body: {
      'name': name,
      'username': username,
      'email': email,
      if (dob != null) 'dob': apiDate(dob),
    });
    return fetchMe();
  }

  Future<void> changePassword({required String current, required String next}) {
    return _api.post(ApiConfig.changePassword, body: {
      'current_password': current,
      'password': next,
      'password_confirmation': next,
    });
  }

  /// Creates the account and keeps the user signed in.
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required DateTime dob,
  }) async {
    final json = asMap(await _api.send(
      'POST',
      ApiConfig.register,
      authenticated: false,
      body: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'dob': apiDate(dob),
        'gender': 'Perempuan',
        'app_version': 'general',
      },
    ));
    final token = json['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const ApiException('Your account was created, but we couldn’t sign you in. Please log in.');
    }
    await AuthService.saveToken(token);
  }

  Future<void> requestPasswordReset(String email) {
    return _api.send('POST', ApiConfig.forgotPassword, authenticated: false, body: {'email': email});
  }

  Future<void> deleteAccount(String password) async {
    await _api.post(ApiConfig.deleteAccount, body: {'password': password});
    await AuthService.logout();
    Session.user.value = null;
  }

  Future<void> saveInterests(List<String> interests, {String? other}) async {
    final extra = other?.trim() ?? '';
    await _api.post(ApiConfig.onboardingInterests, body: {
      'interests': interests,
      if (extra.isNotEmpty) 'other': extra,
    });
    Session.user.value = Session.user.value?.withInterests([...interests, if (extra.isNotEmpty) extra]);
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout);
    } catch (_) {
      // Signing out locally is enough if the server call fails.
    }
    await AuthService.logout();
    Session.user.value = null;
  }
}
