import 'package:flutter/material.dart';

class TombolAman extends StatefulWidget {
  const TombolAman({super.key});

  @override
  State<TombolAman> createState() {
    return _TombolAmanState();
  }
}

class _TombolAmanState extends State<TombolAman> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
      appBar: AppBar(
        title: const Text('TombolAman'),
      ),
      body: const Center(
        child: Text(
          'TombolAman Screen',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
