import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Trang chủ', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
