import 'package:flutter/material.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() {
    return _PageHomeState();
  }
}

class _PageHomeState extends State<PageHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
      appBar: AppBar(
        title: const Text('PageHome'),
      ),
      body: const Center(
        child: Text(
          'PageHome Screen',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
