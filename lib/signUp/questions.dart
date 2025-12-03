import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/signUp/allSetPage.dart';
import 'package:Empuan/styles/style.dart';
import 'package:Empuan/components/cancel_dialog.dart';
import 'package:http/http.dart' as http;

class questions extends StatefulWidget {
  // questions({Key? key}) : super(key: key);

  final String username;
  final String email;
  final String password;

  const questions({
    Key? key,
    required this.username,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<questions> createState() => _questionsState();
}

double progressPercentage = 0.2;

class _questionsState extends State<questions> with TickerProviderStateMixin {
  List<Map<String, dynamic>> question1 = [
    {"id": 0, "selected": false, "title": 'My cycle is regular'},
    {"id": 1, "selected": false, "title": 'My cycle is irregular'},
    {"id": 2, "selected": false, "title": 'I don\'t know'},
  ];
  List<Map<String, dynamic>> question3 = [
    {"id": 0, "selected": false, "title": 'No, I sleep well'},
    {"id": 1, "selected": false, "title": 'Difficulty falling asleep'},
    {"id": 2, "selected": false, "title": 'Waking up tired'},
    {"id": 3, "selected": false, "title": 'Waking up during the night'},
    {"id": 4, "selected": false, "title": 'Lack of sleep schedule'},
    {"id": 5, "selected": false, "title": 'Insomnia'},
    {"id": 6, "selected": false, "title": 'Other'},
  ];
  List<Map<String, dynamic>> question4 = [
    {"id": 0, "selected": false, "title": 'Painful menstrual cramps'},
    {"id": 1, "selected": false, "title": 'PMS symptoms'},
    {"id": 2, "selected": false, "title": 'Unusual discharge'},
    {"id": 3, "selected": false, "title": 'Heavy menstrual flow'},
    {"id": 4, "selected": false, "title": 'Mood Swings'},
    {"id": 5, "selected": false, "title": 'Other'},
    {"id": 6, "selected": false, "title": 'No, nothings bother me'},
  ];
  List<Map<String, dynamic>> question5 = [
    {"id": 0, "selected": false, "title": 'None'},
    {"id": 1, "selected": false, "title": 'Lose weight'},
    {"id": 2, "selected": false, "title": 'Gain weight'},
    {"id": 3, "selected": false, "title": 'Start exercising'},
    {"id": 4, "selected": false, "title": 'Learn about nutrition'},
    {"id": 5, "selected": false, "title": 'Get more energy'},
    {"id": 6, "selected": false, "title": 'Other'},
  ];
  late PageController _pageViewController = PageController();
  late TabController _tabController;
  int _currentPageIndex = 0;
  late TextEditingController dateInputController;
  late TextEditingController dateInputControllerend;
  bool dontKnowSelected = false;
  bool dontKnowSelectedEnd = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 5, vsync: this);
    dateInputController = TextEditingController();
    dateInputControllerend = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // cek username ama password
    print("q username: ${widget.username}");
    print("q password: ${widget.password}");

    return Scaffold(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
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
                        Text(
                          'Empuan',
                          style: TextStyle(
                            fontFamily: 'Brodies',
                            fontSize: 28,
                            color: AppColors.primary,
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
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
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
                            'Question ${_currentPageIndex + 1} of 5',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(((_currentPageIndex + 1) / 5) * 100).toInt()}%',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.primary,
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
                          percent: (_currentPageIndex + 1) / 5,
                          backgroundColor: AppColors.accent.withOpacity(0.3),
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
              ),

              // PageView Content
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageViewController,
                  onPageChanged: _handlePageViewChanged,
                  children: [
                    _buildQuestionPage(
                      questionNumber: 1,
                      question: 'Is your menstrual cycle regular?',
                      subtitle: '(varies by no more than 7 days)',
                      options: question1,
                    ),
                    _buildDateQuestionPage(),
                    _buildQuestionPage(
                      questionNumber: 3,
                      question:
                          'Is there anything you want to improve about your sleep?',
                      options: question3,
                    ),
                    _buildQuestionPage(
                      questionNumber: 4,
                      question:
                          'Do you experience discomfort due to any of the following?',
                      options: question4,
                    ),
                    _buildQuestionPage(
                      questionNumber: 5,
                      question: 'What\'s your fitness goal?',
                      options: question5,
                    ),
                  ],
                ),
              ),

