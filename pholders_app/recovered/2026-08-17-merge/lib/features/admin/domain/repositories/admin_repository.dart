import '../entities/admin_profile.dart';

abstract class AdminRepository {
  /// Fetches the signed-in admin's own account.
  Future<AdminProfile> getProfile();
}
