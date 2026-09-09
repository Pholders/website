import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/doctor.dart';

/// The result of a successful doctor login: a JWT plus the signed-in doctor.
class DoctorSession {
  const DoctorSession({required this.token, required this.doctor});

  final String token;
  final Doctor doctor;
}

/// All doctor authentication calls.
///
/// The endpoint contracts here were verified against the live API and the
/// backend controllers, NOT against `docs/api/roles/DOCTOR_ENDPOINTS.md`,
/// which is out of date in several places (see the notes on each method).
class DoctorAuthRepository {
  const DoctorAuthRepository(this._api);

  final ApiClient _api;

  /// Registers a new doctor.
  ///
  /// Every parameter is required by the backend — it rejects the request with
  /// a 400 listing all of them if any is missing.
  ///
  /// [clinicAddress] must be a place name the Open-Meteo geocoder recognises
  /// (e.g. "Johannesburg"). A full street address fails geocoding and the
  /// whole signup is rejected with a 400. See [isGeocodingFailure].
  Future<Doctor> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String hpcsaNumber,
    required String specialization,
    required int experience,
    required String clinicName,
    required String city,
    required String province,
    required String clinicAddress,
  }) async {
    final data = await _api.post(
      '/users/doctor/signup',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'hpcsa_number': hpcsaNumber,
        'specialization': specialization,
        'experience': experience,
        'clinic_name': clinicName,
        'city': city,
        'province': province,
        'clinic_address': clinicAddress,
      },
    );

    final doctor = data['doctor'];
    if (doctor is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Registration succeeded but the server returned no profile.',
        kind: ApiErrorKind.badResponse,
      );
    }
    return Doctor.fromJson(doctor);
  }

  /// Signs a doctor in and returns their session.
  ///
  /// Despite what the API docs claim, this endpoint does **not** issue an OTP
  /// challenge — it returns the JWT directly in `data.token`. There is no
  /// second step, and email verification is not enforced at login.
  Future<DoctorSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/users/doctor/login',
      body: {'email': email, 'password': password},
    );

    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        message: 'Sign in succeeded but the server returned no token.',
        kind: ApiErrorKind.badResponse,
      );
    }

    return DoctorSession(token: token, doctor: Doctor.fromJson(data));
  }

  /// Activates an account with the OTP emailed after signup.
  ///
  /// The field is `otp_code`, not `otp` as the docs state, and it is keyed by
  /// email rather than by a session id.
  Future<void> verifyEmail({
    required String email,
    required String otpCode,
  }) async {
    await _api.post(
      '/users/doctor/verify-email',
      body: {'email': email, 'otp_code': otpCode},
    );
  }

  /// Requests a fresh activation code, returning it when the backend hands it
  /// back rather than emailing it.
  ///
  /// Rate-limited to one code per 60 seconds (429 otherwise). The response is
  /// deliberately generic — it does not reveal whether the account exists.
  ///
  /// While the server runs with `NODE_ENV=development` it includes the code in
  /// the response as `data.verification_code`; in production that field is
  /// absent and the code only arrives by email.
  Future<String?> resendVerification({required String email}) async {
    final data = await _api.post(
      '/users/doctor/resend-verification',
      body: {'email': email},
    );
    final code = data['verification_code'];
    return code is String && code.isNotEmpty ? code : null;
  }

  /// Fetches the full profile of the signed-in doctor.
  Future<Doctor> fetchProfile() async {
    final data = await _api.get('/users/doctor/profile');
    return Doctor.fromJson(data);
  }

  /// Revokes the current session server-side. Safe to ignore failures — the
  /// client clears its own token regardless.
  Future<void> logout() async {
    await _api.post('/users/doctor/logout');
  }

  /// True when a signup failed because the address could not be geocoded,
  /// so the UI can point at the address field specifically.
  static bool isGeocodingFailure(ApiException e) =>
      e.statusCode == 400 && e.message.toLowerCase().contains('geocode');
}
