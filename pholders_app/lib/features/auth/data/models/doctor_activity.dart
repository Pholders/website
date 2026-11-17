/// One entry from `GET /users/doctor/activity-log`.
///
/// The backend records security events — logins, failed logins, OTP checks,
/// profile changes — rather than general app usage.
class DoctorActivity {
  const DoctorActivity({
    required this.id,
    required this.eventType,
    required this.status,
    this.ipAddress,
    this.createdAt,
    this.errorMessage,
  });

  factory DoctorActivity.fromJson(Map<String, dynamic> json) {
    return DoctorActivity(
      id: _asInt(json['id']) ?? 0,
      eventType: _asString(json['event_type']) ?? 'unknown',
      status: _asString(json['status']) ?? 'unknown',
      ipAddress: _asString(json['ip_address']),
      createdAt: DateTime.tryParse(_asString(json['created_at']) ?? ''),
      errorMessage: _asString(json['error_message']),
    );
  }

  final int id;

  /// 'login', 'login_failed', 'otp_verified', 'signup', and so on.
  final String eventType;

  /// 'success' or 'failed'.
  final String status;
  final String? ipAddress;
  final DateTime? createdAt;
  final String? errorMessage;

  bool get succeeded => status == 'success';

  /// "login failed" reads better than the raw 'login_failed'.
  String get label => eventType.replaceAll('_', ' ');

  /// "9 Sep, 13:33".
  String get formattedTime {
    final d = createdAt;
    if (d == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = d.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]}, $hh:$mm';
  }

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
}

/// One entry from  — a device currently signed in.
class ActiveSession {
  const ActiveSession({
    required this.id,
    this.ipAddress,
    this.userAgent,
    this.createdAt,
    this.lastActivityAt,
    this.expiresAt,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    // The user agent is nested inside a device_info blob rather than a column.
    final device = json['device_info'];
    return ActiveSession(
      id: DoctorActivity._asString(json['id']) ?? '',
      ipAddress: DoctorActivity._asString(json['ip_address']),
      userAgent: device is Map<String, dynamic>
          ? DoctorActivity._asString(device['userAgent'])
          : null,
      createdAt:
          DateTime.tryParse(DoctorActivity._asString(json['created_at']) ?? ''),
      lastActivityAt: DateTime.tryParse(
          DoctorActivity._asString(json['last_activity_at']) ?? ''),
      expiresAt:
          DateTime.tryParse(DoctorActivity._asString(json['expires_at']) ?? ''),
    );
  }

  final String id;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final DateTime? expiresAt;

  /// "Chrome on Windows" from the raw user agent, best effort.
  String get device {
    final ua = userAgent;
    if (ua == null) return 'Unknown device';
    if (ua.startsWith('curl')) return 'API client';
    final browser = ua.contains('Edg/')
        ? 'Edge'
        : ua.contains('Chrome')
            ? 'Chrome'
            : ua.contains('Firefox')
                ? 'Firefox'
                : ua.contains('Safari')
                    ? 'Safari'
                    : 'Browser';
    final os = ua.contains('Windows')
        ? 'Windows'
        : ua.contains('Mac OS')
            ? 'macOS'
            : ua.contains('Android')
                ? 'Android'
                : ua.contains('iPhone')
                    ? 'iOS'
                    : 'Unknown OS';
    return '$browser on $os';
  }
}
