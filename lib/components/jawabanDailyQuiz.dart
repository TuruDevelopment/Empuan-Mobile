import 'package:flutter/material.dart';
import 'package:Empuan/screens/navScreen.dart';
import 'package:Empuan/styles/style.dart';

class JawabanDailyQuiz extends StatefulWidget {
  final int selectedindex;
  final bool isLastQuestion;
  // Data yang diterima dari halaman soal
  final String questionText;
  final String correctAnswerText;
  final List<dynamic> currentOptions;

  const JawabanDailyQuiz({
    Key? key,
    required this.selectedindex,
    required this.isLastQuestion,
    required this.questionText,
    required this.correctAnswerText,
    required this.currentOptions,
  }) : super(key: key);

  @override
  State<JawabanDailyQuiz> createState() => _JawabanDailyQuizState();
}

class _JawabanDailyQuizState extends State<JawabanDailyQuiz> {
  bool isCorrect = false;
  List<Map<String, dynamic>> displayedOptions = [];

  @override
  void initState() {
    super.initState();
    _calculateResult();
  }

  void _calculateResult() {
    // 1. Validasi
    if (widget.selectedindex < 0 ||
        widget.selectedindex >= widget.currentOptions.length) {
      return;
    }

    // 2. Cek Jawaban
    String selectedText =
        widget.currentOptions[widget.selectedindex]['option_text'].toString();
    String correctText = widget.correctAnswerText.toString();

    // Bandingkan dengan menghapus spasi dan lowercase agar akurat
    isCorrect =
        selectedText.trim().toLowerCase() == correctText.trim().toLowerCase();

    // 3. Siapkan data untuk tampilan
    displayedOptions.clear();
    for (int i = 0; i < widget.currentOptions.length; i++) {
      var opt = widget.currentOptions[i];
      String txt = opt['option_text'].toString();

      // Cek apakah opsi ini adalah jawaban yang benar (untuk visual hijau)
      bool isActuallyCorrect =
          txt.trim().toLowerCase() == correctText.trim().toLowerCase();

      displayedOptions.add({
        "text": txt,
        "isSelected": i == widget.selectedindex,
        "isCorrectKey": isActuallyCorrect
      });
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
              // HEADER
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const MainScreen())),
                    icon: const Icon(Icons.close, color: AppColors.primary),
                  ),
                  const Text('Quiz Result',
                      style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // ICON HASIL
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 80,
                        color:
                            isCorrect ? AppColors.secondary : AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(isCorrect ? "Correct!" : "Incorrect",
                          style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? AppColors.secondary
                                  : AppColors.error)),

                      const SizedBox(height: 32),

                      // TEKS SOAL (Dari Data yang Dikirim)
                      Text(widget.questionText,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),

                      const SizedBox(height: 32),

                      // LIST OPSI
                      ...List.generate(displayedOptions.length, (index) {
                        var item = displayedOptions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  // Logika Warna Border: Hijau jika kunci benar, Merah jika user salah pilih
                                  color: item['isCorrectKey']
                                      ? AppColors.secondary
                                      : (item['isSelected']
                                          ? AppColors.error
                                          : Colors.grey.shade300),
                                  width: (item['isSelected'] ||
                                          item['isCorrectKey'])
                                      ? 2
                                      : 1)),
                          child: Row(children: [
                            Icon(
                              item['isCorrectKey']
                                  ? Icons.check
                                  : (item['isSelected']
                                      ? Icons.close
                                      : Icons.circle_outlined),
                              color: item['isCorrectKey']
                                  ? AppColors.secondary
                                  : (item['isSelected']
                                      ? AppColors.error
                                      : Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['text'],
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ]),
                        );
                      }),

                      const SizedBox(height: 32),

                      // TOMBOL NEXT
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          if (widget.isLastQuestion) {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => const MainScreen()));
                          } else {
                            Navigator.of(context)
                                .pop(true); // Kembali ke soal berikutnya
                          }
                        },
                        child: Text(
                            widget.isLastQuestion
                                ? "Finish Quiz"
                                : "Next Question",
                            style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
