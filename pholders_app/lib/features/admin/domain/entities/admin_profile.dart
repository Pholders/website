/// An admin account as returned by `GET /users/admin/profile`.
///
/// The API sends the raw `admins` row in snake_case and, notably, no role
/// field — the `admins` table has no role column. Role is carried in the JWT
/// and supplied by the client, so it is deliberately absent here too.
class AdminProfile {
  const AdminProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.status,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? status;

  String get fullName {
    final name = [firstName, lastName]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join(' ');
    return name.isEmpty ? email.split('@').first : name;
  }
}
