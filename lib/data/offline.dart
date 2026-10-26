import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contacts_repository.dart';

/// What a saved response belongs to, for the storage breakdown in settings.
enum OfflineSection { courses, articles, other }

class CachedResponse {
  const CachedResponse(this.data, this.savedAt);

  final dynamic data;
  final DateTime savedAt;
}

/// Server responses saved on this phone, so screens can show the last copy
/// without a connection.
///
/// Lives in the app's private support folder, which other apps can't read.
/// Erased on sign-out and account deletion. Every call swallows storage
/// errors: a missing cache only means the screen needs the internet.
class OfflineCache {
  OfflineCache._();

  static final instance = OfflineCache._();

  /// Tests point this at a temporary folder.
  @visibleForTesting
  static Directory? directoryOverride;

  Directory? _dir;

  Future<Directory?> _root() async {
    if (directoryOverride != null) return directoryOverride;
    if (_dir != null) return _dir;
    try {
      _dir = Directory('${(await getApplicationSupportDirectory()).path}/offline');
      return _dir;
    } catch (_) {
      return null;
    }
  }

  static OfflineSection sectionFor(String key) {
    if (key.contains('/learning')) return OfflineSection.courses;
    if (key.contains('suara-puan')) return OfflineSection.articles;
    return OfflineSection.other;
  }

  Future<File?> _file(String key) async {
    final root = await _root();
    if (root == null) return null;
    return File('${root.path}/${sectionFor(key).name}_${_hash(key)}.json');
  }

  Future<void> write(String key, dynamic data, {DateTime? now}) async {
    try {
      final file = await _file(key);
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'saved_at': (now ?? DateTime.now()).toIso8601String(), 'data': data}));
    } catch (_) {}
  }

  Future<CachedResponse?> read(String key) async {
    try {
      final file = await _file(key);
      if (file == null || !await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map) return null;
      final savedAt = DateTime.tryParse('${json['saved_at']}');
      if (savedAt == null) return null;
      return CachedResponse(json['data'], savedAt);
    } catch (_) {
      return null;
    }
  }

  /// Bytes on disk per section.
  Future<Map<OfflineSection, int>> sizes() async {
    final sizes = {for (final s in OfflineSection.values) s: 0};
    try {
      final root = await _root();
      if (root == null || !await root.exists()) return sizes;
      await for (final entity in root.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final section = OfflineSection.values.firstWhere((s) => name.startsWith('${s.name}_'), orElse: () => OfflineSection.other);
        sizes[section] = sizes[section]! + await entity.length();
      }
    } catch (_) {}
    return sizes;
  }

  /// How many saved responses each section holds.
  Future<Map<OfflineSection, int>> counts() async {
    final counts = {for (final s in OfflineSection.values) s: 0};
    try {
      final root = await _root();
      if (root == null || !await root.exists()) return counts;
      await for (final entity in root.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        for (final s in OfflineSection.values) {
          if (name.startsWith('${s.name}_')) counts[s] = counts[s]! + 1;
        }
      }
    } catch (_) {}
    return counts;
  }

  Future<void> clear() async {
    try {
      final root = await _root();
      if (root != null && await root.exists()) await root.delete(recursive: true);
    } catch (_) {}
  }

  /// Two 32-bit hashes (FNV-1a and djb2), enough to turn a URL into a safe,
  /// stable file name.
  static String _hash(String input) {
    var fnv = 0x811c9dc5;
    var djb = 5381;
    for (final unit in utf8.encode(input)) {
      fnv = ((fnv ^ unit) * 0x01000193) & 0xFFFFFFFF;
      djb = ((djb * 33) + unit) & 0xFFFFFFFF;
    }
    return '${fnv.toRadixString(16)}${djb.toRadixString(16)}';
  }
}

/// Whether Empuan can reach its server right now, as far as the app can tell.
///
/// Offline when the phone has no network at all, or when the last request
/// couldn't reach the server. The first successful response clears it.
class OfflineStatus extends ChangeNotifier {
  OfflineStatus._();

  static final instance = OfflineStatus._();

  bool _noNetwork = false;
  bool _unreachable = false;
  DateTime? _savedAt;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get offline => _noNetwork || _unreachable;

