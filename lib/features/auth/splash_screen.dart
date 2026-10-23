import 'package:flutter/material.dart';

import '../../app/main_shell.dart';
import '../../data/account_repository.dart';
import '../../data/api.dart';
import '../../services/auth_service.dart';
import '../../ui/em_ui.dart';
import 'welcome_screen.dart';

/// Decides where to start: the app if a saved session works, otherwise Welcome.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: EmMotion.slow);
  late final Animation<double> _mark = CurvedAnimation(parent: _intro, curve: const Interval(0, 0.75, curve: EmMotion.enter));
  late final Animation<double> _markScale = Tween(begin: 0.92, end: 1.0).animate(_mark);
  late final Animation<double> _tagline = CurvedAnimation(parent: _intro, curve: const Interval(0.35, 1, curve: EmMotion.enter));
  late final Animation<Offset> _taglineSlide = Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(_tagline);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _route();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _playIntro() async {
    try {
      await _intro.forward().orCancel;
    } on TickerCanceled {
      // Disposed mid-intro; nothing left to route.
    }
  }

  Future<void> _route() async {
    final reduced = EmMotion.reduced(context);
    if (reduced) _intro.value = 1;
    // Let the intro finish before leaving so the splash doesn't flash past.
    final intro = reduced ? Future<void>.value() : _playIntro();
    var signedIn = AuthService.token?.isNotEmpty ?? false;
    if (signedIn) {
      try {
        await AccountRepository().fetchMe();
      } on ApiException catch (e) {
        // 401 already signed the user out. Any other failure (offline, server
        // down) keeps the session so SOS still works without a connection.
        if (e.statusCode == 401 || e.statusCode == 403) signedIn = false;
      }
    }
    await intro;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: reduced ? Duration.zero : EmMotion.slow,
      pageBuilder: (_, __, ___) => signedIn ? const MainShell() : const WelcomeScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a.drive(CurveTween(curve: EmMotion.enter)), child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _mark,
              child: ScaleTransition(scale: _markScale, child: const EmWordmark(size: 64, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _tagline,
              child: SlideTransition(
                position: _taglineSlide,
                child: const Text('Safety, learning and community for women', style: TextStyle(color: AppColors.surfaceAlt, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
