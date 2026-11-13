import 'package:flutter/material.dart';

import '../data/pharmacy_profile.dart';
import 'pharmacy_profile_form.dart';

/// When the pharmacy is open and what it offers, saved to the server.
/// Patients see these hours when they choose a pharmacy.
class PharmacyProfessionalPage extends StatelessWidget {
  const PharmacyProfessionalPage({super.key, this.repository});

  final PharmacyProfileRepository? repository;

  @override
  Widget build(BuildContext context) {
    return PharmacyProfileForm(
      title: 'Hours and Services',
      selectedItemId: 'professional',
      repository: repository,
      includeHours: true,
      includeServices: true,
    );
  }
}
