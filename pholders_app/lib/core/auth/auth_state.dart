import 'package:equatable/equatable.dart';

import '../../features/auth/data/models/doctor.dart';

/// Represents the authentication slice of the Redux store.
///
/// This is the single source of truth for the current user's auth status,
/// JWT token, and resolved role.
class AuthState extends Equatable {

  const AuthState({
    this.token,
    this.role,
    this.userName,
    this.doctor,
    this.isLoading = false,
    this.errorMessage,
    this.isRestoring = true,
    this.signupEmail,
    this.devOtpCode,
    this.isEmailVerified = false,
  });

  /// The initial state before any login attempt.
  factory AuthState.initial() => const AuthState();

  /// The JWT token returned by the REST API on successful login.
  /// Null when the user is not authenticated.
  final String? token;

  /// The authenticated user's role: 'doctor' or 'pharmacy'.
  /// Null when the user is not authenticated.
  final String? role;

  /// The authenticated user's display name.
  final String? userName;

  /// The signed-in doctor's full profile, once loaded. Null for other roles.
  final Doctor? doctor;

  /// True while an auth request (login / signup) is in flight.
  final bool isLoading;

  /// Non-null when the last auth operation failed.
  final String? errorMessage;

  /// True until the stored session has been read from secure storage at
  /// startup. The router waits on this so it does not bounce an
  /// already-signed-in user to the login page on a page refresh.
  final bool isRestoring;

  /// The email a doctor just registered with, so the verification screen can
  /// prefill it.
  final String? signupEmail;

  /// The activation code, when the backend returns it instead of emailing it.
  /// The deployed API does this while it runs with NODE_ENV=development.
  final String? devOtpCode;

  /// True once the activation code has been accepted.
  final bool isEmailVerified;

  /// Returns true when a valid token and role are present.
  bool get isAuthenticated => token != null && role != null;

  /// True when the signed-in user is a doctor.
  bool get isDoctor => role == 'doctor';

  AuthState copyWith({
    String? token,
    String? role,
    String? userName,
    Doctor? doctor,
    bool? isLoading,
    String? errorMessage,
    bool? isRestoring,
    String? signupEmail,
    String? devOtpCode,
    bool? isEmailVerified,
    bool clearError = false,
    bool clearToken = false,
    bool clearSignup = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      role: clearToken ? null : (role ?? this.role),
      userName: clearToken ? null : (userName ?? this.userName),
      doctor: clearToken ? null : (doctor ?? this.doctor),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRestoring: isRestoring ?? this.isRestoring,
      signupEmail: clearSignup ? null : (signupEmail ?? this.signupEmail),
      devOtpCode: clearSignup ? null : (devOtpCode ?? this.devOtpCode),
      isEmailVerified:
          clearSignup ? false : (isEmailVerified ?? this.isEmailVerified),
    );
  }

  @override
  List<Object?> get props =>
      [token, role, userName, doctor, isLoading, errorMessage, isRestoring,
       signupEmail, devOtpCode, isEmailVerified];
}
