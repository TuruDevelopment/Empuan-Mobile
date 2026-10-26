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
}

class ContactsRepository {
  ContactsRepository(this.kind, {Api? api}) : _api = api ?? Api();

  final ContactKind kind;
  final Api _api;

  String get _base => kind == ContactKind.trusted ? ApiConfig.kontakAman : ApiConfig.kontakPalsu;

  Future<List<Contact>> list() async => asMapList(await _api.get(_base)).map(Contact.fromJson).toList();

  Future<void> create({required String name, required String phone, required String relation}) {
    return _api.post(_base, body: {'name': name, 'phoneNumber': phone, 'relation': relation});
  }

  Future<void> update(int id, {required String name, required String phone, required String relation}) {
    return _api.put('$_base/$id', body: {'name': name, 'phoneNumber': phone, 'relation': relation});
  }

  Future<void> delete(int id) => _api.delete('$_base/$id');
}
