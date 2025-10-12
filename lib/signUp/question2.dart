import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:tumpuan/services/auth_service.dart';

import 'package:tumpuan/signUp/question3.dart';
import 'package:tumpuan/start_page.dart';
import 'package:tumpuan/styles/style.dart';
import 'package:http/http.dart' as http;

class Question2 extends StatefulWidget {
  // const Question2({Key? key}) : super(key: key);

  final String username;
  final String password;
  const Question2({
    Key? key,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<Question2> createState() => _Question2State();
}

class _Question2State extends State<Question2> {
  late TextEditingController dateInputController;
  late TextEditingController dateInputControllerend;
  bool dontKnowSelected = false;

  @override
  void initState() {
    super.initState();
    dateInputController = TextEditingController();
    dateInputControllerend = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    print("last username: ${widget.username}");
    print("last password: ${widget.password}");

    getIdByUsername(widget.username).then((userId) {
      if (userId != null) {
        print('User ID: $userId');
        // Lakukan apa pun yang perlu Anda lakukan dengan user ID di sini
      } else {
        print('Failed to get user ID');
      }
    });

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
                    percent: 0.5,
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
                      'Question 2',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w900,
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                const Text(
                  'When did your last period start ?',
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
                                      DateFormat('yyyy-MM-dd')
                                          .format(pickedDate);
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
                  height: 10,
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
                                  dontKnowSelected = false;
                                });
                                DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime(2050),
                                );

                                if (pickedDate != null) {
                                  dateInputControllerend.text =
                                      DateFormat('yyyy-MM-dd')
                                          .format(pickedDate);
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
                const SizedBox(height: 150),
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
                        child: Center(
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
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: ((dateInputController.text.isNotEmpty &&
                                      !dontKnowSelected) ||
                                  dontKnowSelected)
                              ? const Color.fromRGBO(251, 111, 146, 1)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: TextButton(
                            onPressed: () async {
                              // if (dateInputController.text.isNotEmpty ||
                              //     dontKnowSelected) {
                              //   Navigator.of(context).push(MaterialPageRoute(
                              //       builder: (context) => const Question3()));
                              // } else {
                              //   // Show a snackbar or dialog to inform the user to fill the required fields.
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(
                              //         content: Text(
                              //             'Please select a date or check "I don\'t know".')),
                              //   );
                              // }
                              if (dateInputController.text.isNotEmpty ||
                                  dontKnowSelected) {
                                // Lakukan login otomatis dengan username dan password yang diberikan
                                await doLogin();

                                // Ambil ID berdasarkan username
                                final userId =
                                    await getIdByUsername(widget.username);

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
                              } else {
                                // Show a snackbar or dialog to inform the user to fill the required fields.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please select a date or check "I don\'t know".')),
                                );
                              }
                            },
                            child: const Text(
                              'Save & Next',
                              style: TextStyle(color: Colors.white),
                            ),
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

  doLogin() async {
    final username = widget.username;
    final password = widget.password;

    bool isSuccess =
        await AuthService().login(username: username, password: password);

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
  final bool value;
  final ValueChanged<bool>? onChanged;

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
            onChanged:
                onChanged != null ? (newValue) => onChanged!(newValue!) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: const BorderSide(color: Colors.pink),
            ),
            activeColor: const Color.fromRGBO(251, 111, 146, 1),
            checkboxShape: const CircleBorder(),
          ),
        ),
        const SizedBox(
          height: 10,
        )
      ],
    );
  }
}
