import 'package:flutter/material.dart';

import '../data/pharmacy_profile.dart';
import 'pharmacy_profile_form.dart';

/// The pharmacist's own name and contact number, saved to the server.
class PharmacyPersonalInfoPage extends StatelessWidget {
  const PharmacyPersonalInfoPage({super.key, this.repository});

  final PharmacyProfileRepository? repository;

  @override
  Widget build(BuildContext context) {
    return PharmacyProfileForm(
      title: 'Personal Information',
      selectedItemId: 'personal_information',
      repository: repository,
      sections: const [
        ProfileSection(null, [
          ProfileField('first_name', 'First Name', required: true),
          ProfileField('last_name', 'Surname', required: true),
          ProfileField('email', 'Email', readOnly: true),
          ProfileField('phone', 'Mobile', hint: '+27 82 123 4567'),
        ]),
      ],
    );
  }
}
