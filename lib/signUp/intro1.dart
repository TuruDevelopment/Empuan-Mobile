import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:tumpuan/signUp/intro2.dart';
import 'package:tumpuan/styles/style.dart';

class Intro1 extends StatefulWidget {
  const Intro1({super.key});

  @override
  State<Intro1> createState() => _Intro1State();
}

class _Intro1State extends State<Intro1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Image(image: AssetImage('images/intro1.png')),
            const SizedBox(height: 15),
            const Text(
              'Breaking Stereotypes,\nEmpowering Women',
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.bold,
                  color: AppColors.pink1,
                  fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tumpuan App Paves the Way for\nGender Equality in Indonesia',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  // fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 15),
            ),
            const SizedBox(height: 80),
            DotsIndicator(
              dotsCount: 3,
              position: 0,
              decorator: const DotsDecorator(
                color: AppColors.bg1,
                activeColor: AppColors.pink1,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 75,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) => const Intro2()));
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromRGBO(251, 111, 146, 1))),
                child: const Text(
                  'Next',
                  style: TextStyle(fontFamily: 'Satoshi'),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
