import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which first-run screens this device has shown: "What's new" for
/// people coming from the old app, and the spotlight tour for everyone.
class IntroPrefs {
  /// Accounts created before this were made in the old app, so their owners
  /// get "What's new" even on a fresh install or after their session ran out.
  static final v2Cutoff = DateTime.utc(2026, 11, 1);

  static const _firstLaunchKey = 'app_v2_first_launch_recorded';
  static const _whatsNewDueKey = 'whats_new_v2_due';
  static const whatsNewSeenKey = 'whats_new_v2_seen';
  static const tourDoneKey = 'app_tour_v1_done';

  /// Call on every launch right after the saved session is loaded, before
  /// anything can sign the user out. Only the first launch of this version
  /// counts: a session then means the person used the old app. Fresh installs
  /// have none, so new sign-ups never see "What's new".
  static Future<void> recordFirstLaunch({required bool hadSession}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_firstLaunchKey) ?? false) return;
      await prefs.setBool(_whatsNewDueKey, hadSession);
      await prefs.setBool(_firstLaunchKey, true);
    } catch (_) {
      // Without storage nobody sees "What's new"; the tour still runs.
    }
  }

  /// Due once per device for anyone who used the old app: signed in to it on
  /// this phone, or holding an account older than [v2Cutoff].
  static Future<bool> whatsNewDue({DateTime? accountCreatedAt}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(whatsNewSeenKey) ?? false) return false;
      final oldAccount = accountCreatedAt != null && accountCreatedAt.isBefore(v2Cutoff);
      return oldAccount || (prefs.getBool(_whatsNewDueKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markWhatsNewSeen() => _set(whatsNewSeenKey);

  static Future<bool> tourDone() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(tourDoneKey) ?? false;
    } catch (_) {
      // Better to skip the tour than to show it on every launch.
      return true;
    }
  }

  static Future<void> markTourDone() => _set(tourDoneKey);

  static Future<void> _set(String key) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(key, true);
    } catch (_) {}
  }
}
