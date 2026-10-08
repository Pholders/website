import 'package:dio/dio.dart';

import '../../../shared/constants/app_constants.dart';
import 'models/qr_prescription.dart';

/// What a QR token is worth before it is spent.
class QrTokenStatus {
  const QrTokenStatus({required this.usable, this.message});

  final bool usable;
  final String? message;
}

/// Opens a prescription from its one-time QR link.
///
/// Deliberately not the shared [ApiClient]: that attaches the signed-in
/// doctor's token and logs them out on a 403, and this endpoint answers 403
/// for an ordinary, expected case — a code that has already been used. It is
/// also unauthenticated by design, so there is nothing to attach.
class QrPrescriptionRepository {
  QrPrescriptionRepository([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              connectTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 60),
              // Every status is read here; none of them is an exception.
              validateStatus: (_) => true,
            ));

  final Dio _dio;

  /// Whether the code can still be opened — without spending it.
  ///
  /// Checked first because opening is irreversible: a messaging app that
  /// fetches link previews would otherwise burn the code before the patient
  /// ever tapped it.
  Future<QrTokenStatus> checkStatus(String token) async {
    final res = await _dio.get<dynamic>('/prescriptions/qr/$token/status');
    final body = res.data;
    if (body is! Map) {
      return const QrTokenStatus(
        usable: false,
        message: 'This link could not be checked. Try again in a moment.',
      );
    }

    if (body['success'] != true) {
      return QrTokenStatus(usable: false, message: _message(body));
    }

    final data = body['data'];
    final map = data is Map ? data : const {};
    final used = map['used'] == true || map['accessed'] == true;
    final expired = map['isExpired'] == true || map['expired'] == true;
    final valid = map['valid'] == true || map['status'] == 'VALID';

    if (used) {
      return const QrTokenStatus(
        usable: false,
        message: 'This prescription has already been opened. '
            'A QR code can be used once.',
      );
    }
    if (expired) {
      return const QrTokenStatus(
        usable: false,
        message: 'This link has expired. Ask the doctor to issue a new one.',
      );
    }
    // An unrecognised shape is treated as usable: the open call is the real
    // authority, and refusing here would strand a valid prescription.
    return QrTokenStatus(usable: valid || map.isEmpty || !map.containsKey('valid'));
  }

  /// Opens the prescription. This spends the code.
  Future<QrPrescription> open(String token) async {
    final res = await _dio.get<dynamic>('/prescriptions/qr/$token');
    final body = res.data;

    if (body is! Map || body['success'] != true) {
      throw QrAccessException(_message(body));
    }

    final data = body['data'];
    final prescription = data is Map ? data['prescription'] : null;
    if (prescription is! Map<String, dynamic>) {
      throw const QrAccessException('This prescription could not be read.');
    }
    return QrPrescription.fromJson(prescription);
  }

  static String _message(dynamic body) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return 'This prescription could not be opened.';
  }
}

/// A QR link that cannot be opened, with the reason worth showing.
class QrAccessException implements Exception {
  const QrAccessException(this.message);
  final String message;

  @override
  String toString() => message;
}
