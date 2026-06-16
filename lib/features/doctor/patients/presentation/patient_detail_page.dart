import 'package:flutter/material.dart';

/// PatientDetailPage — placeholder until Figma design is implemented.
class PatientDetailPage extends StatelessWidget {

  const PatientDetailPage({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('PatientDetailPage')),
    );
  }
}
