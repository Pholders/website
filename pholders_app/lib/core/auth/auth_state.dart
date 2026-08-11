import 'package:equatable/equatable.dart';

/// Represents the authentication slice of the Redux store.
///
/// This is the single source of truth for the current user's auth status,
/// JWT token, and resolved role.
class AuthState extends Equatable {
  /// The JWT token returned by the REST API on successful login.
  /// Null when the user is not authenticated.
  final String? token;

  /// The authenticated user's role: 'doctor' or 'pharmacy'.
  /// Null when the user is not authenticated.
  final String? role;

  /// The authenticated user's display name.
  final String? userName;

  /// True while an auth request (login / refresh) is in flight.
  final bool isLoading;

  /// Non-null when the last auth operation failed.
  final String? errorMessage;

  /// Non-null when the last auth operation produced a success message.
  final String? successMessage;

  const AuthState({
    this.token,
    this.role,
    this.userName,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  /// The initial state before any login attempt.
  factory AuthState.initial() => const AuthState();

  /// Returns true when a valid token and role are present.
  bool get isAuthenticated => token != null && role != null;

  AuthState copyWith({
    String? token,
    String? role,
    String? userName,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearToken = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      role: clearToken ? null : (role ?? this.role),
      userName: clearToken ? null : (userName ?? this.userName),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [token, role, userName, isLoading, errorMessage, successMessage];
}
