import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../services/app_info.dart';
import 'api.dart';

/// What the server says about this build, from `GET /app/version` or from a
/// 426 `update_required` response.
class AppVersionStatus {
  const AppVersionStatus({
    this.updateRequired = false,
    this.updateAvailable = false,
    this.latestBuild = 0,
    this.latestVersion = '',
    this.storeUrl,
    this.title,
    this.message,
  });

  /// Reads the `/app/version` envelope: `{ success, data: { ... } }`.
  factory AppVersionStatus.fromJson(dynamic json) {
    final data = asMap(asMap(json)['data']);
    return AppVersionStatus(
      updateRequired: asBool(data['update_required']),
      updateAvailable: asBool(data['update_available']),
      latestBuild: asInt(data['latest_build']),
      latestVersion: asString(data['latest_version']),
      storeUrl: _text(data['store_url']),
      title: _text(data['title']),
      message: _text(data['message']),
    );
  }

  /// Reads a 426 body: `{ code: update_required, title, message, store_url }`.
  factory AppVersionStatus.fromUpgradeRequired(dynamic json) {
    final body = asMap(json);
    return AppVersionStatus(
      updateRequired: true,
      storeUrl: _text(body['store_url']),
      title: _text(body['title']),
      message: _text(body['message']),
    );
  }

  final bool updateRequired;
  final bool updateAvailable;
  final int latestBuild;
  final String latestVersion;

  /// Null when the server has none, e.g. iOS before the App Store listing.
  final String? storeUrl;
  final String? title;
  final String? message;

  static String? _text(dynamic value) {
    final text = asString(value).trim();
    return text.isEmpty ? null : text;
  }
}

class AppVersionRepository {
  AppVersionRepository({Api? api}) : _api = api ?? Api();

  final Api _api;
  static const _offeredKey = 'update_offer_seen_build';

  /// Asks whether this build must or can update. Returns null on any failure
  /// (offline, slow, or a backend without the route yet) so startup carries
  /// on: a missing answer must never lock anyone out.
  Future<AppVersionStatus?> check({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      final json = await _api.send(
        'GET',
        ApiConfig.appVersion,
        query: {'platform': AppInfo.platform, 'build': '${AppInfo.build}'},
        authenticated: false,
        timeout: timeout,
      );
      return AppVersionStatus.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// The optional update sheet shows once per latest build.
  Future<bool> shouldOffer(AppVersionStatus status) async {
    if (status.updateRequired || !status.updateAvailable) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_offeredKey) != status.latestBuild;
  }

  Future<void> markOffered(AppVersionStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offeredKey, status.latestBuild);
  }
}
