import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/screens/navScreen.dart';

import 'package:Empuan/services/auth_service.dart';

import 'package:Empuan/signUp/intro.dart';

import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'package:Empuan/config/api_config.dart';

// import android.telephony.SmsManager;

class LoginPage extends StatefulWidget {
  final Map? login;

  const LoginPage({Key? key, this.login}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool visible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true; // Password hidden by default
  bool _isLoggingIn = false; // Track login state
  String? _currentAddress;
  Position? _currentPosition;
  static const platform = const MethodChannel('sendSms');

  void initState() {
    super.initState();
    // getDataKontakAman();
    getData();
  }

  bool isLoading = true;
  List<String> phoneNumbers = [];
  List<dynamic> dataMore = [];
  // final List listNum = [
  //   '62895617896999',
  //   '6285773030388',
  //   '6281368701176',
  //   '62895334296207',
  //   '6282277842107'
  // ];
  final List listNum = [
    '6281368701176',
    '6283895832404',
    '62895334296207',
    '628159966712',
    '6285290176877',
    '6281285362705',
    '6285766996371',
    '6287781630337',
    '6281332040550',
    '6289638016161',
    '6285725177043',
    '62895389916688',
    '6285276251525',
    '6281377690667',
    '6282211114846',
    '6282277842107',
    '628119517675',
    '6282173320908',
    '6281332185362',
    '6281905634863',
    '62895414770917',
    '628995717130',
    '6285773030388',
    '628118895560',
    '6285861002700',
    '6281905538337',
    '6282297936064',
    '6288747566647',
    '628111915988',
    '6281388193216',
    '628198405395',
    '6281341457095',
    '6289643690621',
    '6288269841977',
    '6285156565719',
    '6285693070832'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'images/empuanlogo.jpg',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.favorite_rounded,
                              size: 50,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Empuan',
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        color: AppColors.primary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      'Your holistic health journey awaits 🌸',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email/Username Field
                    buildModernTextField(
                      controller: usernameController,
                      obscureText: false,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    buildModernTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      obscureText: obscurePassword,
                      onTap: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryVariant,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoggingIn ? null : doLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoggingIn
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Not a member?',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const Intro(),
                              ),
                            );
                          },
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Footer
                    Text(
                      '© 2025 Empuan | Designed for holistic wellbeing',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The rest of your code remains unchanged
  // ...

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    Function()? onTap,
    bool? obscureText, // Add the obscureText parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        obscureText: obscureText ??
            true, // Set obscureText based on the parameter or default to false
        controller: controller,
        decoration: InputDecoration(
          suffixIcon: hintText == 'Password'
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: onTap as void Function()?,
                )
              : null,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
        onTap: onTap,
      ),
    );
  }

  Widget buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    Function()? onTap,
    bool? obscureText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText ?? false,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: AppColors.textSecondary.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: hintText == 'Password'
              ? IconButton(
                  icon: Icon(
                    obscureText == true
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  onPressed: onTap,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        validator: validator,
      ),
    );
  }

  doLogin() async {
    bool isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final emailOrUsername = usernameController.text;
      final password = passwordController.text;

      print('[DEBUG] Attempting login for user: $emailOrUsername');

      bool isSuccess =
          await AuthService().login(email: emailOrUsername, password: password);

      print('[DEBUG] Login result: $isSuccess');
      print('[DEBUG] Token: ${AuthService.token}');

      if (!isSuccess) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Login failed. Please check your credentials.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Login successful! Welcome back.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(16),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Small delay for UX
        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to main screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[ERROR] Login exception: $e');
      print('[ERROR] Stack trace: $stackTrace');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'An error occurred. Please try again.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> getData() async {
    // get data from form
    // submit data to the server
    final url = '${ApiConfig.baseUrl}/ruang-puan';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      print('items kita' + json['data'].toString());
      final result = json['data'] ?? [] as List;
      setState(() {
        dataMore = result;
      });
    } else {}
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }

  // Contact aman darisini sampe abis

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> location() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print('test');
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });

    print('LAT: ${_currentPosition?.latitude ?? ""}');
    print('LNG: ${_currentPosition?.longitude ?? ""}');

    _launchUrl(_currentPosition?.latitude, _currentPosition?.longitude);
  }

  Future<void> _launchUrl(double? lat, double? long) async {
    Uri _url = Uri.parse('https://www.google.com/maps/search/${lat},${long}');
    print(_url);

    // SMS functionality only works on mobile platforms
    if (!kIsWeb) {
      print('SMS sending not available on web. Location: $_url');
      // On mobile, you would use direct_sms here
      // for (var i = 0; i < listNum.length; i++) {
      //   directSms.sendSms(message: "Help Your Friend!!!\n${_url}", phone: "${listNum[i]}");
      // }
    } else {
      print('Web platform: SMS not supported. Location shared: $_url');
    }
  }
}
