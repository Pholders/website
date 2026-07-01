import 'package:flutter/material.dart';
import 'package:doctor_app/screens/patients_screen.dart';
import 'package:doctor_app/screens/patient_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF4FAFA),
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2EC4C4)),
        useMaterial3: true,
      ),
      home: const _AppEntry(),
    );
  }
}

/// Temporary root widget — holds the nav state until your colleagues
/// connect their navigation shell. Once they do, replace this entire
/// widget with their shell and remove this file's _AppEntry class.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  Patient? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedPatient != null
          ? PatientProfileScreen(
              patient: _selectedPatient!,
              onBack: () => setState(() => _selectedPatient = null),
            )
          : PatientsScreen(
              onPatientTap: (p) =>
                  setState(() => _selectedPatient = p),
            ),
    );
  }
}
