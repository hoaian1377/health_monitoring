import 'package:flutter/material.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Checklist', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
