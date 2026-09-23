import 'package:equatable/equatable.dart';

/// A doctor as returned by the backend.
///
/// Two endpoints return a doctor in two different shapes:
///  * `POST /users/doctor/login` returns a camelCase summary
///    (`doctorId`, `firstName`, `hpcsaNumber`, …),
///  * `GET  /users/doctor/profile` returns the full snake_case database row
///    (`id`, `first_name`, `hpcsa_number`, …).
///
/// [Doctor.fromJson] accepts either, so callers do not have to care.
class Doctor extends Equatable {
  const Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.hpcsaNumber,
    this.specialization,
    this.experience,
    this.clinicName,
    this.clinicAddress,
    this.city,
    this.province,
    this.zipCode,
    this.qualification,
    this.bio,
    this.profileImage,
    this.consultationFee,
    this.currency,
    this.rating,
    this.reviewCount,
    this.status,
    this.emailVerified = false,
  });

  /// Builds a [Doctor] from either the login or the profile payload.
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: _asInt(json['id'] ?? json['doctorId']) ?? 0,
      firstName: _asString(json['first_name'] ?? json['firstName']) ?? '',
      lastName: _asString(json['last_name'] ?? json['lastName']) ?? '',
      email: _asString(json['email']) ?? '',
      phone: _asString(json['phone']),
      hpcsaNumber: _asString(json['hpcsa_number'] ?? json['hpcsaNumber']),
      specialization: _asString(json['specialization']),
      experience: _asInt(json['experience']),
      clinicName: _asString(json['clinic_name'] ?? json['clinicName']),
      clinicAddress: _asString(json['clinic_address'] ?? json['clinicAddress']),
      city: _asString(json['city']),
      province: _asString(json['province']),
      zipCode: _asString(json['zip_code'] ?? json['zipCode']),
      qualification: _asString(json['qualification']),
      bio: _asString(json['bio']),
      profileImage: _asString(json['profile_image'] ?? json['profileImage']),
      consultationFee: _asDouble(json['consultation_fee']),
      currency: _asString(json['currency']),
      rating: _asDouble(json['rating']),
      reviewCount: _asInt(json['review_count']),
      status: _asString(json['status']),
      emailVerified: json['email_verified'] == true,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? hpcsaNumber;
  final String? specialization;
  final int? experience;
  final String? clinicName;
  final String? clinicAddress;
  final String? city;
  final String? province;
  final String? zipCode;
  final String? qualification;
  final String? bio;
  final String? profileImage;
  final double? consultationFee;
  final String? currency;
  final double? rating;
  final int? reviewCount;
  final String? status;
  final bool emailVerified;

  /// "John Smith", or the email local part when the name is missing.
  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email.split('@').first : name;
  }

  /// "Dr John Smith" — for headers and prescription previews.
  String get displayName => 'Dr $fullName';

  // Postgres returns NUMERIC columns as strings over JSON ("-26.20227000"),
  // and the two endpoints disagree on int vs string ids, so every field is
  // parsed defensively rather than cast.
  static String? _asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [id, firstName, lastName, email, hpcsaNumber];
}
