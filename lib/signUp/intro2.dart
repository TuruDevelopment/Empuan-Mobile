import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:tumpuan/signUp/intro3.dart';
import 'package:tumpuan/styles/style.dart';

class Intro2 extends StatefulWidget {
  const Intro2({super.key});

  @override
  State<Intro2> createState() => _Intro2State();
}

class _Intro2State extends State<Intro2> {
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
            const Image(image: AssetImage('images/intro2.png')),
            const SizedBox(height: 15),
            const Text(
              'Safe Spaces, Collectiove Growth',
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.bold,
                  color: AppColors.pink1,
                  fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tumpuan App Fosters Women\'s\nEmpowerment and Equality',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Satoshi',
                  // fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 15),
            ),
            const SizedBox(height: 100),
            DotsIndicator(
              dotsCount: 3,
              position: 1,
              decorator: const DotsDecorator(
                color: AppColors.bg1,
                activeColor: AppColors.pink1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 7.0),
                  child: SizedBox(
                    width: 75,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              const Color.fromRGBO(251, 111, 146, 1))),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontFamily: 'Satoshi'),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7.0),
                  child: SizedBox(
                    width: 75,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const Intro3()));
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
                ),
              ],
            ),
          ],
        ),
      )),
    );
  }
}
