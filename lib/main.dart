import 'package:flutter/material.dart';

import 'features/auth/splash_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'styles/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
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
