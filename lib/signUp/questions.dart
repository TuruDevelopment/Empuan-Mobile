import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:tumpuan/services/auth_service.dart';
import 'package:tumpuan/signUp/allSetPage.dart';
import 'package:tumpuan/signUp/question3.dart';
import 'package:tumpuan/start_page.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class questions extends StatefulWidget {
  // questions({Key? key}) : super(key: key);

  final String username;
  final String password;

  const questions({
    Key? key,
    required this.username,
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
        body: Stack(alignment: Alignment.center, children: [
      Column(children: [
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
        SizedBox(
          height: 10,
        ),
        Padding(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: LinearPercentIndicator(
            lineHeight: 3.0,
            percent:
                _currentProgressPercent(_currentPageIndex, progressPercentage),
            backgroundColor: Colors.grey,
            progressColor: AppColors.pink1,
          ),
        )
      ]),
      Positioned.fill(
          child: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageViewController,
        onPageChanged: _handlePageViewChanged,
        children: [
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Is your menstrual cycle regular\n(varies by no more 7 days) ?',
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
                    question1.length,
                    (index) => LabeledCheckboxExample(
                      sentences: question1[index]["title"],
                      value: question1[index]["selected"],
                      onChanged: (value) {
                        setState(() {
                          for (var i = 0; i < question1.length; i++) {
                            if (i == index) {
                              question1[i]["selected"] = true;
                            } else {
                              question1[i]["selected"] = false;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          )),
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'When did your last period start ?',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            controller: dateInputController,
                            readOnly: true,
                            onTap: () async {
                              setState(() {
                                dontKnowSelected = false;
                              });
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1950),
                                lastDate: DateTime(2050),
                              );

                              if (pickedDate != null) {
                                dateInputController.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              const Text(
                'When did your last period end ?',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            controller: dateInputControllerend,
                            readOnly: true,
                            onTap: () async {
                              setState(() {
                                dontKnowSelectedEnd = false;
                              });
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1950),
                                lastDate: DateTime(2050),
                              );

                              if (pickedDate != null) {
                                dateInputControllerend.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          )),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                      question3.length,
                      (index) => LabeledCheckboxExample(
                        sentences: question3[index]["title"],
                        value: question3[index]["selected"],
                        onChanged: (value) {
                          setState(() {
                            for (var i = 0; i < question3.length; i++) {
                              if (i == index) {
                                question3[i]["selected"] = value ?? false;
                              } else {
                                question3[i]["selected"] = false;
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Do you experience discomfort due\nto any of the following?',
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
                      question4.length,
                      (index) => LabeledCheckboxExample(
                        sentences: question4[index]["title"],
                        value: question4[index]["selected"],
                        onChanged: (value) {
                          setState(() {
                            for (var i = 0; i < question4.length; i++) {
                              if (i == index) {
                                question4[i]["selected"] = value ?? false;
                              } else {
                                question4[i]["selected"] = false;
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text(
                'What\'s your fitness goal?',
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
                    question5.length,
                    (index) => LabeledCheckboxExample(
                      sentences: question5[index]["title"],
                      value: question5[index]["selected"],
                      onChanged: (value) {
                        setState(() {
                          for (var i = 0; i < question5.length; i++) {
                            if (i == index) {
                              question5[i]["selected"] = value ?? false;
                            } else {
                              question5[i]["selected"] = false;
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      )),
      Positioned(
        bottom: 125,
        child: PageIndicator(
          tabController: _tabController,
          currentPageIndex: _currentPageIndex,
          onUpdateCurrentPageIndex: _updateCurrentPageIndex,
          isAnyOptionSelected: _isAnyOptionSelected(_currentPageIndex),
          dateInputController: dateInputController,
          dateInputControllerend: dateInputControllerend,
          dontKnowSelected: dontKnowSelected,
          dontKnowSelectedEnd: dontKnowSelectedEnd, username: widget.username,
          password: widget.password,
          // isOnDesktopAndWeb: _isOnDesktopAndWeb,
        ),
      )
    ]));
  }

  bool _isAnyOptionSelected(int currentPageIndex) {
    if (currentPageIndex == 0) {
      if (question1.any((item) => item['selected'] == true)) {
        return true;
      }
      ;
      return false;
    } else if (currentPageIndex == 2) {
      if (question3.any((item) => item['selected'] == true)) {
        return true;
      }
      ;
      return false;
    } else if (currentPageIndex == 3) {
      if (question4.any((item) => item['selected'] == true)) {
        return true;
      }
      ;
      return false;
    } else if (currentPageIndex == 4) {
      if (question5.any((item) => item['selected'] == true)) {
        return true;
      }
      ;
      return false;
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

_currentProgressPercent(var currentPageIndex, var progressPercentage) {
  if (currentPageIndex == 4) {
    return progressPercentage = 1.0;
  } else if (currentPageIndex == 3) {
    return progressPercentage = 0.8;
  } else if (currentPageIndex == 2) {
    return progressPercentage = 0.6;
  } else if (currentPageIndex == 1) {
    return progressPercentage = 0.4;
  } else if (currentPageIndex == 0) {
    return progressPercentage = 0.2;
  }
}

class PageIndicator extends StatelessWidget {
  PageIndicator({
    super.key,
    required this.tabController,
    required this.currentPageIndex,
    required this.onUpdateCurrentPageIndex,
    required this.isAnyOptionSelected,
    required this.dateInputController,
    required this.dateInputControllerend,
    required this.dontKnowSelected,
    required this.dontKnowSelectedEnd,
    required this.username,
    required this.password,
  });

  late TextEditingController dateInputController;
  late TextEditingController dateInputControllerend;
  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;
  bool isAnyOptionSelected;
  bool dontKnowSelected;
  bool dontKnowSelectedEnd;

  final String username;
  final String password;

  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.only(right: 7.0),
                  child: Visibility(
                    visible: visibleButton(currentPageIndex, _isVisible),
                    child: SizedBox(
                      width: 109,
                      child: FilledButton(
                        onPressed: () {
                          if (currentPageIndex == 0) {
                            return;
                          } else if (currentPageIndex != 0) {
                            progressPercentage -= 0.2;
                          }
                          onUpdateCurrentPageIndex(currentPageIndex - 1);
                        },
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                const Color.fromRGBO(251, 111, 146, 1))),
                        child: Text(
                          'Back',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(right: 7.0),
                child: SizedBox(
                  width: 109,
                  child: FilledButton(
                    onPressed: () async {
                      if (isAnyOptionSelected == false &&
                          currentPageIndex != 1) {
                        return;
                      }

                      if (currentPageIndex == 1) {
                        if (dateInputController.text.isEmpty ||
                            (dontKnowSelected == true &&
                                dontKnowSelectedEnd == true)) {
                          return;
                        }
                      }

                      if (currentPageIndex == 4) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const AllSetPage()));
                        return;
                      }

                      if (dateInputController.text.isNotEmpty ||
                          dontKnowSelected) {
                        // Lakukan login otomatis dengan username dan password yang diberikan
                        await doLogin();

                        // Ambil ID berdasarkan username
                        final userId = await getIdByUsername(username);

                        // Jika ID berhasil diperoleh, kirimkan data catatan haid
                        if (userId != null) {
                          print("masuk submit");
                          await submitData();
                        }
                        print("KESKIPPPP");
                        // Lakukan logout setelah submit data catatan haid
                        AuthService.logout();

                        // Pindah ke halaman selanjutnya
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const Question3()));
                      }

                      onUpdateCurrentPageIndex(currentPageIndex + 1);
                    },
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            const Color.fromRGBO(251, 111, 146, 1))),
                    child: Text(
                      'Next',
                      style: const TextStyle(
                        fontFamily: 'Satoshi',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]));
  }

  doLogin() async {
    final username2 = username;
    final password2 = password;

    bool isSuccess =
        await AuthService().login(username: username2, password: password2);

    if (!isSuccess) {
      print(isSuccess);
    } else {}
  }

  Future<String?> getIdByUsername(String username) async {
    final url = 'http://10.0.2.2:8000/api/users/username/$username';
    final uri = Uri.parse(url);
    final response =
        await http.get(uri, headers: {'Authorization': '${AuthService.token}'});

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

    final url = "http://10.0.2.2:8000/api/catatanhaids";
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Authorization': '${AuthService.token}'
    });

    print(response.statusCode);
    print(response.body);
  }
}

visibleButton(var currentPageIndex, bool isVisible) {
  if (currentPageIndex == 0) {
    return isVisible = false;
  }
  return true;
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
            child: const Text('Yes', style: TextStyle(color: AppColors.pink1)),
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
