import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import 'api.dart';

enum ContactKind {
  /// People who receive the SOS text (`/kontak-aman`).
  trusted,

  /// Names shown on the fake incoming call (`/kontak-palsu`).
  caller,
}

class Contact {
  const Contact({required this.id, required this.name, required this.phone, required this.relation});

  final int id;
  final String name;
  final String phone;
  final String relation;

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: asInt(json['id']),
        name: asString(json['name'], 'Contact'),
        phone: asString(json['phoneNumber'] ?? json['phone_number']),
        relation: asString(json['relation']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phoneNumber': phone, 'relation': relation};
}

/// The last list of each kind of contact, kept encrypted on this phone so SOS
/// and the fake call work without a connection. Erased on sign-out.
class ContactsVault {
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  /// Tests replace the secure storage with a map.
  @visibleForTesting
  static Map<String, String>? memory;

  static String _key(ContactKind kind) => 'offline_contacts_${kind.name}';

  static Future<void> save(ContactKind kind, List<Contact> contacts) async {
    final value = jsonEncode(contacts.map((c) => c.toJson()).toList());
    if (memory != null) {
      memory![_key(kind)] = value;
      return;
    }
    try {
      await _storage.write(key: _key(kind), value: value);
    } catch (_) {}
  }

  /// Null when nothing was saved yet.
  static Future<List<Contact>?> load(ContactKind kind) async {
    try {
      final value = memory != null ? memory![_key(kind)] : await _storage.read(key: _key(kind));
      if (value == null) return null;
      return asMapList(jsonDecode(value)).map(Contact.fromJson).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    for (final kind in ContactKind.values) {
      if (memory != null) {
        memory!.remove(_key(kind));
        continue;
      }
      try {
        await _storage.delete(key: _key(kind));
      } catch (_) {}
    }
  }

  /// Bytes used, for the storage breakdown in settings.
  static Future<int> size() async {
    var total = 0;
    for (final kind in ContactKind.values) {
      try {
        final value = memory != null ? memory![_key(kind)] : await _storage.read(key: _key(kind));
        total += value == null ? 0 : utf8.encode(value).length;
      } catch (_) {}
    }
    return total;
  }
}

class ContactsRepository {
  ContactsRepository(this.kind, {Api? api}) : _api = api ?? Api();

  final ContactKind kind;
  final Api _api;

  String get _base => kind == ContactKind.trusted ? ApiConfig.kontakAman : ApiConfig.kontakPalsu;

  /// From the server when it answers, which also refreshes the saved copy;
  /// otherwise the saved copy.
  Future<List<Contact>> list() async {
    try {
      final contacts = asMapList(await _api.get(_base, cache: false)).map(Contact.fromJson).toList();
      await ContactsVault.save(kind, contacts);
      return contacts;
    } on ApiException catch (e) {
      if (!e.offline) rethrow;
      final saved = await ContactsVault.load(kind);
      if (saved == null) rethrow;
      return saved;
    }
  }

  /// The copy saved on this phone, without asking the server.
  Future<List<Contact>?> saved() => ContactsVault.load(kind);

  Future<void> create({required String name, required String phone, required String relation}) {
    return _api.post(_base, body: {'name': name, 'phoneNumber': phone, 'relation': relation});
  }

  Future<void> update(int id, {required String name, required String phone, required String relation}) {
    return _api.put('$_base/$id', body: {'name': name, 'phoneNumber': phone, 'relation': relation});
  }

  Future<void> delete(int id) => _api.delete('$_base/$id');
}
