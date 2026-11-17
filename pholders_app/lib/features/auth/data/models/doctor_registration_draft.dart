/// The personal details captured on step 1 of doctor registration.
///
/// Registration is split across two pages but the backend takes a single
/// `POST /users/doctor/signup` call, so step 1 hands this to step 2 through
/// GoRouter's `extra` and step 2 submits both halves together.
class DoctorRegistrationDraft {
  const DoctorRegistrationDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
}
