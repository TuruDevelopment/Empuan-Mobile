import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/screens/navScreen.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

class JawabanDailyQuiz extends StatefulWidget {
  final int selectedindex;
  const JawabanDailyQuiz({Key? key, required this.selectedindex})
      : super(key: key);

  @override
  State<JawabanDailyQuiz> createState() => _JawabanDailyQuizState();
}

class _JawabanDailyQuizState extends State<JawabanDailyQuiz> {
  TextEditingController dateInputController = TextEditingController();
  bool isLoading = true;

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

    // Calculate correct answer
    String correctAnswerText = dataQuestion.isNotEmpty
        ? dataQuestion[0]['correct_answer'].toString()
        : '';
    bool isCorrect = widget.selectedindex.toString() == correctAnswerText;

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
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Quiz Result',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Result Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCorrect
                                ? [
                                    AppColors.secondary,
                                    AppColors.secondary.withOpacity(0.8),
                                  ]
                                : [
                                    AppColors.error,
                                    AppColors.error.withOpacity(0.8),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isCorrect
                                      ? AppColors.secondary
                                      : AppColors.error)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Result Text
                      Text(
                        isCorrect ? 'Correct!' : 'Incorrect',
                        style: TextStyle(
                          fontFamily: 'Brodies',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color:
                              isCorrect ? AppColors.secondary : AppColors.error,
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
                        children: List.generate(
                          checkListItems.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LabeledCheckboxExample(
                              index: index,
                              sentences: checkListItems[index]["title"],
                              value: checkListItems[index]["selected"],
                              onChanged: null, // Disabled
                              selectedIndex: widget.selectedindex,
                              correctIndex:
                                  int.tryParse(correctAnswerText) ?? -1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Continue Button
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
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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
    final url = 'http://192.168.8.48:8000/api/questions';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});
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
      final url = 'http://192.168.8.48:8000/api/questions/$idQuestion/options';
      final uri = Uri.parse(url);

      try {
        final response = await http
            .get(uri, headers: {'Authorization': 'Bearer ${AuthService.token}'});

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
  final int selectedIndex;
  final int correctIndex;

  const LabeledCheckboxExample({
    required this.sentences,
    required this.value,
    required this.onChanged,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this option is correct
    bool isCorrect = index == correctIndex;
    // Determine if this option was selected by user
    bool isSelected = index == selectedIndex;

    // Determine background color based on state
    Color backgroundColor;
    Color borderColor;

    if (isSelected && isCorrect) {
      // User selected correct answer - green
      backgroundColor = AppColors.secondary.withOpacity(0.15);
      borderColor = AppColors.secondary;
    } else if (isSelected && !isCorrect) {
      // User selected wrong answer - red
      backgroundColor = AppColors.error.withOpacity(0.15);
      borderColor = AppColors.error;
    } else if (!isSelected && isCorrect) {
      // Correct answer but not selected - green outline
      backgroundColor = AppColors.secondary.withOpacity(0.08);
      borderColor = AppColors.secondary;
    } else {
      // Other options - default
      backgroundColor = AppColors.surface;
      borderColor = AppColors.accent.withOpacity(0.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: (isSelected || isCorrect) ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: (isSelected || isCorrect) ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect
                    ? AppColors.secondary
                    : (isSelected ? AppColors.error : Colors.transparent),
                border: Border.all(
                  color: isCorrect
                      ? AppColors.secondary
                      : (isSelected
                          ? AppColors.error
                          : AppColors.accent.withOpacity(0.3)),
                  width: 2,
                ),
              ),
              child: Icon(
                isCorrect
                    ? Icons.check_rounded
                    : (isSelected ? Icons.close_rounded : null),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                sentences,
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 15,
                  fontWeight: (isSelected || isCorrect)
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
