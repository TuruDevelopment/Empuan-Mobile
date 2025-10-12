import 'package:flutter/material.dart';

class SaloonPage extends StatefulWidget {
  const SaloonPage({super.key});

  @override
  State<SaloonPage> createState() {
    return _SaloonPageState();
  }
}

class _SaloonPageState extends State<SaloonPage> {
  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(left: 20.0, bottom: 20, right: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Color.fromARGB(255, 255, 26, 26),
              ),
              height: 200,
              width: MediaQuery.of(context).size.width,
            ),
          );
        },
        childCount: 20,
      ),
    );
  }
}
