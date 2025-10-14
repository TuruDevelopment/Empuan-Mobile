import 'package:flutter/material.dart';
import 'splash_page.dart';
import 'styles/app_theme.dart';
import 'services/auth_service.dart';

void main() async {
  // Ensure Flutter is initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved token from disk
  await AuthService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}
