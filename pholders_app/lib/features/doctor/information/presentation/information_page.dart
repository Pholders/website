import 'package:flutter/material.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Information Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}