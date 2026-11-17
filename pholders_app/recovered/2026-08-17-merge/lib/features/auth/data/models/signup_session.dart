class SignupSession {
  factory SignupSession() => _instance;
  static final SignupSession _instance = SignupSession._internal();
  SignupSession._internal();

  String? email;
  String? role;
  String? firstName;
  String? lastName;
  String? phone;
  String? password;

  void clear() {
    email = null;
    role = null;
    firstName = null;
    lastName = null;
    phone = null;
    password = null;
  }
}
