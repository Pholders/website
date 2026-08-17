import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  final String token;
  final String? refreshToken;
  final String role;
  final String userName;

  const AuthSession({
    required this.token,
    this.refreshToken,
    required this.role,
    required this.userName,
  });

  @override
  List<Object?> get props => [token, refreshToken, role, userName];
}
