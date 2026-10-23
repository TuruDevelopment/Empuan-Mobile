import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/contacts_repository.dart';

/// State of the SOS flow, shared by the tab bar button, the Home banner and
/// the Safety tab.
///
/// Empuan never sends texts itself. It opens the phone's messages app with the
/// recipients and text filled in, so no SMS permission is needed.
class SosController extends ChangeNotifier {
  SosController._();

  static final SosController instance = SosController._();

  final ContactsRepository _contacts = ContactsRepository(ContactKind.trusted);

  DateTime? _sentAt;
  List<Contact> _alerted = const [];

  bool get active => _sentAt != null;
  DateTime? get sentAt => _sentAt;
  List<Contact> get alerted => _alerted;

  Future<List<Contact>> trustedContacts() => _contacts.list();

  static const _disclosureKey = 'sos_location_disclosure_seen';

  /// Whether the location explanation screen was shown before asking the
  /// system for permission (Google Play prominent disclosure).
  static Future<bool> disclosureSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_disclosureKey) ?? false;

  static Future<void> markDisclosureSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_disclosureKey, true);

  /// Asks for foreground location permission. Returns false if the user
  /// declines or location services are off.
  static Future<bool> requestLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  /// Best-effort current position: a fresh fix within 8 seconds, otherwise
  /// the last known one. Null when location is unavailable.
  Future<Position?> currentPosition() async {
    if (!await hasLocationPermission()) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  static String helpMessage(Position? position) {
    final base = 'I need help. This is an SOS from the Empuan app.';
    if (position == null) return '$base I couldn’t share my location, please call me.';
    final lat = position.latitude.toStringAsFixed(5);
    final lng = position.longitude.toStringAsFixed(5);
    return '$base My location: https://maps.google.com/?q=$lat,$lng';
  }

  static const safeMessage = 'I’m safe now. Thanks for checking on me.';

  /// Opens the messages app addressed to [contacts]. Returns false when no
  /// messages app could be opened.
  static Future<bool> openMessages(List<Contact> contacts, String body) async {
    final numbers = contacts.map((c) => c.phone.replaceAll(RegExp(r'[^0-9+]'), '')).where((n) => n.isNotEmpty).toList();
    if (numbers.isEmpty) return false;
    final encoded = Uri.encodeComponent(body);
    final candidates = [
      Uri.parse('sms:${numbers.join(';')}?body=$encoded'),
      Uri.parse('sms:${numbers.join(',')}?body=$encoded'),
      Uri.parse('smsto:${numbers.join(';')}?body=$encoded'),
    ];
    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
      } catch (_) {
        // Try the next format.
      }
    }
    return false;
  }

  /// Opens the dialer with [number] filled in. Uses ACTION_DIAL, so no call
  /// permission is needed and the user presses call themselves.
  static Future<bool> dial(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    try {
      return await launchUrl(Uri(scheme: 'tel', path: cleaned));
    } catch (_) {
      return false;
    }
  }

  void markSent(List<Contact> contacts) {
    _sentAt = DateTime.now();
    _alerted = contacts;
    notifyListeners();
  }

  void end() {
    _sentAt = null;
    _alerted = const [];
    notifyListeners();
  }
}

String namesList(List<Contact> contacts) {
  final names = contacts.map((c) => c.name).toList();
  if (names.isEmpty) return '';
  if (names.length == 1) return names.first;
  if (names.length == 2) return '${names[0]} and ${names[1]}';
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}
