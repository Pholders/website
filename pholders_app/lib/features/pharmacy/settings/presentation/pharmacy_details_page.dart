import 'package:flutter/material.dart';

import '../data/pharmacy_profile.dart';
import 'pharmacy_profile_form.dart';

/// The pharmacy's name and where it is, saved to the server.
class PharmacyDetailsPage extends StatelessWidget {
  const PharmacyDetailsPage({super.key, this.repository});

  final PharmacyProfileRepository? repository;

  @override
  Widget build(BuildContext context) {
    return PharmacyProfileForm(
      title: 'Pharmacy Details',
      selectedItemId: 'pharmacy_details',
      repository: repository,
      sections: pharmacyDetailsSections,
    );
  }
}

/// Also shown on the combined profile page.
const pharmacyDetailsSections = [
  ProfileSection(null, [
    ProfileField('pharmacy_name', 'Pharmacy Name', required: true),
    ProfileField('license_number', 'Registration Number', readOnly: true),
  ]),
  ProfileSection('Location', [
    ProfileField('address', 'Street Address'),
    ProfileField('city', 'City', required: true),
    ProfileField('province', 'Province', required: true),
    ProfileField('zip_code', 'Postal Code'),
  ]),
];
