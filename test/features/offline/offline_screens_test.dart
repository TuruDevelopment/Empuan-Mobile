import 'package:Empuan/data/contacts_repository.dart';
import 'package:Empuan/data/offline.dart';
import 'package:Empuan/features/ai/ai_chat_screen.dart';
import 'package:Empuan/features/offline/offline_banner.dart';
import 'package:Empuan/features/offline/offline_settings_screen.dart';
import 'package:Empuan/features/space/compose_screen.dart';
import 'package:Empuan/styles/app_theme.dart';
import 'package:Empuan/ui/em_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
    home: home,
  ));
  await tester.pumpAndSettle();
}

void _goOffline() => OfflineStatus.instance.reportUnreachable();

/// Lets real file reads finish: each one needs real time, then a pump to run
/// what follows it under the test's fake clock.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OfflineStatus.instance.reset();
    ContactsVault.memory = {};
  });
  tearDown(() => OfflineStatus.instance.reset());

  testWidgets('the banner appears while offline and goes when the server answers', (tester) async {
    await _pump(tester, const Scaffold(body: Column(children: [OfflineBanner(), Expanded(child: SizedBox())])));
    expect(find.textContaining('You’re offline'), findsNothing);

    _goOffline();
    await tester.pumpAndSettle();
    expect(find.text('You’re offline. Saved content and SOS still work.'), findsOneWidget);

    OfflineStatus.instance.reportReachable();
    await tester.pumpAndSettle();
    expect(find.textContaining('You’re offline'), findsNothing);
  });

  testWidgets('Empuan AI offline offers the help lines and can’t be typed into', (tester) async {
    _goOffline();
    await _pump(tester, const AiChatScreen());

    expect(find.text('Empuan AI needs internet'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
    expect(find.text('SAPA 129'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(field.decoration?.hintText, 'You’re offline');
  });

  testWidgets('a new post can be written offline but not sent', (tester) async {
    _goOffline();
    await _pump(tester, const ComposeScreen());
    expect(find.textContaining('post when you’re back online'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Any tips for a first salary talk?');
    await tester.pump();
    expect(tester.widget<EmButton>(find.widgetWithText(EmButton, 'Post')).onPressed, isNull);
  });

  testWidgets('clearing saved content keeps the trusted contacts', (tester) async {
    await ContactsVault.save(ContactKind.trusted, const [Contact(id: 1, name: 'Ibu', phone: '0812', relation: 'Mother')]);
    await tester.runAsync(() => OfflineCache.instance.write('https://empuanapp.id/api/suara-puan', {'data': 'x' * 4000}));
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const OfflineSettingsScreen()));
    // Sizes are read from disk, outside the test's fake clock.
    await _settleIo(tester);

    expect(find.text('On this phone'), findsOneWidget);
    expect(find.text('Articles (1 page)'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear saved content'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear saved content'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await _settleIo(tester);

    expect(await tester.runAsync(() => OfflineCache.instance.read('https://empuanapp.id/api/suara-puan')), isNull);
    expect(await ContactsVault.load(ContactKind.trusted), isNotNull);
    expect(find.text('Articles'), findsOneWidget);
  });
}
