import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:Empuan/signUp/allSetPage.dart';
import 'package:Empuan/styles/style.dart';
import 'package:Empuan/components/cancel_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/services/auth_service.dart';

class questions extends StatefulWidget {
  // questions({Key? key}) : super(key: key);

  final String username;
  final String email;
  final String password;
  final String token;

  const questions({
    Key? key,
    required this.username,
    required this.email,
    required this.password,
    required this.token,
  }) : super(key: key);

  @override
  State<questions> createState() => _questionsState();
}

double progressPercentage = 0.2;

class _questionsState extends State<questions> with TickerProviderStateMixin {
  List<Map<String, dynamic>> question1 = [
    {"id": 0, "selected": false, "title": 'Very active'},
    {"id": 1, "selected": false, "title": 'Moderately active'},
    {"id": 2, "selected": false, "title": 'Sedentary'},
    {"id": 3, "selected": false, "title": 'I don\'t know'},
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
    {"id": 0, "selected": false, "title": 'Stress management'},
    {"id": 1, "selected": false, "title": 'Energy levels'},
    {"id": 2, "selected": false, "title": 'Mood balance'},
    {"id": 3, "selected": false, "title": 'Physical fitness'},
    {"id": 4, "selected": false, "title": 'Nutrition'},
    {"id": 5, "selected": false, "title": 'Other'},
    {"id": 6, "selected": false, 'title': 'No, nothing bothers me'},
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
  
  // Store actual backend question/option IDs
  Map<int, int> questionIdMap = {}; // frontend_id -> backend_question_id
  Map<int, Map<int, int>> optionIdMap = {}; // frontend_question_id -> (frontend_option_id -> backend_option_id)
  
  late PageController _pageViewController = PageController();
  late TabController _tabController;
  int _currentPageIndex = 0;
  bool _isSubmitting = false;
  bool _isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
    _tabController = TabController(length: 4, vsync: this);
    _fetchWellnessQuestions();
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  Future<void> _fetchWellnessQuestions() async {
    print('[ONBOARDING] Fetching wellness questions from backend...');
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/wellness/questions?type=wellness&limit=10');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      print('[ONBOARDING] Fetch questions status: ${response.statusCode}');
      print('[ONBOARDING] Fetch questions response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questions = data['data'] as List;
        
        print('[ONBOARDING] Received ${questions.length} questions');

        // Map backend questions to frontend question indices
        // Frontend: 0=activity, 1=sleep, 2=wellness, 3=fitness
        int questionIndex = 0;
        for (var q in questions) {
          final qId = q['id'] as int;
          final qText = q['question'] as String;
          final options = q['options'] as List;
          
          print('[ONBOARDING] === Question $questionIndex ===');
          print('[ONBOARDING] Backend ID: $qId');
          print('[ONBOARDING] Text: $qText');
          print('[ONBOARDING] Options: ${options.map((o) => "${o['id']}: ${o['text']}").join(", ")}');
          
          // Map by index order (assumes backend returns questions in same order as frontend)
          if (questionIndex == 0) {
            // Activity level question
            questionIdMap[0] = qId;
            optionIdMap[0] = {};
            for (var i = 0; i < options.length && i < question1.length; i++) {
              optionIdMap[0]![i] = options[i]['id'] as int;
              print('[ONBOARDING]   Map option $i (${question1[i]['title']}) -> ${options[i]['id']}');
            }
          } else if (questionIndex == 1) {
            // Sleep question
            questionIdMap[1] = qId;
            optionIdMap[1] = {};
            for (var i = 0; i < options.length && i < question3.length; i++) {
              optionIdMap[1]![i] = options[i]['id'] as int;
              print('[ONBOARDING]   Map option $i (${question3[i]['title']}) -> ${options[i]['id']}');
            }
          } else if (questionIndex == 2) {
            // Wellness concerns question
            questionIdMap[2] = qId;
            optionIdMap[2] = {};
            for (var i = 0; i < options.length && i < question4.length; i++) {
              optionIdMap[2]![i] = options[i]['id'] as int;
              print('[ONBOARDING]   Map option $i (${question4[i]['title']}) -> ${options[i]['id']}');
            }
          }
          
          questionIndex++;
        }

        print('[ONBOARDING] === Final Mapping ===');
        print('[ONBOARDING] Question ID map: $questionIdMap');
        print('[ONBOARDING] Option ID map: $optionIdMap');
      }

      setState(() => _isLoadingQuestions = false);
    } catch (e) {
      print('[ONBOARDING] Error fetching questions: $e');
      setState(() => _isLoadingQuestions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // cek username ama password
    print("q username: ${widget.username}");
    print("q password: ${widget.password}");

    // Show loading while fetching questions
    if (_isLoadingQuestions) {
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
                AppColors.accent.withOpacity(0.15),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading questions...',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                            'Question ${_currentPageIndex + 1} of 4',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(((_currentPageIndex + 1) / 4) * 100).toInt()}%',
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
                          percent: (_currentPageIndex + 1) / 4,
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
                      question: 'How active is your daily lifestyle?',
                      options: question1,
                    ),
                    _buildQuestionPage(
                      questionNumber: 2,
                      question:
                          'Is there anything you want to improve about your sleep?',
                      options: question3,
                    ),
                    _buildQuestionPage(
                      questionNumber: 3,
                      question:
                          'Do you experience discomfort due to any of the following?',
                      options: question4,
                    ),
                    _buildQuestionPage(
                      questionNumber: 4,
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
                                    _currentPageIndex == 3
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
          mainAxisSize: MainAxisSize.min,
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
              mainAxisSize: MainAxisSize.min,
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
    return _isAnyOptionSelected(_currentPageIndex);
  }

  Future<void> _handleNext() async {
    if (_isSubmitting) return;

    print('[ONBOARDING] _handleNext called, page: $_currentPageIndex');

    setState(() => _isSubmitting = true);

    try {
      // Logic untuk halaman terakhir (Finish)
      if (_currentPageIndex == 3) {
        // Submit onboarding data before navigating
        await _submitOnboarding();
        return;
      }

      // Pindah ke halaman berikutnya
      _updateCurrentPageIndex(_currentPageIndex + 1);
    } catch (e, stackTrace) {
      print('[ONBOARDING] _handleNext failed: $e');
      print('[ONBOARDING] Stack trace: $stackTrace');

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

  Future<void> _submitOnboarding() async {
    print('[ONBOARDING] Starting onboarding submission...');

    // Collect answers from all questions
    final selectedActivity = question1.firstWhere((item) => item['selected'] == true);
    final selectedSleep = question3.firstWhere((item) => item['selected'] == true);
    final selectedWellness = question4.firstWhere((item) => item['selected'] == true);

    // Map frontend selections to backend expected values
    final activityLevel = selectedActivity['title'];
    final sleepQuality = selectedSleep['title'];
    final wellnessConcerns = [selectedWellness['title']];

    print('[ONBOARDING] Activity Level: $activityLevel');
    print('[ONBOARDING] Sleep Quality: $sleepQuality');
    print('[ONBOARDING] Wellness Concerns: $wellnessConcerns');

    // Get backend question/option IDs
    final backendQuestionId1 = questionIdMap[0]; // activity
    final backendQuestionId2 = questionIdMap[1]; // sleep
    final backendQuestionId4 = questionIdMap[2]; // wellness
    
    final backendOptionId1 = optionIdMap[0]?[selectedActivity['id']];
    final backendOptionId2 = optionIdMap[1]?[selectedSleep['id']];
    final backendOptionId4 = optionIdMap[2]?[selectedWellness['id']];

    print('[ONBOARDING] Backend Question IDs: Q1=$backendQuestionId1, Q2=$backendQuestionId2, Q4=$backendQuestionId4');
    print('[ONBOARDING] Backend Option IDs: Opt1=$backendOptionId1, Opt2=$backendOptionId2, Opt4=$backendOptionId4');

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Saving your preferences...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Prepare request body with actual backend IDs
    final answers = <Map<String, dynamic>>[];
    
    if (backendQuestionId1 != null && backendOptionId1 != null) {
      answers.add({
        'question_id': backendQuestionId1,
        'option_id': backendOptionId1,
        'answer_text': null,
        'answer_type': 'wellness',
      });
    }
    if (backendQuestionId2 != null && backendOptionId2 != null) {
      answers.add({
        'question_id': backendQuestionId2,
        'option_id': backendOptionId2,
        'answer_text': null,
        'answer_type': 'wellness',
      });
    }
    if (backendQuestionId4 != null && backendOptionId4 != null) {
      answers.add({
        'question_id': backendQuestionId4,
        'option_id': backendOptionId4,
        'answer_text': null,
        'answer_type': 'wellness',
      });
    }

    final body = {
      'answers': answers,
      'activity_level': activityLevel,
      'sleep_quality': sleepQuality,
      'wellness_concerns': wellnessConcerns,
    };

    print('[ONBOARDING] Submitting to: ${ApiConfig.baseUrl}/onboarding/submit');
    print('[ONBOARDING] Request body: $body');

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/onboarding/submit');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      print('[ONBOARDING] Response status: ${response.statusCode}');
      print('[ONBOARDING] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[ONBOARDING] ✅ Onboarding submitted successfully');
        
        // Save token to AuthService for future API calls
        AuthService.token = widget.token;
        
        // Navigate to success page
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AllSetPage()),
            (route) => false, // Remove all previous routes
          );
        }
      } else {
        print('[ONBOARDING] ❌ Onboarding submission failed');
        final errorData = jsonDecode(response.body);
        print('[ONBOARDING] Error: $errorData');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save preferences: ${errorData['message'] ?? 'Unknown error'}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('[ONBOARDING] ❌ Exception during onboarding submission: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  bool _isAnyOptionSelected(int currentPageIndex) {
    if (currentPageIndex == 0) {
      return question1.any((item) => item['selected'] == true);
    } else if (currentPageIndex == 1) {
      return question3.any((item) => item['selected'] == true);
    } else if (currentPageIndex == 2) {
      return question4.any((item) => item['selected'] == true);
    } else if (currentPageIndex == 3) {
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
