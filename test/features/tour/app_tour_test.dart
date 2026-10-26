import 'package:Empuan/app/main_shell.dart';
import 'package:Empuan/features/learn/learn_tab.dart';
import 'package:Empuan/features/profile/animated_avatar.dart';
import 'package:Empuan/features/tour/app_tour.dart';
import 'package:Empuan/features/tour/intro_prefs.dart';
import 'package:Empuan/features/tour/whats_new_screen.dart';
import 'package:Empuan/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _practiceNote = 'Try it now: hold SOS. This is practice, nothing is sent.';

// startSosFlow with no reachable contacts (every request fails in tests)
// opens this sheet, so seeing it means a real SOS flow started.
const _realSosSheet = 'No one to alert yet';

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

Future<void> _pumpShell(WidgetTester tester, {Size size = const Size(390, 844), bool reduceMotion = true}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: const MainShell(),
  ));
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

/// The tour card, found by the label it gives screen readers.
Rect _card(WidgetTester tester) => tester.getRect(find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.label?.startsWith('App tour, step') ?? false),
    ));

// Searched in the live semantics tree, which is what screen readers see.
final _profileButton = find.semantics.byLabel(RegExp('Your profile'));
final _sosButton = find.semantics.byLabel(RegExp('^SOS'));

void main() {
  group('IntroPrefs', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a session on the first launch of this version means What’s new is due', () async {
      await IntroPrefs.recordFirstLaunch(hadSession: true);
      expect(await IntroPrefs.whatsNewDue(), isTrue);

      // Later launches don't change the answer, even after signing out.
      await IntroPrefs.recordFirstLaunch(hadSession: false);
      expect(await IntroPrefs.whatsNewDue(), isTrue);

      await IntroPrefs.markWhatsNewSeen();
      expect(await IntroPrefs.whatsNewDue(), isFalse);
    });

    test('fresh installs with a new account never see What’s new', () async {
      await IntroPrefs.recordFirstLaunch(hadSession: false);
      await IntroPrefs.recordFirstLaunch(hadSession: true);
      expect(await IntroPrefs.whatsNewDue(), isFalse);
      expect(await IntroPrefs.whatsNewDue(accountCreatedAt: IntroPrefs.v2Cutoff.add(const Duration(days: 1))), isFalse);
    });

    test('an account from the old app gets What’s new after logging in on a fresh install', () async {
      await IntroPrefs.recordFirstLaunch(hadSession: false);
      final oldAccount = DateTime.utc(2025, 3, 14);
      expect(await IntroPrefs.whatsNewDue(accountCreatedAt: oldAccount), isTrue);

      await IntroPrefs.markWhatsNewSeen();
      expect(await IntroPrefs.whatsNewDue(accountCreatedAt: oldAccount), isFalse);
    });

    test('the tour is remembered once done', () async {
      expect(await IntroPrefs.tourDone(), isFalse);
      await IntroPrefs.markTourDone();
      expect(await IntroPrefs.tourDone(), isTrue);
    });
  });

  group('spotlight tour', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('runs on the first Home visit and practice never starts SOS', (tester) async {
      await _pumpShell(tester);

      expect(find.text('Your SOS button'), findsOneWidget);
      expect(find.text('1 OF 5'), findsOneWidget);
      expect(find.text(_practiceNote), findsOneWidget);

      await _hold(tester);

      expect(find.text('That’s all it takes'), findsOneWidget);
      expect(find.text('1 OF 5 · PRACTICE DONE'), findsOneWidget);
      expect(find.text(_realSosSheet), findsNothing);

      await _next(tester);
      expect(find.text('Safety tools'), findsOneWidget);
      // The SOS button is no longer reachable through the scrim.
      await _hold(tester);
      expect(find.text(_realSosSheet), findsNothing);
      expect(find.text('Safety tools'), findsOneWidget);

      await _next(tester);
      expect(find.text('Ask Empuan AI'), findsWidgets);
      await _next(tester);
      expect(find.text('Learn and Her Space'), findsOneWidget);
      await _next(tester);
      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Skip tour'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(AppTourOverlay), findsNothing);
      expect(await IntroPrefs.tourDone(), isTrue);

      // Outside the tour the same button starts the real flow.
      await _hold(tester);
      expect(find.text(_realSosSheet), findsOneWidget);
    });

    testWidgets('the whole SOS face responds, including the part above the tab bar', (tester) async {
      await _pumpShell(tester);
      final label = tester.getRect(_sosFace);
      final barTop = tester.getRect(find.text('Home')).top - 30;
      final top = tester.getCenter(_sosFace) - Offset(0, label.height / 2 + 14);
      expect(top.dy, lessThan(barTop), reason: 'the point is above the tab bar');

      Future<void> holdAt(Offset point) async {
        final gesture = await tester.startGesture(point);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 3200));
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await holdAt(top);
      expect(find.text('That’s all it takes'), findsOneWidget);

      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();
      await holdAt(top);
      expect(find.text(_realSosSheet), findsOneWidget);
    });

    testWidgets('with reduced motion steps change without a transition', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Safety tools'), findsOneWidget);
      expect(find.text('Your SOS button'), findsNothing);
    });

    testWidgets('Next works without practising', (tester) async {
      await _pumpShell(tester);

      await _next(tester);

      expect(find.text('Safety tools'), findsOneWidget);
      expect(find.text('That’s all it takes'), findsNothing);
    });

    testWidgets('taps on the scrim do nothing', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Learn'), warnIfMissed: false);
      await tester.tapAt(const Offset(195, 300));
      await tester.pumpAndSettle();

      expect(find.text('Your SOS button'), findsOneWidget);
      // Learn was never opened.
      expect(find.byType(LearnTab), findsNothing);
    });

    testWidgets('Skip tour ends it for good', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();

      expect(find.byType(AppTourOverlay), findsNothing);
      expect(await IntroPrefs.tourDone(), isTrue);
    });

    testWidgets('does not run again once done, but can be replayed', (tester) async {
      SharedPreferences.setMockInitialValues({IntroPrefs.tourDoneKey: true});
      await _pumpShell(tester);
      expect(find.byType(AppTourOverlay), findsNothing);

      AppTour.replay();
      await tester.pumpAndSettle();

      expect(find.text('Your SOS button'), findsOneWidget);
    });

    testWidgets('the card sits above tab targets and below the avatar', (tester) async {
      await _pumpShell(tester);
      final tabBarTop = tester.getTopLeft(find.text('Home')).dy - 30;

      expect(_card(tester).bottom, lessThan(tabBarTop));
      for (var i = 0; i < 3; i++) {
        await _next(tester);
      }
      expect(find.text('Learn and Her Space'), findsOneWidget);
      expect(_card(tester).bottom, lessThan(tabBarTop));

      await _next(tester);
      expect(_card(tester).top, greaterThan(tester.getRect(find.byType(AnimatedAvatar)).bottom));
    });

    testWidgets('fits on a small screen and in landscape', (tester) async {
      for (final size in const [Size(360, 520), Size(780, 360)]) {
        SharedPreferences.setMockInitialValues({});
        await _pumpShell(tester, size: size);
        for (var step = 0; step < AppTourController.steps; step++) {
          final card = _card(tester);
          expect(card.top, greaterThanOrEqualTo(0), reason: 'step ${step + 1} at $size');
          expect(card.bottom, lessThanOrEqualTo(size.height), reason: 'step ${step + 1} at $size');
          expect(card.left, greaterThanOrEqualTo(0));
          expect(card.right, lessThanOrEqualTo(size.width));
          if (step < 4) {
            await _next(tester);
            expect(find.textContaining('${step + 2} OF 5'), findsOneWidget, reason: 'Next is reachable at $size');
          }
        }
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('screen readers only reach the tour card', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpShell(tester);

      expect(find.semantics.byLabel('App tour, step 1 of 5'), findsOne);
      expect(_profileButton, findsNothing);
      expect(_sosButton, findsNothing);

      await _next(tester);
      expect(find.semantics.byLabel('App tour, step 2 of 5'), findsOne);

      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();
      expect(_profileButton, findsOne);
      expect(_sosButton, findsOne);
      handle.dispose();
    });

    testWidgets('also runs with animations on', (tester) async {
      await _pumpShell(tester, reduceMotion: false);
      // Home keeps skeletons shimmering, so pump through the transitions.
      expect(find.text('Your SOS button'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Safety tools'), findsOneWidget);
    });
  });

  group('What’s new', () {
    testWidgets('shows for people from the old app, then the tour', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await IntroPrefs.recordFirstLaunch(hadSession: true);
      await _pumpShell(tester);

      expect(find.text('Empuan has a new look'), findsOneWidget);
      expect(find.byType(AppTourOverlay), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('SOS now works with one hold'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Empuan has a new look'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('What’s changed'), findsOneWidget);

      await tester.tap(find.text('Show me around'));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewScreen), findsNothing);
      expect(find.text('Your SOS button'), findsOneWidget);
      expect(await IntroPrefs.whatsNewDue(), isFalse);
    });

    testWidgets('Skip the tour skips both', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await IntroPrefs.recordFirstLaunch(hadSession: true);
      await _pumpShell(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip the tour'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewScreen), findsNothing);
      expect(find.byType(AppTourOverlay), findsNothing);
      expect(await IntroPrefs.tourDone(), isTrue);
    });

    testWidgets('Skip on the first pages goes to the tour', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await IntroPrefs.recordFirstLaunch(hadSession: true);
      await _pumpShell(tester);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewScreen), findsNothing);
      expect(find.text('Your SOS button'), findsOneWidget);
    });

    testWidgets('new installs go straight to the tour', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await IntroPrefs.recordFirstLaunch(hadSession: false);
      await _pumpShell(tester);

      expect(find.byType(WhatsNewScreen), findsNothing);
      expect(find.text('Your SOS button'), findsOneWidget);
    });
  });
}
