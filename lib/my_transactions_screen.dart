import 'package:flutter/material.dart';

class MyTransactionsScreen extends StatelessWidget {
  const MyTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاملاتي'),
      ),
      body: const Center(
        child: Text(
          'صفحة معاملاتي',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
