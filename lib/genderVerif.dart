import 'dart:io';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:tumpuan/accountCred.dart';
import 'package:tumpuan/screens/takePhoto.dart';
import 'package:tumpuan/start_page.dart';
import 'package:tumpuan/styles/style.dart';

class GenderVerifPage extends StatefulWidget {
  // const GenderVerifPage({Key? key}) : super(key: key);

  final String name;
  final String dob;
  final String email;

  const GenderVerifPage({
    Key? key,
    required this.name,
    required this.dob,
    required this.email,
  }) : super(key: key);

  @override
  State<GenderVerifPage> createState() => _GenderVerifPageState();
}

class _GenderVerifPageState extends State<GenderVerifPage> {
  File? _image;

  @override
  Widget build(BuildContext context) {
    bool isImageUploaded = _image != null;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
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
                      onPressed: () => _showCloseDialog(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                    ),
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
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearPercentIndicator(
                    lineHeight: 3.0,
                    percent: 0.67,
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
                      'Gender Verification',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _image == null
                    ? IconButton(
                        icon: Image.asset('images/ktp.png'),
                        iconSize: 300,
                        onPressed: () async {
                          final pickedImage = await Navigator.push<File?>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageSelectionPage(),
                            ),
                          );
                          setState(() {
                            _image = pickedImage ?? File('images/ktp.png');
                          });
                        },
                      )
                    : Container(
                        height: 400,
                        width: 300,
                        child: Image.file(_image!),
                      ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Make sure to take a clear picture of your ID',
                      style: TextStyle(fontFamily: 'Satoshi', fontSize: 12),
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
                        child: Center(
                          child: TextButton(
                            child: const Text(
                              'Back',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: isImageUploaded
                              ? const Color.fromRGBO(251, 111, 146, 1)
                              : Colors
                                  .grey, // Disable button when no image is uploaded
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: TextButton(
                            child: const Text(
                              'Save & Next',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: isImageUploaded
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AccountCred(
                                          name: widget.name,
                                          dob: widget.dob,
                                          email: widget.email,
                                        ),
                                      ),
                                    );
                                  }
                                : null, // Disable button when no image is uploaded
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
