import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:tumpuan/components/checkBoxSignUp.dart';
import 'package:tumpuan/signUp/question4.dart';
import 'package:tumpuan/start_page.dart';
import 'package:tumpuan/styles/style.dart';

class Question3 extends StatefulWidget {
  const Question3({Key? key}) : super(key: key);

  @override
  State<Question3> createState() => _Question3State();
}

class _Question3State extends State<Question3> {
  List<Map<String, dynamic>> checkListItems = [
    {"id": 0, "selected": false, "title": 'No, I sleep well'},
    {"id": 1, "selected": false, "title": 'Difficulty falling asleep'},
    {"id": 2, "selected": false, "title": 'Waking up tired'},
    {"id": 3, "selected": false, "title": 'Waking up during the night'},
    {"id": 4, "selected": false, "title": 'Lack of sleep schedule'},
    {"id": 5, "selected": false, "title": 'Insomnia'},
    {"id": 6, "selected": false, "title": 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                AppBar(
                  toolbarHeight: 70,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      onPressed: () {
                        _showCloseDialog(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                    )
                  ],
                  title: const Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Tumpuan',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Brodies',
                        color: Color.fromRGBO(251, 111, 146, 1),
                        fontSize: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearPercentIndicator(
                    lineHeight: 3.0,
                    percent: 0.75,
                    backgroundColor: Colors.grey,
                    progressColor: AppColors.pink1,
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 25.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Question 3',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w900,
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Is there anything you want to\nimprove about your sleep?',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      checkListItems.length,
                      (index) => LabeledCheckboxExample(
                        sentences: checkListItems[index]["title"],
                        value: checkListItems[index]["selected"],
                        onChanged: (value) {
                          setState(() {
                            for (var i = 0; i < checkListItems.length; i++) {
                              if (i == index) {
                                checkListItems[i]["selected"] = value ?? false;
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(251, 111, 146, 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Back',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: _isAnyOptionSelected()
                              ? const Color.fromRGBO(251, 111, 146, 1)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: _isAnyOptionSelected()
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const Question4(),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text(
                            'Save & Next',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isAnyOptionSelected() {
    return checkListItems.any((item) => item['selected'] == true);
  }

  Future<void> _showCloseDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image(image: AssetImage('images/cancelRegist.png')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.pink1),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Yes', style: TextStyle(color: AppColors.pink1)),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const StartPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class LabeledCheckboxExample extends StatelessWidget {
  final String sentences;
  final bool? value;
  final ValueChanged<bool?>? onChanged;

  const LabeledCheckboxExample({
    required this.sentences,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CheckboxListTile(
            dense: true,
            title: Text(
              sentences,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black,
                fontFamily: 'Satoshi',
              ),
            ),
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: const BorderSide(color: Colors.pink),
            ),
            activeColor: const Color.fromRGBO(251, 111, 146, 1),
            checkboxShape: const CircleBorder(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
