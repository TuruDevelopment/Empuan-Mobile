import 'dart:async';
import 'dart:convert';

import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/data/api.dart';
import 'package:Empuan/data/app_version_repository.dart';
import 'package:Empuan/features/learning/services/learning_service.dart';
import 'package:Empuan/features/update/update_gate.dart';
import 'package:Empuan/features/update/update_required_screen.dart';
import 'package:Empuan/services/api_client.dart';
import 'package:Empuan/services/app_info.dart';
import 'package:Empuan/services/chatbot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

Map<String, dynamic> versionBody({bool required = false, bool available = false, int latest = 16}) => {
      'success': true,
      'data': {
        'platform': 'android',
        'min_build': 16,
        'latest_build': latest,
        'latest_version': '2.1.0',
        'update_required': required,
        'update_available': available,
        'store_url': 'https://play.google.com/store/apps/details?id=com.turudev.empuan',
        'title': 'Update Empuan to continue',
        'message': 'This version of Empuan is no longer supported.',
      },
    };

const _upgradeRequired = {
  'success': false,
  'code': 'update_required',
  'title': 'Update Empuan to continue',
  'message': 'This version of Empuan is no longer supported.',
  'store_url': 'https://play.google.com/store/apps/details?id=com.turudev.empuan',
  'min_build': 17,
};

void expectAppHeaders(Map<String, String> headers) {
  expect(headers['X-App-Platform'], 'android');
  expect(headers['X-App-Version'], AppInfo.version);
  expect(headers['X-App-Build'], '${AppInfo.build}');
}