              // Bottom Navigation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Back Button (hidden on first page)
                      if (_currentPageIndex > 0)
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
                                _updateCurrentPageIndex(_currentPageIndex - 1);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.textPrimary,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
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
                      // Next Button
                      Expanded(
                        flex: _currentPageIndex == 0 ? 1 : 1,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: _canProceed()
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryVariant,
                                    ],
                                  )
                                : null,
                            color: _canProceed() ? null : Colors.grey,
                            boxShadow: _canProceed()
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: (_canProceed() && !_isSubmitting)
                                ? _handleNext
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
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
                                : Text(
                                    _currentPageIndex == 4
                                        ? 'Finish'
                                        : 'Save & Next',
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
                      ),
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

  Widget _buildQuestionPage({
    required int questionNumber,
    required String question,
    String? subtitle,
    required List<Map<String, dynamic>> options,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Question Number Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Question $questionNumber',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Question Text
            Text(
              question,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Options
            Column(
              children: List.generate(
                options.length,
                (index) => _buildModernOption(
                  title: options[index]["title"],
                  isSelected: options[index]["selected"],
                  onTap: () {
                    setState(() {
                      for (var i = 0; i < options.length; i++) {
                        options[i]["selected"] = i == index;
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDateQuestionPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Question Number Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Question 2',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Question 1: Start Date
            Text(
              'When did your last period start?',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 24),

            // Start Date Picker
            Container(
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
                controller: dateInputController,
                readOnly: true,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Select start date',
                  hintStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onTap: () async {
                  setState(() {
                    dontKnowSelected = false;
                  });
                  DateTime? pickedDate = await showDatePicker(
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
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    setState(() {
                      dateInputController.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 40),

            // Question 2: End Date
            Text(
              'When did your last period end?',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 24),

            // End Date Picker
            Container(
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
                controller: dateInputControllerend,
                readOnly: true,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Select end date',
                  hintStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onTap: () async {
                  setState(() {
                    dontKnowSelectedEnd = false;
                  });
                  DateTime? pickedDate = await showDatePicker(
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
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (pickedDate != null) {
                    setState(() {
                      dateInputControllerend.text =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.accent.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary.withOpacity(0.3),
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_currentPageIndex == 1) {
      return dateInputController.text.isNotEmpty &&
          dateInputControllerend.text.isNotEmpty;
    }
    return _isAnyOptionSelected(_currentPageIndex);
  }

  Future<void> _handleNext() async {
    if (_isSubmitting) return;

    print('[DEBUG] _handleNext called, page: $_currentPageIndex');
    print('[DEBUG] Can proceed: ${_canProceed()}');

    setState(() => _isSubmitting = true);

    try {
      if (_currentPageIndex == 4) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AllSetPage()),
        );
        return;
      }

      if (_currentPageIndex == 1 && dateInputController.text.isNotEmpty) {
        print('[DEBUG] Submitting period data...');

        // Lakukan login otomatis dengan username dan password yang diberikan
        await doLogin();

        // Ambil ID berdasarkan username
        final userId = await getIdByUsername(widget.username);

        // Jika ID berhasil diperoleh, kirimkan data catatan haid
        if (userId != null) {
          print("[DEBUG] User ID: $userId, submitting data...");
          await submitData();
        } else {
          print("[DEBUG] Failed to get user ID");
        }

        // Lakukan logout setelah submit data catatan haid
        await AuthService.logout();
      }

      _updateCurrentPageIndex(_currentPageIndex + 1);
    } catch (e, stackTrace) {
      print('[ERROR] _handleNext failed: $e');
      print('[ERROR] Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> doLogin() async {
    final email2 = widget.email;
    final password2 = widget.password;

    bool isSuccess =
        await AuthService().login(email: email2, password: password2);

    if (!isSuccess) {
      print(isSuccess);
    }
  }

  Future<String?> getIdByUsername(String username) async {
    final url = 'http://192.168.8.52:8000/api/users/username/$username';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map;
      final result = json['data'];
      if (result != null && result.containsKey('id')) {
        return result['id'].toString();
      }
    }

    return null;
  }

  Future<void> submitData() async {
    final dateStart = dateInputController.text;
    final dateEnd = dateInputControllerend.text;

    print("ini hasilklan" + dateStart + " " + dateEnd);

    final body = {
      'start_date': dateStart,
      'end_date': dateEnd,
    };

    final url = "http://192.168.8.52:8000/api/catatan-haid";
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AuthService.token}'
    });

    print(response.statusCode);
    print(response.body);
  }

  bool _isAnyOptionSelected(int currentPageIndex) {
    if (currentPageIndex == 0) {
      return question1.any((item) => item['selected'] == true);
    } else if (currentPageIndex == 2) {
      return question3.any((item) => item['selected'] == true);
    } else if (currentPageIndex == 3) {
      return question4.any((item) => item['selected'] == true);
    } else if (currentPageIndex == 4) {
      return question5.any((item) => item['selected'] == true);
    }
    return false;
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
}
