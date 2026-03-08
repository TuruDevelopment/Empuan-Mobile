import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/components/dailyQuiz.dart';
import 'package:Empuan/screens/catatanHaid.dart';
import 'package:Empuan/screens/chatbot.dart';
import 'package:Empuan/screens/newUntukPuan.dart';
import 'package:Empuan/screens/suaraPuan.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:Empuan/config/api_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.startdate, required this.enddate});

  final DateTime startdate;
  final DateTime enddate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getCurrentUser().then((userid) {
      if (userid != null) {
        getData(userid);
      }
    });
  }

  // State Variables
  late DateTime _rangeStartDay = widget.startdate;
  late DateTime _rangeEndDay = widget.enddate;
  late DateTime _rangeStartDayplus30 =
      _rangeStartDay.add(const Duration(days: 30));
  late DateTime _rangeEndDayplus30 = _rangeEndDay.add(const Duration(days: 30));

  // Stats data from backend (Logic Baru)
  double? avgCycleLength;
  int? lastCycleLength;
  DateTime? predictedNextPeriod;
  int? daysUntilNextPeriod;

  Future<int?> getCurrentUser() async {
    final url = '${ApiConfig.baseUrl}/me';
    final uri = Uri.parse(url);

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final userData = jsonData['user'];

        if (userData != null && userData is Map) {
          if (userData.containsKey('id')) {
            return userData['id'];
          }
        }
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
    return null;
  }

  Future<void> getData(int userid) async {
    setState(() {
      isLoading = true;
    });

    // First, check user's app version
    final appVersion = await _checkAppVersion();
    print('[HOME] User app version: $appVersion');

    // If general version, try auto-upgrade to health
    if (appVersion == 'general') {
      print('[HOME] User is general version, attempting auto-upgrade...');
      final upgraded = await _autoUpgradeToHealth();
      if (upgraded) {
        print('[HOME] Successfully auto-upgraded to health version');
      } else {
        print('[HOME] Auto-upgrade failed or not needed, skipping period tracking');
        // User is general version and couldn't upgrade - show message but don't crash
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Period tracking is available for Health version users'),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    // 1. Fetch List Data (Untuk kebutuhan kalender range)
    final url = '${ApiConfig.baseUrl}/catatan-haid';
    final uri = Uri.parse(url);

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['data'] != null) {
          final data = jsonData['data'];
          if (data['start_date'] != null && data['end_date'] != null) {
            setState(() {
              _rangeStartDay = DateTime.parse(data['start_date']);
              _rangeEndDay = DateTime.parse(data['end_date']);
            });
          }
        }
      } else if (response.statusCode == 403) {
        print('[HOME] 403 Forbidden - User needs health version');
        // Handle gracefully - user is general version
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upgrade to Health version for period tracking'),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching list data: $e");
    }

    // 2. Fetch stats data (Logic Utama Data)
    await getStats();

    setState(() {
      isLoading = false;
    });
  }

  // Check user's app version
  Future<String> _checkAppVersion() async {
    try {
      final url = '${ApiConfig.baseUrl}/me';
      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${AuthService.token}'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final user = jsonData['user'];
        if (user != null && user['app_version'] != null) {
          return user['app_version'];
        }
      }
    } catch (e) {
      print('[HOME] Error checking app version: $e');
    }
    return 'general'; // Default to general
  }

  // Auto-upgrade user from general to health
  Future<bool> _autoUpgradeToHealth() async {
    try {
      final url = '${ApiConfig.baseUrl}/wellness/upgrade-to-health';
      final uri = Uri.parse(url);
      
      // Get current token - make sure it's the full token
      String? token = AuthService.token;
      
      print('[HOME] ═══════════════════════════════════════');
      print('[HOME] 🔐 Auto-Upgrade Token Check');
      print('[HOME] Token exists: ${token != null}');
      print('[HOME] Token length: ${token?.length ?? 0}');
      if (token != null && token.length > 20) {
        print('[HOME] Token preview: ${token.substring(0, 20)}...');
        print('[HOME] Token starts with number: ${RegExp(r"^[0-9]+\\|").hasMatch(token)}');
      }
      print('[HOME] ═══════════════════════════════════════');
      
      if (token == null || token.isEmpty) {
        print('[HOME] ❌ No token available for upgrade');
        return false;
      }
      
      // Ensure token doesn't have "Bearer " prefix already
      if (token.startsWith('Bearer ')) {
        token = token.substring(7);
        print('[HOME] Removed Bearer prefix from token');
      }
      
      print('[HOME] 📡 Calling upgrade endpoint: $url');
      
      // Use http.post directly with proper Bearer token format
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',  // Add Bearer prefix here
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}), // Send empty body
      );

      print('[HOME] 📥 Upgrade response status: ${response.statusCode}');
      print('[HOME] 📥 Upgrade response headers: ${response.headers}');
      print('[HOME] 📥 Upgrade response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          final alreadyUpgraded = jsonData['already_upgraded'] ?? false;
          print('[HOME] ✅ Already upgraded: $alreadyUpgraded');
          print('[HOME] ═══════════════════════════════════════');
          return !alreadyUpgraded; // Return true if upgraded
        } catch (e) {
          print('[HOME] ❌ Error parsing response: $e');
          print('[HOME] Raw response: ${response.body}');
          return false;
        }
      } else if (response.statusCode == 401) {
        // Token invalid - but don't trigger logout, just return false
        print('[HOME] ⚠️ Upgrade endpoint returned 401 - Token invalid/expired');
        print('[HOME] This is a backend authentication issue');
        print('[HOME] ═══════════════════════════════════════');
        return false;
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist on backend
        print('[HOME] ⚠️ Upgrade endpoint not found (404)');
        print('[HOME] ═══════════════════════════════════════');
        return false;
      } else if (response.statusCode == 403) {
        print('[HOME] ⚠️ Upgrade endpoint returned 403 - Forbidden');
        print('[HOME] ═══════════════════════════════════════');
        return false;
      } else {
        print('[HOME] ⚠️ Upgrade endpoint returned ${response.statusCode}');
        print('[HOME] ═══════════════════════════════════════');
        return false;
      }
    } catch (e) {
      print('[HOME] ❌ Error upgrading to health: $e');
      print('[HOME] Stack trace: ${StackTrace.current}');
      print('[HOME] ═══════════════════════════════════════');
    }
    return false;
  }

