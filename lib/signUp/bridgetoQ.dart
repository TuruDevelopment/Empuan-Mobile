import 'package:flutter/material.dart';
import 'package:tumpuan/signUp/question1.dart';
import 'package:tumpuan/signUp/questions.dart';

class BridgetoQ extends StatefulWidget {
  // const BridgetoQ({super.key});

  final String username;
  final String password;
  const BridgetoQ({
    Key? key,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<BridgetoQ> createState() => _BridgetoQState();
}

class _BridgetoQState extends State<BridgetoQ> {
  @override
  Widget build(BuildContext context) {
    print('Username cekkk: ${widget.username}');
    return Scaffold(
      backgroundColor: const Color.fromRGBO(237, 237, 237, 1),
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Image(image: AssetImage('images/bridging.png')),
            const SizedBox(height: 50),
            SizedBox(
              width: 300,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => 
                      // Question1(
                      //       username: widget.username,
                      //       password: widget.password,
                      // )
                      questions(username: widget.username, password: widget.password,),
                      ));
                },
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromRGBO(251, 111, 146, 1))),
                child: const Text(
                  'Next',
                  style: TextStyle(fontFamily: 'Satoshi',
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
