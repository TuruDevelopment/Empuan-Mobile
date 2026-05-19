import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:Empuan/signUp/questions.dart';
import 'package:Empuan/styles/style.dart';
import 'package:Empuan/components/cancel_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:Empuan/config/api_config.dart';

class tempSignUpPage extends StatefulWidget {
  const tempSignUpPage({Key? key}) : super(key: key);

  @override
  State<tempSignUpPage> createState() => _tempSignUpPageState();
}

class _tempSignUpPageState extends State<tempSignUpPage>
    with TickerProviderStateMixin {
  late PageController _pageViewController = PageController();
  late TabController _tabController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  final String name = '';
  final String dob = '';
  final String email = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dateInputController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header with Logo and Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Empuan',
                              style: TextStyle(
                                fontFamily: 'Brodies',
                                color: AppColors.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        // Close Button
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              showCancelDialog(context: context);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Progress Indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Step ${_currentPageIndex + 1} of 2',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${((_currentPageIndex + 1) / 2 * 100).toInt()}%',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearPercentIndicator(
                              padding: EdgeInsets.zero,
                              lineHeight: 8.0,
                              percent: (_currentPageIndex + 1) / 2,
                              backgroundColor:
                                  AppColors.accent.withOpacity(0.3),
                              linearGradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryVariant,
                                ],
                              ),
                              barRadius: const Radius.circular(8),
                              animation: true,
                              animationDuration: 400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PageView Content
              Positioned.fill(
                top: 200,
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageViewController,
                  onPageChanged: _handlePageViewChanged,
                  children: [
                    // Page 1: Personal Details
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Details',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tell us about yourself',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  buildModernTextField(
                                    controller: firstNameController,
                                    hintText: 'First and Middle Name',
                                    prefixIcon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your first and middle name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  buildModernTextField(
                                    controller: dateInputController,
                                    hintText: 'Birth Date',
                                    prefixIcon: Icons.cake_outlined,
                                    suffixIcon: Icons.calendar_month_outlined,
                                    readOnly: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your birth date';
                                      }
                                      return null;
                                    },
                                    onTap: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(1950),
                                        lastDate: DateTime(2050),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: AppColors.primary,
                                                onPrimary: Colors.white,
                                                onSurface:
                                                    AppColors.textPrimary,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (pickedDate != null) {
                                        dateInputController.text =
                                            DateFormat('yyyy-MM-dd')
                                                .format(pickedDate);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  buildModernTextField(
                                    controller: emailController,
                                    hintText: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    // Page 2: Credentials
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Credentials',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your login credentials',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  buildModernTextField(
                                    controller: usernameController,
                                    hintText: 'Username',
                                    prefixIcon: Icons.account_circle_outlined,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  buildModernTextField(
                                    controller: passwordController,
                                    hintText: 'Password',
                                    prefixIcon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Buttons
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: PageIndicator(
                  tabController: _tabController,
                  currentPageIndex: _currentPageIndex,
                  onUpdateCurrentPageIndex: _updateCurrentPageIndex,
                  formKey: _formKey,
                  firstNameController: firstNameController,
                  lastNameController: lastNameController,
                  dateInputController: dateInputController,
                  emailController: emailController,
                  usernameController: usernameController,
                  passwordController: passwordController,
                  registrationUser: RegistrationUser,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    setState(() {
      _currentPageIndex = currentPageIndex;
    });
  }

  void _updateCurrentPageIndex(int index) {
    _tabController.index = index;
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    String? Function(String?)? validator,
    Function()? onTap,
    bool readOnly = false,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    bool _obscurePassword = isPassword;
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: _obscurePassword,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: AppColors.primary,
                size: 22,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : (suffixIcon != null
                      ? Icon(
                          suffixIcon,
                          color: AppColors.textSecondary,
                          size: 22,
                        )
                      : null),
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
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            validator: validator,
            onTap: onTap,
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> RegistrationUser(
      var firstNameController,
      var dateInputController,
      var emailController,
      var usernameController,
      var passwordController) async {
    final name = firstNameController.text;
    String dob = dateInputController.text;
    final email = emailController.text;
    final username = usernameController.text;
    final password = passwordController.text;

    print('[REGISTRATION] Starting registration for: $username');
    print('[REGISTRATION] Name: $name');
    print('[REGISTRATION] DOB: $dob');
    print('[REGISTRATION] Email: $email');

    final body = {
      "name": name,
      "dob": dob,
      "email": email,
      "username": username,
      "password": password,
      "gender": "Perempuan",
      "app_version": "general", // IMPORTANT: Set to "general" for wellness app
    };

    if (dob.isNotEmpty) {
      final parts = dob.split('-');
      if (parts.length == 3 && parts[0].length == 2 && parts[2].length == 4) {
        dob = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    }

    final url = '${ApiConfig.baseUrl}/register';
    final uri = Uri.parse(url);
    
    print('[REGISTRATION] POST to: $url');
    print('[REGISTRATION] Body: $body');
    
    try {
      final response = await http
          .post(uri, body: jsonEncode(body), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 20));

      print('[REGISTRATION] Response status: ${response.statusCode}');
      print('[REGISTRATION] Response body: ${response.body}');

      Map<String, dynamic>? responseData;
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = responseData?['token'];
        if (token == null) {
          print('[REGISTRATION] ❌ Missing token in response');
          return {
            'ok': false,
            'message': 'Server mengembalikan respons sukses tetapi token tidak ada.',
          };
        }

        print('[REGISTRATION] ✅ Registration successful');
        print('[REGISTRATION] Token: $token');

        return {
          'ok': true,
          'token': token,
          'user': responseData?['user'],
          'username': username,
          'email': email,
          'password': password,
        };
      }

      print('[REGISTRATION] ❌ Registration failed');
      return {
        'ok': false,
        'message': (responseData?['message'] ?? responseData?['error'] ?? 'Registration failed').toString(),
        'statusCode': response.statusCode,
      };
    } on TimeoutException {
      print('[REGISTRATION] ❌ Request timeout');
      return {
        'ok': false,
        'message': 'Request registrasi timeout. Periksa koneksi ke server atau alamat API.',
      };
    } on SocketException catch (e) {
      print('[REGISTRATION] ❌ SocketException: $e');
      return {
        'ok': false,
        'message': 'Tidak dapat terhubung ke server. Cek jaringan dan base URL.',
      };
    } on FormatException catch (e) {
      print('[REGISTRATION] ❌ FormatException: $e');
      return {
        'ok': false,
        'message': 'Respon server tidak valid.',
      };
    } on HttpException catch (e) {
      print('[REGISTRATION] ❌ HttpException: $e');
      return {
        'ok': false,
        'message': 'Terjadi kesalahan HTTP saat registrasi.',
      };
    } catch (e) {
      print('[REGISTRATION] ❌ Unexpected error: $e');
      return {
        'ok': false,
        'message': 'Terjadi kesalahan tidak terduga saat registrasi.',
      };
    }
  }
}

class PageIndicator extends StatelessWidget {
  PageIndicator({
    super.key,
    required this.tabController,
    required this.currentPageIndex,
    required this.onUpdateCurrentPageIndex,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.dateInputController,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.registrationUser,
  });

  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController dateInputController;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Future<Map<String, dynamic>?> Function(
      TextEditingController,
      TextEditingController,
      TextEditingController,
      TextEditingController,
      TextEditingController) registrationUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back Button (hidden on first page)
        if (currentPageIndex > 0)
          Expanded(
            child: Container(
              height: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  onUpdateCurrentPageIndex(currentPageIndex - 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

        // Next/Finish Button
        Expanded(
          flex: currentPageIndex == 0 ? 1 : 1,
          child: Container(
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
              onPressed: () async {
                // Page 1: Personal Details
                if (currentPageIndex == 0) {
                  if (formKey.currentState!.validate() == false) {
                    return;
                  }
                  print(firstNameController.text);
                  print(dateInputController.text);
                  print(emailController.text);
                }

                // Page 2: Account Credentials
                if (currentPageIndex == 1) {
                  if (formKey.currentState!.validate()) {
                    // Show loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text('Creating account...'),
                          ],
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // Register user
                    final result = await registrationUser(
                      firstNameController,
                      dateInputController,
                      emailController,
                      usernameController,
                      passwordController,
                    );

                    if (result != null && result['ok'] == true) {
                      // Registration successful, navigate to questions with token
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => questions(
                            username: usernameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                            token: result['token'].toString(), // Pass the auth token
                          ),
                        ),
                      );
                    } else {
                      // Registration failed
                      final errorMessage = (result?['message'] ?? 'Registration failed. Please try again.').toString();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                  return;
                }

                onUpdateCurrentPageIndex(currentPageIndex + 1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                currentPageIndex == 1 ? 'Finish' : 'Save & Next',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
