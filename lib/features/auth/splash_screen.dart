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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
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
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => signedIn ? const MainShell() : const WelcomeScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmWordmark(size: 64, color: Colors.white),
            SizedBox(height: 12),
            Text('Safety, learning and community for women', style: TextStyle(color: AppColors.surfaceAlt, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