void main() {
  setUp(UpdateGate.reset);

  group('version headers', () {
    test('Api sends them on signed-in and public requests', () async {
      final seen = <Map<String, String>>[];
      final api = Api(client: MockClient((request) async {
        seen.add(request.headers);
        return json({'ok': true});
      }));

      await api.get('/me');
      await api.send('POST', ApiConfig.register, authenticated: false, body: {'email': 'a@b.c'});

      expect(seen, hasLength(2));
      seen.forEach(expectAppHeaders);
      expect(seen.first['Authorization'], startsWith('Bearer'));
      expect(seen.last.containsKey('Authorization'), isFalse);
    });

    test('Learning requests send them', () async {
      late Map<String, String> headers;
      final client = MockClient((request) async {
        headers = request.headers;
        return json({'data': []});
      });

      await LearningService(client: client).getCertificates();

      expectAppHeaders(headers);
    });

    test('the Empuan AI stream sends them', () async {
      late Map<String, String> headers;
      final service = ChatbotService(
        client: MockClient.streaming((request, _) async {
          headers = request.headers;
          return http.StreamedResponse(Stream.value(utf8.encode('{}')), 500, headers: {'content-type': 'application/json'});
        }),
      );

      await service.stream(message: 'Hi').toList();

      expectAppHeaders(headers);
      expect(headers['Accept'], 'text/event-stream');
    });
  });

  group('version check', () {
    AppVersionRepository repoWith(Future<http.Response> Function(http.Request request) handler) =>
        AppVersionRepository(api: Api(client: MockClient(handler)));

    test('asks about this platform and build without signing in', () async {
      late http.Request sent;
      final status = await repoWith((request) async {
        sent = request;
        return json(versionBody());
      }).check();

      expect(sent.url.path, endsWith('/app/version'));
      expect(sent.url.queryParameters, {'platform': 'android', 'build': '${AppInfo.build}'});
      expect(sent.headers.containsKey('Authorization'), isFalse);
      expect(status!.updateRequired, isFalse);
      expect(status.updateAvailable, isFalse);
    });

    test('reads a required update', () async {
      final status = await repoWith((_) async => json(versionBody(required: true, available: true, latest: 17))).check();

      expect(status!.updateRequired, isTrue);
      expect(status.latestBuild, 17);
      expect(status.title, 'Update Empuan to continue');
      expect(status.storeUrl, contains('com.turudev.empuan'));
    });

    test('reads an optional update', () async {
      final status = await repoWith((_) async => json(versionBody(available: true, latest: 17))).check();

      expect(status!.updateRequired, isFalse);
      expect(status.updateAvailable, isTrue);
      expect(status.latestVersion, '2.1.0');
    });

    test('a missing store URL, title or message stays null', () {
      final status = AppVersionStatus.fromJson({
        'data': {'update_required': true, 'store_url': null, 'title': '', 'message': '  '},
      });

      expect(status.storeUrl, isNull);
      expect(status.title, isNull);
      expect(status.message, isNull);
    });

    test('any failure means carry on', () async {
      expect(await repoWith((_) async => json({'message': 'Not Found'}, 404)).check(), isNull);
      expect(await repoWith((_) async => json({'message': 'Server Error'}, 500)).check(), isNull);
      expect(await repoWith((_) async => throw const SocketExceptionLike()).check(), isNull);
      expect(
        await repoWith((_) => Completer<http.Response>().future).check(timeout: const Duration(milliseconds: 10)),
        isNull,
      );
    });

    test('offers an optional update once per latest build', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AppVersionRepository(api: Api(client: MockClient((_) async => json({}))));
      final v17 = AppVersionStatus.fromJson(versionBody(available: true, latest: 17));
      final v18 = AppVersionStatus.fromJson(versionBody(available: true, latest: 18));

      expect(await repo.shouldOffer(v17), isTrue);
      await repo.markOffered(v17);
      expect(await repo.shouldOffer(v17), isFalse);
      expect(await repo.shouldOffer(v18), isTrue);
      expect(await repo.shouldOffer(AppVersionStatus.fromJson(versionBody(required: true, available: true, latest: 19))), isFalse);
    });
  });

  group('426 update_required', () {
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Home')),
      ));
    }

    testWidgets('replaces the app with the update screen once', (tester) async {
      await pumpApp(tester);
      final api = Api(client: MockClient((_) async => json(_upgradeRequired, 426)));

      final errors = <ApiException>[];
      await tester.runAsync(() => Future.wait([
            api.get('/me').catchError((Object e) => errors.add(e as ApiException)),
            api.get('/kontak-aman').catchError((Object e) => errors.add(e as ApiException)),
          ]));
      await tester.pumpAndSettle();

      expect(errors.map((e) => e.code), ['update_required', 'update_required']);
      expect(errors.first.statusCode, 426);
      expect(find.byType(UpdateRequiredScreen), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(navigatorKey.currentState!.canPop(), isFalse);
      expect(find.text('Update Empuan to continue'), findsOneWidget);
    });

    testWidgets('from the Empuan AI stream too', (tester) async {
      await pumpApp(tester);
      final service = ChatbotService(
        client: MockClient.streaming((_, __) async => http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode(_upgradeRequired))),
              426,
              headers: {'content-type': 'application/json'},
            )),
      );

      await tester.runAsync(() => service.stream(message: 'Hi').toList());
      await tester.pumpAndSettle();

      expect(find.byType(UpdateRequiredScreen), findsOneWidget);
    });
  });

  group('UpdateRequiredScreen', () {
    Future<void> pumpScreen(WidgetTester tester, AppVersionStatus status, {List<String>? dialled, List<String?>? opened}) async {
      // Pushed over another route, so a working back gesture would reveal it.
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(navigatorKey: navigator, home: const Scaffold(body: Text('Below'))));
      unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => UpdateRequiredScreen(
          status: status,
          openUpdate: (url) async {
            opened?.add(url);
            return true;
          },
          dial: (number) async {
            dialled?.add(number);
            return true;
          },
        ),
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('has no way back', (tester) async {
      await pumpScreen(tester, const AppVersionStatus(updateRequired: true));

      expect(find.byTooltip('Back'), findsNothing);
      expect(find.byTooltip('Close'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(UpdateRequiredScreen), findsOneWidget);
      expect(find.text('Below'), findsNothing);
    });

    testWidgets('shows the fallback copy when the server sends none', (tester) async {
      await pumpScreen(tester, const AppVersionStatus(updateRequired: true));

      expect(find.text(UpdateRequiredScreen.fallbackTitle), findsOneWidget);
      expect(find.text(UpdateRequiredScreen.fallbackMessage), findsOneWidget);
    });

    testWidgets('Update now opens the store URL from the server', (tester) async {
      final opened = <String?>[];
      await pumpScreen(tester, const AppVersionStatus(updateRequired: true, storeUrl: 'https://example.com/store'), opened: opened);

      await tester.tap(find.text('Update now'));
      await tester.pumpAndSettle();

      expect(opened, ['https://example.com/store']);
    });

    testWidgets('can call 112 without updating', (tester) async {
      final dialled = <String>[];
      await pumpScreen(tester, const AppVersionStatus(updateRequired: true), dialled: dialled);

      await tester.tap(find.text('Emergency? Call 112'));
      await tester.pumpAndSettle();

      expect(dialled, ['112']);
    });
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
