import '../../../../core/network/api_client.dart';

/// Where the signed-in doctor stands with one patient's health record.
///
/// The patient decides who sees their record (SRS: "patient controls
/// access"), and vitals are part of it, so a doctor asks and waits.
enum RecordAccessStatus { granted, pending, denied, revoked, none }

class RecordAccess {
  const RecordAccess({
    required this.status,
    this.requestedAt,
    this.grantedAt,
    this.canRequest = false,
  });

  factory RecordAccess.fromJson(Map<String, dynamic> json) {
    final name = json['status']?.toString();
    return RecordAccess(
      status: RecordAccessStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => RecordAccessStatus.none,
      ),
      requestedAt: _date(json['requestedAt']),
      grantedAt: _date(json['grantedAt']),
      canRequest: json['canRequest'] == true,
    );
  }

  final RecordAccessStatus status;
  final DateTime? requestedAt;
  final DateTime? grantedAt;

  /// False while a request waits, once access is granted, or when the doctor
  /// has no booking with this patient.
  final bool canRequest;
}

/// One set of readings the patient logged in the Pholders app.
///
/// Postgres DECIMAL columns arrive as strings ("74.50"), so every number is
/// parsed rather than cast.
class PatientVital {
  const PatientVital({
    required this.measuredAt,
    this.systolicBp,
    this.diastolicBp,
    this.heartRate,
    this.weightKg,
    this.bmi,
    this.bloodGlucose,
    this.oxygenSaturation,
    this.temperatureC,
    this.notes,
  });

  factory PatientVital.fromJson(Map<String, dynamic> json) {
    final notes = json['notes']?.toString().trim();
    return PatientVital(
      measuredAt: _date(json['measured_at']) ?? DateTime.now(),
      systolicBp: _num(json['systolic_bp'])?.toInt(),
      diastolicBp: _num(json['diastolic_bp'])?.toInt(),
      heartRate: _num(json['heart_rate'])?.toInt(),
      weightKg: _num(json['weight_kg'])?.toDouble(),
      bmi: _num(json['bmi'])?.toDouble(),
      bloodGlucose: _num(json['blood_glucose'])?.toDouble(),
      oxygenSaturation: _num(json['oxygen_saturation'])?.toDouble(),
      temperatureC: _num(json['temperature_c'])?.toDouble(),
      notes: (notes == null || notes.isEmpty) ? null : notes,
    );
  }

  final DateTime measuredAt;
  final int? systolicBp;
  final int? diastolicBp;
  final int? heartRate;
  final double? weightKg;
  final double? bmi;
  final double? bloodGlucose;
  final double? oxygenSaturation;
  final double? temperatureC;
  final String? notes;

  String? get bloodPressure => systolicBp == null || diastolicBp == null
      ? null
      : '$systolicBp/$diastolicBp';
}

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

num? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString().trim());
}

/// The doctor's side of the patient health record (PHR).
///
/// The routes live in the backend's userRoutes.js, mounted at /users.
class PatientRecordRepository {
  const PatientRecordRepository(this._api);

  final ApiClient _api;

  Future<RecordAccess> fetchAccess(String patientId) async {
    final data = await _api.get('/users/phr/$patientId/access-status');
    return RecordAccess.fromJson(data);
  }

  /// Asks the patient for access. Asking again while a request waits does
  /// not make a second one; the server returns the current state instead.
  Future<RecordAccess> requestAccess(String patientId, {String? reason}) async {
    final note = reason?.trim();
    final data = await _api.post(
      '/users/phr/$patientId/access-request',
      body: {if (note != null && note.isNotEmpty) 'reason': note},
    );
    return RecordAccess.fromJson(data);
  }

  /// Newest first. Only works while access is granted; the server answers
  /// 403 otherwise.
  Future<List<PatientVital>> fetchVitals(String patientId, {int limit = 50}) async {
    final data = await _api.get(
      '/users/phr/$patientId/vitals',
      queryParameters: {'limit': limit},
    );
    final rows = data['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => PatientVital.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
