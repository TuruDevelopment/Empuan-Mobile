import 'package:Empuan/features/auth/welcome_art.dart';
import 'package:Empuan/features/auth/welcome_screen.dart';
import 'package:Empuan/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpWelcome(WidgetTester tester, {Size size = const Size(390, 844), bool reduceMotion = false}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: const WelcomeScreen(),
  ));
  // The illustrations loop forever, so step time instead of settling.
  await tester.pump(const Duration(seconds: 1));
}

/// Swipes one slide left and lets the page snap.
Future<void> _next(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-400, 0));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('four slides, ending with Empuan AI', (tester) async {
    await _pumpWelcome(tester);
    expect(find.text('Look after yourself, with backup'), findsOneWidget);
    expect(find.bySemanticsLabel('Slide 1 of 4'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await _next(tester);
    }
    expect(find.text('Ask anything, any time'), findsOneWidget);
    expect(find.bySemanticsLabel('Slide 4 of 4'), findsOneWidget);
  });

  testWidgets('fits on a small phone and in landscape while animating', (tester) async {
    for (final size in const [Size(360, 520), Size(780, 360)]) {
      await _pumpWelcome(tester, size: size);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
        await _next(tester);
      }
    }
  });

  testWidgets('with reduced motion the illustrations hold still', (tester) async {
    await _pumpWelcome(tester, reduceMotion: true);
    // Nothing is left ticking, so the screen settles.
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeArt), findsOneWidget);
  });

  testWidgets('illustrations are hidden from screen readers', (tester) async {
    await _pumpWelcome(tester);
    expect(find.bySemanticsLabel(RegExp('Dewi')), findsNothing);
    expect(find.text('Dewi · Her Space'), findsOneWidget);
  });
}
