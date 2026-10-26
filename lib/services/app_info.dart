import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// This build's platform, version and build number. Every API request sends
/// them, so the server can tell this app from the released 1.1.0 one (which
/// sends none) and ask builds below its minimum to update.
class AppInfo {
  /// `android` or `ios`, as the version contract names them.
  static String get platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Fallbacks match pubspec.yaml and are only used if [load] fails.
  static String version = '2.0.0';
  static int build = 16;

  /// Reads the real values from the installed package. Call before runApp.
  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) version = info.version;
      build = int.tryParse(info.buildNumber) ?? build;
    } catch (_) {
      // Keep the fallbacks; a missing header would be worse than a stale one.
    }
  }

  static Map<String, String> get headers => {
        'X-App-Platform': platform,
        'X-App-Version': version,
        'X-App-Build': '$build',
      };
}
