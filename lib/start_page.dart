import 'package:flutter/material.dart';
import 'package:Empuan/login_page.dart';
import 'package:Empuan/screens/playVideo.dart';
import 'package:Empuan/signUp/intro1.dart';

// Temporary
import 'package:Empuan/signUp/intro.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Empuan',
              style: TextStyle(
                  fontFamily: 'Brodies',
                  color: Color.fromRGBO(251, 111, 146, 1),
                  fontSize: 40),
            ),
            const Text(
              'Tempat Untuk Menguatkan Perempuan',
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: Color.fromRGBO(251, 111, 146, 1),
                  fontSize: 13),
            ),
            const SizedBox(height: 200),
            SizedBox(
              width: 300,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const LoginPage()));
                  // Navigator.of(context).pushReplacement(MaterialPageRoute(
                  //     builder: (context) => const VideoApp()));
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromRGBO(251, 111, 146, 1))),
                child: const Text(
                  'Login',
                  style: TextStyle(
                      fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 300,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const Intro()));
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromRGBO(251, 111, 146, 1))),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                      fontFamily: 'Satoshi', fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
