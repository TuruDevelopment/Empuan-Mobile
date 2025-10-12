import 'package:flutter/material.dart';

class SpaPage extends StatefulWidget {
  const SpaPage({super.key});

  @override
  State<SpaPage> createState() {
    return _SpaPageState();
  }
}

class _SpaPageState extends State<SpaPage> {
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
                color: Color.fromARGB(255, 196, 119, 68),
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
