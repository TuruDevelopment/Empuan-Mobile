import 'dart:async';

import 'package:flutter/material.dart';

import 'data/offline.dart';
import 'features/auth/splash_screen.dart';
import 'features/tour/intro_prefs.dart';
import 'services/api_client.dart';
import 'services/app_info.dart';
import 'services/auth_service.dart';
import 'styles/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.load();
  await AuthService.init();
  unawaited(OfflineStatus.instance.start());
  // Before the splash can sign anyone out: was this person using the old app?
  await IntroPrefs.recordFirstLaunch(hadSession: AuthService.token?.isNotEmpty ?? false);
  runApp(const EmpuanApp());
}

class EmpuanApp extends StatelessWidget {
  const EmpuanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Empuan',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
