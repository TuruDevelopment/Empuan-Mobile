import 'package:Empuan/app/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder get _sosFace => find.text('SOS');

/// Holds the SOS button for [duration] and lets go.
Future<void> _hold(WidgetTester tester, {Duration duration = const Duration(milliseconds: 3200)}) async {
  final gesture = await tester.startGesture(tester.getCenter(_sosFace));
  // The first frame starts the hold's clock.
  await tester.pump();
  await tester.pump(duration);
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('ShellSosButton', () {
    Future<(List<String>, List<String>)> pumpButton(WidgetTester tester, {required bool practice}) async {
      final started = <String>[];
      final practised = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: ShellSosButton(
              practice: practice ? () => practised.add('practice') : null,
              startSos: (_) async => started.add('sos'),
            ),
          ),
        ),
      ));
      return (started, practised);
    }

    testWidgets('a practice hold never starts the SOS flow', (tester) async {
      final (started, practised) = await pumpButton(tester, practice: true);

      await _hold(tester);

      expect(practised, ['practice']);
      expect(started, isEmpty);
    });

    testWidgets('the screen-reader long press is practice too', (tester) async {
      final handle = tester.ensureSemantics();
      final (started, practised) = await pumpButton(tester, practice: true);

      tester.semantics.longPress(find.semantics.byLabel(RegExp('^SOS')));
      await tester.pump();

      expect(practised, ['practice']);
      expect(started, isEmpty);
      handle.dispose();
    });

    testWidgets('without practice the hold starts the SOS flow', (tester) async {
      final (started, practised) = await pumpButton(tester, practice: false);

      await _hold(tester);

      expect(started, ['sos']);
      expect(practised, isEmpty);
    });

    testWidgets('a practice hold stays practice if the tour ends mid-hold', (tester) async {
      final started = <String>[];
      var practice = true;
      late StateSetter setOuter;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(builder: (context, setState) {
              setOuter = setState;
              return ShellSosButton(practice: practice ? () {} : null, startSos: (_) async => started.add('sos'));
            }),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(_sosFace));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      setOuter(() => practice = false);
      await tester.pump(const Duration(milliseconds: 2200));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(started, isEmpty);
    });
  });

  testWidgets('in the tab bar the whole face responds, including the part above the bar', (tester) async {
    // The app tour is marked done so only the button is on screen.
    SharedPreferences.setMockInitialValues({'app_tour_v1_done': true});
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
      home: const MainShell(),
    ));
    await tester.pumpAndSettle();

    final barTop = tester.getRect(find.text('Home')).top - 30;
    final point = tester.getCenter(_sosFace) - const Offset(0, 22);
    expect(point.dy, lessThan(barTop), reason: 'the point is above the tab bar');

    final gesture = await tester.startGesture(point);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));
    await gesture.up();
    await tester.pumpAndSettle();

    // With no reachable contacts (requests fail in tests) the real flow
    // starts by asking for one.
    expect(find.text('No one to alert yet'), findsOneWidget);
  });
}
