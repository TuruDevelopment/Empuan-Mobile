import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/components/jawabanDailyQuiz.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

class DailyQuiz extends StatefulWidget {
  const DailyQuiz({Key? key}) : super(key: key);

  @override
  State<DailyQuiz> createState() => _DailyQuizState();
}

class _DailyQuizState extends State<DailyQuiz> {
  TextEditingController dateInputController = TextEditingController();
  bool isLoading = true;
  int? selectedIndex; // Ubah ke nullable untuk validasi
  bool hasAnswered = false; // Tambah flag untuk track apakah user sudah pilih

  void initState() {
    super.initState();
    // updateCheckListItems();
    // getDataOption();
    getDataQuestion();
  }

  List<dynamic> dataQuestion = [];
  List<dynamic> dataOption = [];

  // List<Map<String, dynamic>> checkListItems = [
  //   {"id": 0, "selected": false, "title": 'My cycle is regular'},
  //   {"id": 1, "selected": false, "title": 'My cycle is irregular'},
  //   {"id": 2, "selected": false, "title": 'I don\'t know'},
  //   {"id": 3, "selected": false, "title": 'I don\'t know'},
  // ];

  List<Map<String, dynamic>> checkListItems = [];

  void updateCheckListItems() {
    // Clear existing checkListItems
    checkListItems.clear();

    // Iterate through dataOption and add option_text to checkListItems
    for (var option in dataOption) {
      var title = option['option_text'].toString();
      checkListItems.add({
        "id": checkListItems.length, // Use length to generate unique id
        "selected": false,
        "title": title,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(dataQuestion);
    print(dataOption);
    print(checkListItems);

    // Check if no questions available after loading
    bool hasNoQuestions = !isLoading && dataQuestion.isEmpty;

    return Scaffold(
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
          child: Column(
            children: [
              // Modern Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Daily Quiz',
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: hasNoQuestions
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Empty state icon
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.quiz_outlined,
                                  size: 64,
                                  color: AppColors.accent.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No Questions Available',
                                style: TextStyle(
                                  fontFamily: 'Brodies',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'There are no quiz questions available at the moment. Please check back later!',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 15,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.8),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Go Back',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 16,
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
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Quiz Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.error,
                                    AppColors.error.withOpacity(0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.quiz_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Question Card
                            Container(
                              width: double.infinity,
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
                              child: Text(
                                dataQuestion.isNotEmpty
                                    ? dataQuestion[0]['questions'].toString()
                                    : 'Loading question...',
                                style: const TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Options List
                            Column(
                              children: isLoading
                                  ? [
                                      // Loading skeleton for options
                                      for (int i = 0; i < 4; i++)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: AppColors.accent
                                                    .withOpacity(0.2),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    AppColors.accent
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ]
                                  : List.generate(
                                      checkListItems.length,
                                      (index) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: LabeledCheckboxExample(
                                          index: index,
                                          sentences: checkListItems[index]
                                              ["title"],
                                          value: checkListItems[index]
                                              ["selected"],
                                          onChanged: (value) {
                                            setState(() {
                                              for (var i = 0;
                                                  i < checkListItems.length;
                                                  i++) {
                                                if (i == index) {
                                                  checkListItems[i]
                                                      ["selected"] = true;
                                                  selectedIndex = index;
                                                  hasAnswered = true;
                                                } else {
                                                  checkListItems[i]
                                                      ["selected"] = false;
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 32),

                            // Save Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: (isLoading || !hasAnswered)
                                      ? [
                                          AppColors.accent.withOpacity(0.5),
                                          AppColors.accent.withOpacity(0.3),
                                        ]
                                      : [
                                          AppColors.error,
                                          AppColors.error.withOpacity(0.8),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLoading || !hasAnswered)
                                        ? AppColors.accent.withOpacity(0.1)
                                        : AppColors.error.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: (isLoading ||
                                        !hasAnswered ||
                                        selectedIndex == null)
                                    ? null
                                    : () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                JawabanDailyQuiz(
                                              selectedindex: selectedIndex!,
                                            ),
                                          ),
                                        );
                                      },
                                child: isLoading
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white70,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Loading...',
                                            style: TextStyle(
                                              fontFamily: 'Satoshi',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            hasAnswered
                                                ? 'Save & Next'
                                                : 'Select an answer',
                                            style: TextStyle(
                                              fontFamily: 'Satoshi',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: hasAnswered
                                                  ? Colors.white
                                                  : Colors.white70,
                                            ),
                                          ),
                                          if (hasAnswered) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 32),
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

  Future<void> getDataQuestion() async {
    setState(() {
      isLoading = true;
    });
    // get data from form
    // submit data to the server
    final url = 'http://192.168.1.7:8000/api/questions';
    final uri = Uri.parse(url);
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map;
      final List<dynamic> resultList = jsonResponse['data'] ?? [];

      for (var data in resultList) {
        var questions = data['questions'].toString();
        var correctAnswer = data['correct_answer'].toString();
        dataQuestion.add({
          'questions': questions,
          'correct_answer': correctAnswer,
        });
      }

      setState(() {
        // Update state after fetching data
        dataQuestion = resultList;
        isLoading = false;
      });

      getDataOption();
    } else {
      setState(() {
        isLoading = false; // Set isLoading to false if request failed
      });
    }
    // showsuccess or fail message based on status
    print(response.statusCode);
    print('data pas api tarik' + response.body);
  }

  Future<void> getDataOption() async {
    setState(() {
      isLoading = true;
    });

    if (dataQuestion.isNotEmpty) {
      final idQuestion = dataQuestion[0]['id'].toString();
      print('id q: ' + idQuestion);
      final url = 'http://192.168.1.7:8000/api/questions/$idQuestion/options';
      final uri = Uri.parse(url);

      try {
        final response = await http.get(uri,
            headers: {'Authorization': 'Bearer ${AuthService.token}'});

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body) as Map;
          print('items kita' + jsonResponse['data'].toString());
          final List<dynamic> resultList = jsonResponse['data'] ?? [];

          // Clear existing dataOption before adding new options
          // dataOption.clear();

          for (var option in resultList) {
            var optionText = option['option_text'].toString();
            var questionId = option['question_id'].toString();
            dataOption.add({
              'option_text': optionText,
              'question_id': questionId,
            });
          }

          // Update state after fetching data
          setState(() {
            isLoading = false;
          });

          updateCheckListItems();
        } else {
          // Set isLoading to false if request failed
          setState(() {
            isLoading = false;
          });
        }

        // Show success or fail message based on status
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      } catch (error) {
        // Handle any potential errors that occur during the HTTP request
        print('Error fetching data option: $error');
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

class LabeledCheckboxExample extends StatelessWidget {
  final String sentences;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final int index;

  const LabeledCheckboxExample(
      {required this.sentences,
      required this.value,
      required this.onChanged,
      required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value == true
              ? AppColors.error.withOpacity(0.5)
              : AppColors.accent.withOpacity(0.2),
          width: value == true ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: value == true
                ? AppColors.error.withOpacity(0.15)
                : AppColors.accent.withOpacity(0.08),
            blurRadius: value == true ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged?.call(!value!),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: value == true
                          ? AppColors.error
                          : AppColors.accent.withOpacity(0.5),
                      width: 2,
                    ),
                    color: value == true ? AppColors.error : Colors.transparent,
                  ),
                  child: value == true
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    sentences,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight:
                          value == true ? FontWeight.bold : FontWeight.w500,
                      color: value == true
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
