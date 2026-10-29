import 'dart:typed_data';

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

/// One set of readings, taken by a doctor at a consultation. Older rows were
/// typed in by the patient and have no doctor.
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
    this.recordedByName,
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
      recordedByName: json['recorded_by_name']?.toString(),
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

  /// "Dr Thandi Nkosi", or null for a reading the patient logged themselves.
  final String? recordedByName;

  String? get bloodPressure => systolicBp == null || diastolicBp == null
      ? null
      : '$systolicBp/$diastolicBp';
}

/// A medication the patient is currently taking, from their health record
/// (patient_medications, active rows only).
class PatientMedication {
  const PatientMedication({
    required this.name,
    this.dosage,
    this.frequency,
    this.route,
    this.startDate,
    this.endDate,
    this.reason,
    this.prescribedBy,
    this.notes,
  });

  factory PatientMedication.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    return PatientMedication(
      name: text('medication_name') ?? 'Unnamed medication',
      dosage: text('dosage'),
      frequency: text('frequency'),
      route: text('route'),
      startDate: _date(json['start_date']),
      endDate: _date(json['end_date']),
      reason: text('reason'),
      prescribedBy: text('prescribed_by'),
      notes: text('notes'),
    );
  }

  final String name;
  final String? dosage;
  final String? frequency;
  final String? route;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? reason;
  final String? prescribedBy;
  final String? notes;
}

/// One line of a patient's history: a completed visit or a prescription,
/// with any doctor on the platform.
class PatientHistoryEntry {
  const PatientHistoryEntry({
    required this.kind,
    this.date,
    this.status,
    this.providerName,
    this.specialization,
    this.notes,
  });

  factory PatientHistoryEntry.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    return PatientHistoryEntry(
      kind: text('record_type') ?? 'record',
      date: _date(json['appointment_date']),
      status: text('status'),
      providerName: text('provider_name'),
      specialization: text('specialization'),
      notes: text('notes'),
    );
  }

  /// 'appointment' or 'prescription'.
  final String kind;
  final DateTime? date;
  final String? status;
  final String? providerName;
  final String? specialization;

  /// A visit's notes, or a prescription's diagnosis.
  final String? notes;
}

/// A file the patient stored in the patient app (/users/profile/files).
class PatientDocument {
  const PatientDocument({
    required this.id,
    required this.name,
    this.mimeType,
    this.sizeBytes,
    this.category,
    this.description,
    this.uploadedAt,
  });

  factory PatientDocument.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    return PatientDocument(
      id: '${json['id']}',
      name: text('file_name') ?? 'Untitled file',
      mimeType: text('file_type'),
      sizeBytes: _num(json['file_size'])?.toInt(),
      category: text('category'),
      description: text('description'),
      uploadedAt: _date(json['upload_timestamp'] ?? json['created_at']),
    );
  }

  final String id;
  final String name;
  final String? mimeType;
  final int? sizeBytes;
  final String? category;
  final String? description;
  final DateTime? uploadedAt;
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

  /// Newest first. Any doctor the patient has booked may read these; the
  /// server answers 403 for anyone else.
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

  /// Records a reading for a patient who booked this doctor. [values] uses
  /// the server's field names (systolic_bp, heart_rate, …); BMI is worked out
  /// on the server.
  Future<PatientVital> recordVitals(
      String patientId, Map<String, dynamic> values) async {
    final data = await _api.post('/users/phr/$patientId/vitals', body: values);
    return PatientVital.fromJson(data);
  }

  /// The patient's active medications. Any doctor the patient has booked may
  /// read them; the server answers 403 for anyone else.
  Future<List<PatientMedication>> fetchMedications(String patientId) async {
    final data = await _api.get('/users/phr/$patientId/medications');
    final rows = data['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => PatientMedication.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// The patient's completed visits and prescriptions, newest first.
  Future<List<PatientHistoryEntry>> fetchHistory(String patientId) async {
    final data = await _api.get('/users/phr/$patientId/history');
    final rows = data['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => PatientHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// The files the patient stored, newest first. Metadata only.
  Future<List<PatientDocument>> fetchDocuments(String patientId) async {
    final data = await _api.get('/users/phr/$patientId/documents');
    final rows = data['data'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => PatientDocument.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// The bytes of one of the patient's files.
  Future<Uint8List> downloadDocument(String patientId, String fileId) =>
      _api.getBytes('/users/phr/$patientId/documents/$fileId');
}
