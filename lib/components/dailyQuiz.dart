import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Empuan/components/jawabanDailyQuiz.dart';
import 'package:Empuan/config/api_config.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/styles/style.dart';
import 'package:http/http.dart' as http;

class DailyQuiz extends StatefulWidget {
  const DailyQuiz({Key? key}) : super(key: key);

  @override
  State<DailyQuiz> createState() => _DailyQuizState();
}

class _DailyQuizState extends State<DailyQuiz> {
  // Page Controller
  final PageController _pageController = PageController();

  // List Soal (Hanya ID dan Text Soal)
  List<dynamic> questionsList = [];
  bool isLoadingQuestions = true;
  int currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => isLoadingQuestions = true);
    try {
      final url = '${ApiConfig.baseUrl}/questions';
      final response = await http.get(Uri.parse(url),
          headers: {'Authorization': 'Bearer ${AuthService.token}'});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = json['data'] ?? [];

        questionsList.clear();
        for (var item in list) {
          // Filter Active (String atau Boolean)
          var active = item['active'];
          bool isActive = (active == true ||
              active == 1 ||
              active.toString().toLowerCase() == 'true');

          if (isActive) {
            questionsList.add(item);
          }
        }
      }
    } catch (e) {
      print("Error fetching questions: $e");
    } finally {
      setState(() => isLoadingQuestions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surface,
              AppColors.accent.withOpacity(0.1)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    questionsList.isEmpty
                        ? "Daily Quiz"
                        : "Daily Quiz (${currentQuestionIndex + 1}/${questionsList.length})",
                    style: const TextStyle(
                        fontFamily: 'Brodies',
                        fontSize: 24,
                        color: AppColors.primary),
                  )
                ]),
              ),

              // --- BODY ---
              Expanded(
                child: isLoadingQuestions
                    ? const Center(child: CircularProgressIndicator())
                    : questionsList.isEmpty
                        ? const Center(child: Text("No Questions Available"))
                        : PageView.builder(
                            controller: _pageController,
                            physics:
                                const NeverScrollableScrollPhysics(), // Matikan swipe manual agar data aman
                            itemCount: questionsList.length,
                            onPageChanged: (idx) {
                              setState(() => currentQuestionIndex = idx);
                            },
                            // RAHASIA FIX: Menggunakan Widget Terpisah untuk setiap halaman soal
                            itemBuilder: (context, index) {
                              return QuizPageItem(
                                questionData: questionsList[index],
                                isLastQuestion:
                                    index == questionsList.length - 1,
                                onNext: () {
                                  if (index < questionsList.length - 1) {
                                    _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut);
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET BARU: QUIZ PAGE ITEM
// Widget ini mengisolasi data setiap soal agar tidak tertukar.
// ---------------------------------------------------------------------------
class QuizPageItem extends StatefulWidget {
  final dynamic questionData;
  final bool isLastQuestion;
  final VoidCallback onNext;

  const QuizPageItem({
    Key? key,
    required this.questionData,
    required this.isLastQuestion,
    required this.onNext,
  }) : super(key: key);

  @override
  State<QuizPageItem> createState() => _QuizPageItemState();
}

class _QuizPageItemState extends State<QuizPageItem> {
  List<dynamic> options = [];
  bool isLoadingOptions = true;
  int? selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  // Fetch opsi HANYA untuk soal ini
  Future<void> _fetchOptions() async {
    final qId = widget.questionData['id'];
    try {
      final url = '${ApiConfig.baseUrl}/questions/$qId/options';
      final response = await http.get(Uri.parse(url),
          headers: {'Authorization': 'Bearer ${AuthService.token}'});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          options = json['data'] ?? [];
          isLoadingOptions = false;
        });
      }
    } catch (e) {
      print("Error options: $e");
      setState(() => isLoadingOptions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String questionText = widget.questionData['questions'].toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Icon
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.error,
            child: Icon(Icons.quiz, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),

          // Teks Soal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            child: Text(questionText,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),

          const SizedBox(height: 32),

          // List Opsi
          if (isLoadingOptions)
            const CircularProgressIndicator()
          else
            ...List.generate(options.length, (index) {
              bool isSelected = (selectedOptionIndex == index);
              return GestureDetector(
                onTap: () {
                  setState(() => selectedOptionIndex = index);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.error
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1)),
                  child: Row(children: [
                    Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.error : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(options[index]['option_text'].toString()))
                  ]),
                ),
              );
            }),

          const SizedBox(height: 32),

          // Tombol Check Answer
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            onPressed: (selectedOptionIndex == null)
                ? null
                : () async {
                    // KIRIM DATA YANG BENAR KE HALAMAN HASIL
                    await Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (context) => JawabanDailyQuiz(
                          selectedindex: selectedOptionIndex!,
                          isLastQuestion: widget.isLastQuestion,
                          // Data Soal SAAT INI (dijamin benar karena ada di widget ini)
                          questionText: questionText,
                          correctAnswerText:
                              widget.questionData['correct_answer'].toString(),
                          currentOptions: options,
                        ),
                      ),
                    );

                    // Panggil callback untuk geser halaman di parent
                    widget.onNext();
                  },
            child: const Text("Check Answer",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
