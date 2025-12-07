import 'package:flutter/material.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/start_page.dart';
import 'package:Empuan/screens/navScreen.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('\n[SPLASH] ═══════════════════════════════════════════════');
    print('[SPLASH] 🎬 Splash screen initialized');
    print('[SPLASH] ═══════════════════════════════════════════════\n');

    await Future.delayed(const Duration(seconds: 3));

    print('[SPLASH] ⏰ Delay complete, starting token verification...');

    // Verify if user has valid token
    final hasValidToken = await _verifyToken();

    print('\n[SPLASH] 📊 VERIFICATION RESULT: $hasValidToken');
    print('[SPLASH] ═══════════════════════════════════════════════\n');

    if (mounted) {
      if (hasValidToken) {
        // Token valid, langsung ke home
        print('[SPLASH] ✅ Navigating to MainScreen (Home)');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Token invalid atau tidak ada, ke start page
        print('[SPLASH] ❌ Navigating to StartPage (Login)');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StartPage()),
        );
      }
    }
  }

  /// Verify token validity and user ID match
  Future<bool> _verifyToken() async {
    print('\n[TOKEN_VERIFY] ──────────────────────────────────────');
    print('[TOKEN_VERIFY] 🔐 Starting token verification process...');

    // CRITICAL: Load token from disk FIRST before checking
    print('[TOKEN_VERIFY] Step 1: Reloading token from disk...');
    await AuthService.init();

    final token = AuthService.token;

    print('[TOKEN_VERIFY] Step 2: Checking if token exists in memory...');
    if (token == null || token.isEmpty) {
      print('[TOKEN_VERIFY] ❌ RESULT: No token in memory');
      print('[TOKEN_VERIFY] ──────────────────────────────────────\n');
      return false;
    }

    print(
        '[TOKEN_VERIFY] ✅ Token found in memory: ${token.substring(0, 30)}...');
    print('[TOKEN_VERIFY] Step 3: Making API call to verify token...');
    print('[TOKEN_VERIFY] API URL: ${ApiConfig.baseUrl}/me');

    try {
      final url = '${ApiConfig.baseUrl}/me';
      final uri = Uri.parse(url);

      print('[TOKEN_VERIFY] 📡 Sending GET request...');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      print('[TOKEN_VERIFY] 📥 Response received:');
      print('[TOKEN_VERIFY]    Status Code: ${response.statusCode}');
      print(
          '[TOKEN_VERIFY]    Body Length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        print('[TOKEN_VERIFY] 🔍 Parsing JSON response...');
        final jsonData = jsonDecode(response.body) as Map;
        print('[TOKEN_VERIFY] Response body: ${response.body}');
        print('[TOKEN_VERIFY] JSON keys: ${jsonData.keys.toList()}');

        // API /me returns: {"user": {...}, "roles": [...]}
        // Not {"data": {...}} like other endpoints
        final userData = jsonData['user'];
        print('[TOKEN_VERIFY] Has "user" key: ${jsonData.containsKey('user')}');
        print('[TOKEN_VERIFY] User value: $userData');

        if (userData != null && userData is Map) {
          final userId = userData['id'];
          final username = userData['name'] ?? userData['username'];
          print('[TOKEN_VERIFY] ✅ VALID TOKEN!');
          print('[TOKEN_VERIFY]    User: $username');
          print('[TOKEN_VERIFY]    ID: $userId');
          print('[TOKEN_VERIFY] ──────────────────────────────────────\n');
          return true;
        } else {
          print(
              '[TOKEN_VERIFY] ⚠️ Response has no "user" field, but status is 200');
          print('[TOKEN_VERIFY] ⚠️ Treating as valid anyway');
          print('[TOKEN_VERIFY] ──────────────────────────────────────\n');
          return true; // Status 200 means token is valid
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Only logout on authentication errors
        print('[TOKEN_VERIFY] ❌ AUTHENTICATION FAILED!');
        print('[TOKEN_VERIFY]    Status: ${response.statusCode}');
        print('[TOKEN_VERIFY]    Reason: Token invalid or expired');
        print('[TOKEN_VERIFY]    Action: Calling logout...');
        await AuthService.logout();
        print('[TOKEN_VERIFY] ──────────────────────────────────────\n');
        return false;
      } else {
        // Other HTTP errors (500, 503, etc) - keep token, try again later
        print('[TOKEN_VERIFY] ⚠️ SERVER ERROR');
        print('[TOKEN_VERIFY]    Status: ${response.statusCode}');
        print('[TOKEN_VERIFY]    Body: ${response.body}');
        print(
            '[TOKEN_VERIFY]    Action: Keeping token (temporary server issue)');
        print('[TOKEN_VERIFY] ──────────────────────────────────────\n');
        return true; // Trust the token, proceed to home
      }
    } catch (e) {
      print('[TOKEN_VERIFY] ⚠️ NETWORK ERROR');
      print('[TOKEN_VERIFY]    Error: $e');
      print('[TOKEN_VERIFY]    Error Type: ${e.runtimeType}');
      print('[TOKEN_VERIFY]    Action: Keeping token (might be offline)');
      print('[TOKEN_VERIFY] ──────────────────────────────────────\n');
      // Network error (timeout, no connection) - keep token and proceed
      return true; // Trust the token exists, proceed to home
    }

    print('[TOKEN_VERIFY] ❌ UNEXPECTED FALLTHROUGH');
    print('[TOKEN_VERIFY] ──────────────────────────────────────\n');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.15),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon with Animation
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'images/empuanlogo.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.favorite_rounded,
                                  size: 80,
                                  color: AppColors.primary,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // App Name with Fade In Animation
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOut,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: const Text(
                    'Empuan',
                    style: TextStyle(
                      fontFamily: 'Brodies',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOut,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'Your Safety Companion',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Loading Indicator
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
