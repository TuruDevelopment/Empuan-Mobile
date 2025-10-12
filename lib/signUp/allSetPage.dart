import 'package:flutter/material.dart';
import 'package:tumpuan/login_page.dart';

class AllSetPage extends StatefulWidget {
  const AllSetPage({super.key});

  @override
  State<AllSetPage> createState() => _AllSetPageState();
}

class _AllSetPageState extends State<AllSetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Image(image: AssetImage('images/allset.png')),
            const SizedBox(height: 50),
            SizedBox(
              width: 300,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()));
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromRGBO(251, 111, 146, 1))),
                child: const Text(
                  'Login',
                  style: TextStyle(fontFamily: 'Satoshi', color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
