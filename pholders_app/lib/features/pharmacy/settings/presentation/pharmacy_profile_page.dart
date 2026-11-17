import 'package:flutter/material.dart';

import '../data/pharmacy_profile.dart';
import 'pharmacy_details_page.dart';
import 'pharmacy_profile_form.dart';

/// Personal and pharmacy details on one page, saved to the server.
class PharmacyProfilePage extends StatelessWidget {
  const PharmacyProfilePage({super.key, this.repository});

  final PharmacyProfileRepository? repository;

  @override
  Widget build(BuildContext context) {
    return PharmacyProfileForm(
      title: 'Pharmacy Profile',
      selectedItemId: 'profile',
      repository: repository,
      sections: const [
        ProfileSection('Personal Information', [
          ProfileField('first_name', 'First Name', required: true),
          ProfileField('last_name', 'Surname', required: true),
          ProfileField('email', 'Email', readOnly: true),
          ProfileField('phone', 'Mobile'),
        ]),
        ...pharmacyDetailsSections,
      ],
    );
  }
}