// Update fungsi ini di HomePage.dart
  Future<void> getStats({int months = 6}) async {
    final url = '${ApiConfig.baseUrl}/catatan-haid/stats?months=$months';
    final uri = Uri.parse(url);

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Debugging
        print("[DEBUG HOME STATS] JSON: $jsonData");

        if (jsonData['data'] != null) {
          final data = jsonData['data'];

          if (mounted) {
            setState(() {
              // --- 1. OVERVIEW (Untuk keperluan internal/future) ---
              if (data['overview'] != null) {
                // Opsional: simpan jika nanti butuh
                // avgCycleLength = ...
              }

              // --- 2. PREDICTION (Bagian Lingkaran Pink) ---
              // Cek object 'prediction' (Format Baru) atau 'next_period' (Format Lama)
              final prediction = data['prediction'] ?? data['next_period'];

              if (prediction != null) {
                // A. Countdown Hari (days_remaining)
                // Backend mengirim 'days_remaining', kodingan lama 'days_until'
                final daysRaw =
                    prediction['days_remaining'] ?? prediction['days_until'];

                if (daysRaw != null) {
                  daysUntilNextPeriod = int.tryParse(daysRaw.toString());
                }

                // B. Tanggal Prediksi (predicted_date) -- INI FIX UTAMANYA --
                // Backend mengirim 'predicted_date', kodingan lama 'predicted_start'
                final dateRaw = prediction['predicted_date'] ??
                    prediction['predicted_start'];

                if (dateRaw != null) {
                  predictedNextPeriod = DateTime.tryParse(dateRaw.toString());
                  print("✅ Tanggal Prediksi Ditemukan: $predictedNextPeriod");
                } else {
                  print("❌ Tanggal Prediksi NULL di JSON");
                }
              }
            });
          }
        }
      } else if (response.statusCode == 403) {
        // Handle 403 gracefully - user is general version
        print("[HOME] 403 Forbidden - User needs health version for stats");
        if (mounted) {
          setState(() {
            // Set default values
            daysUntilNextPeriod = null;
            predictedNextPeriod = null;
          });
        }
      } else {
        print("[ERROR HOME] Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching home stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    _rangeStartDayplus30 = _rangeStartDay.add(const Duration(days: 30));
    _rangeEndDayplus30 = _rangeEndDay.add(const Duration(days: 30));

    // LOGIC TAMPILAN
    String countdownDisplay =
        daysUntilNextPeriod != null ? "$daysUntilNextPeriod" : "-";

    String predictionText = 'Prediction: -';
    if (predictedNextPeriod != null) {
      predictionText =
          'Prediction: ${DateFormat('d MMMM yyyy').format(predictedNextPeriod!)}';
    }

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
              AppColors.accent.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Modern Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Empuan',
                            style: TextStyle(
                              fontFamily: 'Brodies',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Your health companion',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Banner Card
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryVariant,
                              AppColors.accent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              right: -30,
                              top: -30,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -20,
                              bottom: -20,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Image.asset(
                                      'images/empuanlogo.jpg',
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Welcome to Empuan',
                                    style: TextStyle(
                                      fontFamily: 'Brodies',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Your complete health companion for women',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick Actions Row 1
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => const SuaraPuan()));
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 130,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.question_answer_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Her Voice',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Ask Questions',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 10.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        const newUntukPuan()));
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 130,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.secondary.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.secondary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.article_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'For Her',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Articles & Info',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 10.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Quick Actions Row 2
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        const ChatbotScreen()));
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 130,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF7C4DFF),
                                      Color(0xFF536DFE),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF7C4DFF).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.smart_toy_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AI Assistant',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Chat with AI',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 10.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 130,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accent.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.access_time_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Period in',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$countdownDisplay Days',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Next period',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Daily Quiz - Full width
                      InkWell(
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                  builder: (context) => const DailyQuiz()));
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.error,
                                AppColors.error.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.quiz_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Quiz',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Test Your Knowledge',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 10.5,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Container(
                        height: 1,
                        color: AppColors.accent.withOpacity(0.3),
                      ),

                      const SizedBox(height: 24),

                      // --- BAGIAN YANG DIHAPUS (Title & Stats Row) ---
                      // Langsung ke Period Tracker Card (Prediction)

                      // Period Tracker Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Circle Tracker
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  'images/homeCircle.png',
                                  width: 200,
                                  height: 200,
                                ),
                                Image.asset(
                                  'images/homeElipse.png',
                                  width: 200,
                                  height: 200,
                                ),
                                Column(
                                  children: [
                                    const Text(
                                      'Period in',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$countdownDisplay Days',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Prediction Text
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                predictionText,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // See Details Button
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryVariant,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  // Navigate to CatatanHaid and wait for result
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CatatanHaid(
                                        startdate: _rangeStartDay,
                                        enddate: _rangeEndDay,
                                      ),
                                    ),
                                  );

                                  // Refresh data when coming back from CatatanHaid
                                  final userid = await getCurrentUser();
                                  if (userid != null) {
                                    await getData(userid);
                                  }
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'See Details',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
