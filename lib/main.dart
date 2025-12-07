import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_page.dart';
import 'styles/app_theme.dart';
import 'services/auth_service.dart';

void main() async {
  print('\n╔════════════════════════════════════════════════════════╗');
  print('║                  🚀 APP STARTING                       ║');
  print('╚════════════════════════════════════════════════════════╝');

  // Ensure Flutter is initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  print('[MAIN] Step 1: Loading token from disk...');
  // Load saved token from disk
  await AuthService.init();
  print(
      '[MAIN] Step 2: Token loaded - Value exists: ${AuthService.token != null && AuthService.token!.isNotEmpty}');

  // Force logout for security update - Check app version
  // Commented out to allow users to stay logged in
  // await _checkSecurityUpdate();

  print('[MAIN] Step 3: Launching app widget...');
  runApp(const MyApp());
}

/// Force logout if this is the first run after security update
Future<void> _checkSecurityUpdate() async {
  const String SECURITY_UPDATE_VERSION = '1.1.1'; // Increment version!
  const String VERSION_KEY = 'security_version';

  final prefs = await SharedPreferences.getInstance();
  final savedVersion = prefs.getString(VERSION_KEY);

  // If no saved version or old version, force logout
  if (savedVersion != SECURITY_UPDATE_VERSION) {
    print('╔════════════════════════════════════════════════════════╗');
    print('║       🔒 SECURITY UPDATE - FORCE LOGOUT               ║');
    print('╠════════════════════════════════════════════════════════╣');
    print('║  Old version: ${savedVersion ?? "none"}');
    print('║  New version: $SECURITY_UPDATE_VERSION');
    print('║  Action: Clearing all authentication data...          ║');
    print('╚════════════════════════════════════════════════════════╝');

    await AuthService.logout(); // Clear old token
    await prefs.setString(VERSION_KEY, SECURITY_UPDATE_VERSION);

    print('[SECURITY] ✅ Logout complete - Please login again');
    print('[SECURITY] ⚠️  DO NOT use old users (admin/tes)');
    print('[SECURITY] ✅ Use: Michael (ID 7) or Yongky (ID 8)');
  } else {
    print('[SECURITY] ✅ Already on version $SECURITY_UPDATE_VERSION');
  }
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
