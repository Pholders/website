import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  final String role;

  const LoginParams({
    required this.email,
    required this.password,
    required this.role,
  });
}

class LoginUseCase implements UseCase<AuthSession, LoginParams> {
  LoginUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<AuthSession> call(LoginParams params) async {
    if (params.email.trim().isEmpty || params.password.trim().isEmpty) {
      throw const ValidationFailure();
    }

    return repository.login(
      email: params.email,
      password: params.password,
      role: params.role,
    );
  }
}
