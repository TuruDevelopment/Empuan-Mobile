import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Empuan/components/checkBoxSignUp.dart';
import 'package:Empuan/components/jawabanDailyQuiz.dart';
import 'package:Empuan/screens/HomePage.dart';
import 'package:Empuan/screens/home.dart';
import 'package:Empuan/services/auth_service.dart';
import 'package:Empuan/signUp/question2.dart';
import 'package:Empuan/start_page.dart';
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
  int selectedIndex = 0; // Tambahkan variabel selectedIndex

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
    var appBar = AppBar();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppBar(
                  toolbarHeight: 70,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  height: (MediaQuery.of(context).size.height -
                      appBar.preferredSize.height),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        // 'Is your menstrual cycle regular\n(varies by no more 7 days) ?',
                        dataQuestion.isNotEmpty
                            ? dataQuestion[0]['questions'].toString()
                            : '',
                        style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 17,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                checkListItems.length,
                                (index) => LabeledCheckboxExample(
                                  index: index,
                                  sentences: checkListItems[index]["title"],
                                  value: checkListItems[index]["selected"],
                                  onChanged: (value) {
                                    setState(() {
                                      for (var i = 0;
                                          i < checkListItems.length;
                                          i++) {
                                        if (i == index) {
                                          checkListItems[i]["selected"] = true;
                                          selectedIndex =
                                              index; // Update selectedIndex
                                        } else {
                                          checkListItems[i]["selected"] = false;
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 25),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromRGBO(251, 111, 146, 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: TextButton(
                                      child: const Text(
                                        'Save & Next',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        // Perform action based on selected option
                                        // For example, navigate to the next page
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    JawabanDailyQuiz(
                                                      selectedindex:
                                                          selectedIndex, // Gunakan selectedIndex
                                                    )));
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final url = 'http://10.0.2.2:8000/api/questions';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});
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
      final url = 'http://10.0.2.2:8000/api/questions/$idQuestion/options';
      final uri = Uri.parse(url);

      try {
        final response = await http
            .get(uri, headers: {'Authorization': '${AuthService.token}'});

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
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              color: AppColors.bg1, borderRadius: BorderRadius.circular(10)),
          child: CheckboxListTile(
            // controlAffinity: ListTileControlAffinity.leading,
            // contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              sentences,
              style: const TextStyle(
                  fontSize: 16.0, color: Colors.black, fontFamily: 'Satoshi'),
            ),
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Optionally
              side: const BorderSide(color: Colors.pink),
            ),
            activeColor: const Color.fromRGBO(251, 111, 146, 1),
            checkboxShape: CircleBorder(),
          ),
        ),
        SizedBox(
          height: 10,
        )
      ],
    );
  }
}
