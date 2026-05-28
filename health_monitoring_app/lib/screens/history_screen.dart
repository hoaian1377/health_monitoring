import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Lịch sử dùng thuốc', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
