import 'dart:convert';
import 'dart:io';

import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/data/api.dart';
import 'package:Empuan/data/contacts_repository.dart';
import 'package:Empuan/data/offline.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/offline/offline_banner.dart';
import 'package:Empuan/features/safety/sos_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A client that answers [body] until [online] is turned off, then fails like
/// a phone without signal.
class _Phone {
  bool online = true;
  Object body = {'data': []};
  int calls = 0;

  late final client = MockClient((request) async {
    calls++;
    if (!online) throw const SocketException('No route to host');
    return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
  });
}

Position _position(DateTime at) => Position(
      latitude: -6.2,
      longitude: 106.8,
      timestamp: at,
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  setUp(() async {
    OfflineStatus.instance.reset();
    await OfflineCache.instance.clear();
    ContactsVault.memory = {};
  });

  group('Api offline', () {
    test('shows the saved copy when the server can’t be reached', () async {
      final phone = _Phone()
        ..body = {
          'data': [
            {'id': 1, 'title': 'Saved article'}
          ]
        };
      final api = Api(client: phone.client);

      await api.get(ApiConfig.suaraPuan);
      // The write is fire-and-forget; give it a moment.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(OfflineStatus.instance.offline, isFalse);

      phone.online = false;
      final saved = await api.get(ApiConfig.suaraPuan);
      expect(asMapList(saved).single['title'], 'Saved article');
      expect(OfflineStatus.instance.offline, isTrue);
      expect(OfflineStatus.instance.savedAt, isNotNull);

      phone.online = true;
      await api.get(ApiConfig.suaraPuan);
      expect(OfflineStatus.instance.offline, isFalse, reason: 'the first answer from the server clears it');
    });

    test('without a saved copy it says the phone is offline', () async {
      final phone = _Phone()..online = false;
      final api = Api(client: phone.client);
      await expectLater(
        api.get(ApiConfig.ruangPuan),
        throwsA(isA<ApiException>().having((e) => e.offline, 'offline', isTrue)),
      );
    });

    test('posts are never answered from the cache', () async {
      final phone = _Phone()..online = false;
      final api = Api(client: phone.client);
      await expectLater(
        api.post(ApiConfig.ruangPuan, body: {'threadName': 'hi'}),
        throwsA(isA<ApiException>().having((e) => e.offline, 'offline', isTrue)),
      );
    });

    test('with no network at all it doesn’t wait for the server', () async {
      final phone = _Phone();
      final api = Api(client: phone.client);
      await api.get(ApiConfig.suaraPuan);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final before = phone.calls;

      OfflineStatus.instance.reportUnreachable();
      // Simulates the system saying there is no network.
      OfflineStatus.instance.debugSetNoNetwork(true);
      await api.get(ApiConfig.suaraPuan);
      expect(phone.calls, before, reason: 'served from the cache without a request');
      OfflineStatus.instance.debugSetNoNetwork(false);
    });
  });

  group('Courses offline', () {
    test('a lesson opened online can be read offline', () async {
      final phone = _Phone()
        ..body = {
          'data': {'id': 7, 'slug': 'budget', 'title': 'The 50/30/20 split', 'type': 'article'}
        };
      final learning = LearningService(client: phone.client);
      expect((await learning.getLesson(7)).title, 'The 50/30/20 split');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      phone.online = false;
      expect((await learning.getLesson(7)).title, 'The 50/30/20 split');
      await expectLater(
        learning.getLesson(8),
        throwsA(isA<LearningApiException>().having((e) => e.offline, 'offline', isTrue)),
      );
    });
  });

  group('Trusted contacts offline', () {
    test('are saved when loaded and used when the server can’t be reached', () async {
      final phone = _Phone()
        ..body = {
          'data': [
            {'id': 1, 'name': 'Ibu', 'phoneNumber': '081234567890', 'relation': 'Mother'},
          ],
        };
      final repo = ContactsRepository(ContactKind.trusted, api: Api(client: phone.client));
      expect((await repo.list()).single.name, 'Ibu');

      phone.online = false;
      final offline = await repo.list();
      expect(offline.single.phone, '081234567890');
      expect((await repo.saved())!.single.name, 'Ibu');
    });

    test('never go into the plain-file cache', () async {
      final phone = _Phone()..body = {'data': []};
      await ContactsRepository(ContactKind.trusted, api: Api(client: phone.client)).list();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await OfflineCache.instance.read(Uri.parse(ApiConfig.getUrl(ApiConfig.kontakAman)).toString()), isNull);
    });

    test('signing out erases them, clearing saved content keeps them', () async {
      await ContactsVault.save(ContactKind.trusted, const [Contact(id: 1, name: 'Ibu', phone: '0812', relation: 'Mother')]);
      await OfflineCache.instance.write('https://empuanapp.id/api/suara-puan', {'data': []});

      await clearOfflineData(keepContacts: true);
      expect(await ContactsVault.load(ContactKind.trusted), isNotNull);
      expect(await OfflineCache.instance.read('https://empuanapp.id/api/suara-puan'), isNull);

      await clearOfflineData();
      expect(await ContactsVault.load(ContactKind.trusted), isNull);
    });
  });

  group('Saved content', () {
    test('is grouped into courses, articles and the rest', () async {
      await OfflineCache.instance.write('https://empuanapp.id/api/learning/courses/budget', {'data': 'x' * 2000});
      await OfflineCache.instance.write('https://empuanapp.id/api/suara-puan', {'data': []});
      await OfflineCache.instance.write('https://empuanapp.id/api/ruang-puan', {'data': []});

      final counts = await OfflineCache.instance.counts();
      expect(counts[OfflineSection.courses], 1);
      expect(counts[OfflineSection.articles], 1);
      expect(counts[OfflineSection.other], 1);
      final sizes = await OfflineCache.instance.sizes();
      expect(sizes[OfflineSection.courses], greaterThan(sizes[OfflineSection.articles]!));
    });

    test('sizes read naturally', () {
      expect(formatBytes(0), '0 KB');
      expect(formatBytes(1500), '2 KB');
      expect(formatBytes(4718592), '4.5 MB');
      expect(formatBytes(18 * 1024 * 1024), '18 MB');
    });
  });

  group('Offline banner text', () {
    final now = DateTime(2026, 10, 26, 16);

    test('says when the saved copy is from', () {
      expect(offlineMessage(DateTime(2026, 10, 26, 14, 5), now: now), 'You’re offline. Showing what was saved today at 14:05.');
      expect(offlineMessage(DateTime(2026, 10, 25, 9, 30), now: now), 'You’re offline. Showing what was saved yesterday at 09:30.');
      expect(offlineMessage(DateTime(2026, 10, 2, 9), now: now), 'You’re offline. Showing what was saved on 2 Oct.');
    });

    test('without a saved copy it still says SOS works', () {
      expect(offlineMessage(null, now: now), contains('SOS still work'));
    });
  });

  group('SOS text', () {
    final now = DateTime(2026, 10, 26, 16);

    test('a fresh GPS fix is sent as is', () {
      final text = SosController.helpMessage(_position(now.subtract(const Duration(seconds: 20))), now: now);
      expect(text, contains('maps.google.com/?q=-6.20000,106.80000'));
      expect(text, isNot(contains('last known')));
    });

    test('an older last known position says how old it is', () {
      final text = SosController.helpMessage(_position(now.subtract(const Duration(minutes: 12))), now: now);
      expect(text, endsWith('(last known, about 12 min ago)'));
    });
  });
}
