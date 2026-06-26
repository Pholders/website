/// Single source of truth for all route path strings.
///
/// No widget should hardcode a route path — always use this class.
/// This prevents typos and makes refactoring routes trivial.
class AppRoutes {
  AppRoutes._();

  // ─── Public routes (no auth required) ───────────────────────────────────────
  static const String splash = '/';
  static const String landing = '/get-started';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerStep2 = '/register/step-2';
  static const String verifyAccount = '/verify';
  static const String forgotPassword = '/forgot-password';

  // ─── Doctor routes ───────────────────────────────────────────────────────────
  static const String doctorDashboard = '/doctor/dashboard';
  static const String doctorPatients = '/doctor/patients';
  static const String doctorPatientDetail = '/doctor/patients/:patientId';
  static const String doctorPatientMedication =
      '/doctor/patients/:patientId/medication';
  static const String doctorPatientMedicationDetail =
      '/doctor/patients/:patientId/medication/:medicationId';
  static const String doctorPatientPrescriptions =
      '/doctor/patients/:patientId/prescriptions';
  static const String doctorPatientPrescriptionDetail =
      '/doctor/patients/:patientId/prescriptions/:prescriptionId';
  static const String doctorPatientAppointments =
      '/doctor/patients/:patientId/appointments';
  static const String doctorPatientDocuments =
      '/doctor/patients/:patientId/documents';
  static const String doctorPatientHistory =
      '/doctor/patients/:patientId/history';
  static const String doctorPrescriptions = '/doctor/prescriptions';
  static const String doctorPrescriptionDetail =
      '/doctor/prescriptions/:prescriptionId';
  static const String doctorAppointments = '/doctor/appointments';
  static const String doctorBilling = '/doctor/billing';
  static const String doctorSettings = '/doctor/settings';
  static const String doctorSupport = '/doctor/support';
  static const String doctorSettingsProfile = '/doctor/settings/profile';
  static const String doctorSettingsProfessional =
      '/doctor/settings/professional';
  static const String doctorSettingsFees = '/doctor/settings/fees';
  static const String doctorSettingsNotifications =
      '/doctor/settings/notifications';
  static const String doctorSettingsSecurity = '/doctor/settings/security';
  static const String doctorSettingsDevices = '/doctor/settings/devices';
  static const String doctorSettingsLoginActivity =
      '/doctor/settings/login-activity';
  static const String doctorSettingsLinkedServices =
      '/doctor/settings/linked-services';

  // ─── Pharmacy routes ─────────────────────────────────────────────────────────
  static const String pharmacyDashboard = '/pharmacy/dashboard';
  static const String pharmacyPrescriptions = '/pharmacy/prescriptions';
  static const String pharmacyPrescriptionDetail =
      '/pharmacy/prescriptions/:prescriptionId';
  static const String pharmacyOrders = '/pharmacy/orders';
  static const String pharmacyOrderDetail = '/pharmacy/orders/:orderId';
  static const String pharmacyInventory = '/pharmacy/inventory';
  static const String pharmacyDispensingQueue = '/pharmacy/dispensing-queue';
  static const String pharmacyPatients = '/pharmacy/patients';
  static const String pharmacyBilling = '/pharmacy/billing';
  static const String pharmacySettings = '/pharmacy/settings';

  static String? get pharmacyReports => null;
}