  /// True when the phone reports no network, so requests can fail fast.
  bool get noNetwork => _noNetwork;

  /// When the oldest saved copy shown since going offline was saved.
  DateTime? get savedAt => offline ? _savedAt : null;

  /// Fires when the connection comes back, so screens can reload.
  final ValueNotifier<int> reconnects = ValueNotifier(0);

  Future<void> start() async {
    if (_sub != null) return;
    try {
      final connectivity = Connectivity();
      _apply(await connectivity.checkConnectivity());
      _sub = connectivity.onConnectivityChanged.listen(_apply);
    } catch (_) {
      // No plugin (tests) or no answer: rely on request failures alone.
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final none = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (none == _noNetwork) return;
    final wasOffline = offline;
    _noNetwork = none;
    if (!none) _unreachable = false;
    if (wasOffline && !offline) _cameBack();
    notifyListeners();
  }

  /// A response came back from the server.
  void reportReachable() {
    if (!_unreachable && !_noNetwork) return;
    final wasOffline = offline;
    _unreachable = false;
    _noNetwork = false;
    if (wasOffline) _cameBack();
    notifyListeners();
  }

  /// A request couldn't reach the server. [servedFrom] is when the saved copy
  /// shown instead was saved, if there was one.
  void reportUnreachable({DateTime? servedFrom}) {
    final changed = !_unreachable;
    _unreachable = true;
    if (servedFrom != null && (_savedAt == null || servedFrom.isBefore(_savedAt!))) {
      _savedAt = servedFrom;
      notifyListeners();
    } else if (changed) {
      notifyListeners();
    }
  }

  void _cameBack() {
    _savedAt = null;
    reconnects.value++;
  }

  /// True on Wi-Fi or Ethernet, for "Download on Wi-Fi only".
  Future<bool> onWifi() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }

  /// Stops listening for network changes. The app listens for its lifetime.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  @visibleForTesting
  void debugSetNoNetwork(bool value) => _apply(value ? const [ConnectivityResult.none] : const [ConnectivityResult.wifi]);

  @visibleForTesting
  void reset() {
    _noNetwork = false;
    _unreachable = false;
    _savedAt = null;
  }
}

/// The "Saved for offline" switches.
class OfflinePrefs {
  static const autoSaveKey = 'offline_autosave_courses';
  static const wifiOnlyKey = 'offline_wifi_only';

  static Future<bool> autoSaveCourses() async => _get(autoSaveKey, true);
  static Future<bool> wifiOnly() async => _get(wifiOnlyKey, false);
  static Future<void> setAutoSaveCourses(bool value) => _set(autoSaveKey, value);
  static Future<void> setWifiOnly(bool value) => _set(wifiOnlyKey, value);

  static Future<bool> _get(String key, bool fallback) async {
    try {
      return (await SharedPreferences.getInstance()).getBool(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> _set(String key, bool value) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(key, value);
    } catch (_) {}
  }
}

/// Saved pictures: article and course images, kept by the image cache.
class OfflineImages {
  /// Off in tests, where the image cache's file plugins don't exist.
  @visibleForTesting
  static bool enabled = true;

  static Future<int> size() async {
    if (!enabled) return 0;
    try {
      final dir = Directory('${(await getTemporaryDirectory()).path}/${DefaultCacheManager.key}');
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Downloads [url] into the image cache so it shows offline later.
  static Future<void> prefetch(String? url) async {
    if (!enabled || url == null || !url.startsWith('http')) return;
    try {
      await DefaultCacheManager().getSingleFile(url);
    } catch (_) {}
  }

  static Future<void> clear() async {
    if (!enabled) return;
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
  }
}

/// Everything saved for offline use. Sign-out and account deletion erase it
/// all; "Clear saved content" keeps the trusted contacts so SOS still works.
Future<void> clearOfflineData({bool keepContacts = false}) async {
  await OfflineCache.instance.clear();
  await OfflineImages.clear();
  if (!keepContacts) await ContactsVault.clear();
}

/// "18 MB", "450 KB", "2 KB".
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    final mb = bytes / (1024 * 1024);
    return '${mb >= 10 ? mb.round() : mb.toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).ceil().clamp(bytes > 0 ? 1 : 0, 1023)} KB';
}
