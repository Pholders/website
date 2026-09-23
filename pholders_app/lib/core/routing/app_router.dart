import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../app/app_state.dart';
import '../../shared/constants/app_constants.dart';
import 'app_routes.dart';

// ─── Auth pages ──────────────────────────────────────────────────────────────
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/landing_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/doctor_register_step2_page.dart';
import '../../features/auth/data/models/doctor_registration_draft.dart';
import '../../features/auth/presentation/verify_account_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/public/presentation/features_page.dart';
import '../../features/public/presentation/about_page.dart';
import '../../features/public/presentation/services_page.dart';
import '../../features/public/presentation/how_it_works_page.dart';
import '../../features/public/presentation/support_page.dart';

// ─── Doctor pages ─────────────────────────────────────────────────────────────
import '../../features/doctor/dashboard/presentation/doctor_dashboard_page.dart';
import '../../features/doctor/patients/presentation/patient_list_page.dart';
import '../../features/doctor/patients/presentation/patient_detail_page.dart';
import '../../features/doctor/patients/presentation/patient_medication_page.dart';
import '../../features/doctor/patients/presentation/patient_medication_detail_page.dart';
import '../../features/doctor/patients/presentation/patient_prescriptions_page.dart';
import '../../features/doctor/patients/presentation/patient_prescription_detail_page.dart';
import '../../features/doctor/patients/presentation/patient_appointments_page.dart';
import '../../features/doctor/patients/presentation/patient_documents_page.dart';
import '../../features/doctor/patients/presentation/patient_history_page.dart';
import '../../features/doctor/prescriptions/presentation/prescriptions_list_page.dart';
import '../../features/doctor/prescriptions/presentation/prescription_detail_page.dart';
import '../../features/doctor/prescriptions/presentation/new_prescription_page.dart';
import '../../features/doctor/prescriptions/presentation/preview_prescription_page.dart';
import '../../features/doctor/prescriptions/presentation/search_scripts_page.dart';
import '../../features/doctor/sick_notes/presentation/sick_notes_page.dart';
import '../../features/doctor/appointments/presentation/appointments_page.dart';
import '../../features/doctor/billing/presentation/billing_page.dart';
import '../../features/doctor/settings/presentation/settings_page.dart';
import '../../features/doctor/settings/presentation/account_settings.dart';
import '../../features/doctor/settings/presentation/practice_settings.dart';
import '../../features/doctor/settings/presentation/security_settings.dart';
import '../../features/doctor/settings/presentation/preferences_settings.dart';
import '../../features/doctor/settings/presentation/integrations_settings.dart';
import '../../features/doctor/settings/presentation/login_activity.dart';
import '../../features/doctor/settings/presentation/support_legal_settings.dart';
import '../../shared/pages/linked_services_page.dart';

// ─── Pharmacy pages ───────────────────────────────────────────────────────────
import '../../features/pharmacy/dashboard/presentation/pharmacy_dashboard_page.dart';
import '../../features/pharmacy/prescriptions/presentation/pharmacy_prescriptions_page.dart';
import '../../features/pharmacy/prescriptions/presentation/pharmacy_prescription_detail_page.dart';
import '../../features/pharmacy/orders/presentation/orders_page.dart';
import '../../features/pharmacy/orders/presentation/order_detail_page.dart';
import '../../features/pharmacy/inventory/presentation/inventory_page.dart';
import '../../features/pharmacy/dispensing_queue/presentation/dispensing_queue_page.dart';
import '../../features/pharmacy/patients/presentation/pharmacy_patients_page.dart';
import '../../features/pharmacy/billing/presentation/pharmacy_billing_page.dart';
import '../../features/pharmacy/reports/presentation/pharmacy_reports_page.dart';
import '../../features/pharmacy/settings/presentation/pharmacy_settings_page.dart';

// ─── Shell layouts ────────────────────────────────────────────────────────────
import '../../shared/widgets/shell_layout.dart';

/// Builds and returns the [GoRouter] instance.
///
/// The router reads auth state from the Redux [Store] to handle redirects.
/// All route strings come from [AppRoutes] — never hardcoded here.
/// Several settings screens are one widget holding two or more panels chosen
/// by `?tab=`. The links have always carried the query string; nothing read it.
int _tab(GoRouterState state) =>
    int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;

GoRouter createRouter(Store<AppState> store) {
  return GoRouter(
    // Let GoRouter use the browser URL instead of forcing splash.
    // initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // Re-run [_guard] whenever the auth slice changes (login, logout, or the
    // stored session finishing its restore).
    refreshListenable: _AuthChangeNotifier(store),
    redirect: (context, state) => _guard(store, state),
    routes: [
      // ─── Public routes ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.registerStep2,
        // Step 1 hands the personal details across as `extra`.
        builder: (context, state) => DoctorRegisterStep2Page(
          draft: state.extra as DoctorRegistrationDraft?,
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyAccount,
        builder: (context, state) => const VerifyAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.features,
        builder: (context, state) => const FeaturesPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesPage(),
      ),
      GoRoute(
        path: AppRoutes.howItWorks,
        builder: (context, state) => const HowItWorksPage(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (context, state) => const SupportPage(),
      ),

      // ─── Doctor shell (authenticated, role = doctor) ─────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellLayout(
          role: AppConstants.roleDoctor,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.doctorDashboard,
            builder: (context, state) => const DoctorDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorPatients,
            builder: (context, state) => const PatientListPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientDetail,
            builder: (context, state) => PatientDetailPage(
              patientId: state.pathParameters['patientId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientMedication,
            builder: (context, state) => PatientMedicationPage(
              patientId: state.pathParameters['patientId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientMedicationDetail,
            builder: (context, state) => PatientMedicationDetailPage(
              patientId: state.pathParameters['patientId']!,
              medicationId: state.pathParameters['medicationId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientPrescriptions,
            builder: (context, state) => PatientPrescriptionsPage(
              patientId: state.pathParameters['patientId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientPrescriptionDetail,
            builder: (context, state) => PatientPrescriptionDetailPage(
              patientId: state.pathParameters['patientId']!,
              prescriptionId: state.pathParameters['prescriptionId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientAppointments,
            builder: (context, state) => PatientAppointmentsPage(
              patientId: state.pathParameters['patientId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientDocuments,
            builder: (context, state) => PatientDocumentsPage(
              patientId: state.pathParameters['patientId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPatientHistory,
            builder: (context, state) => PatientHistoryPage(
              patientId: state.pathParameters['patientId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorPrescriptions,
            builder: (context, state) => const PrescriptionsListPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorPrescriptionDetail,
            builder: (context, state) => PrescriptionDetailPage(
              prescriptionId: state.pathParameters['prescriptionId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.doctorNewPrescription,
            builder: (context, state) => const NewPrescriptionPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorPreviewPrescription,
            builder: (context, state) => const PreviewPrescriptionPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorSearchScripts,
            builder: (context, state) => const SearchScriptsPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorSickNotes,
            builder: (context, state) => const SickNotesPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorAppointments,
            builder: (context, state) => const AppointmentsPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorBilling,
            builder: (context, state) => const BillingPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsProfile,
            builder: (context, state) => const AccountSettings(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsProfessional,
            // Both halves of Account settings are one widget picked by tab, so
            // without this the Professional Details link showed Personal
            // Information.
            builder: (context, state) => const AccountSettings(initialTab: 1),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsFees,
            builder: (context, state) => const PracticeSettings(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsPractice,
            builder: (context, state) =>
                PracticeSettings(initialTab: _tab(state)),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsNotifications,
            builder: (context, state) => const PreferencesSettings(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsPreferences,
            builder: (context, state) =>
                PreferencesSettings(initialTab: _tab(state)),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsSupportLegal,
            builder: (context, state) =>
                SupportLegalSettings(initialTab: _tab(state)),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsSecurity,
            builder: (context, state) => const SecuritySettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsDevices,
            builder: (context, state) => const SecuritySettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsLoginActivity,
            builder: (context, state) => const LoginActivityPage(),
          ),
          GoRoute(
            path: AppRoutes.doctorSettingsLinkedServices,
            builder: (context, state) => const IntegrationsSettings(),
          ),
        ],
      ),

      // ─── Pharmacy shell (authenticated, role = pharmacy) ─────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellLayout(
          role: AppConstants.rolePharmacy,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.pharmacyDashboard,
            builder: (context, state) => const PharmacyDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacyPrescriptions,
            builder: (context, state) => const PharmacyPrescriptionsPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacyPrescriptionDetail,
            builder: (context, state) => PharmacyPrescriptionDetailPage(
              prescriptionId: state.pathParameters['prescriptionId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.pharmacyOrders,
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacyOrderDetail,
            builder: (context, state) => OrderDetailPage(
              orderId: state.pathParameters['orderId']!,
            ),
          ),
          GoRoute(
            path: AppRoutes.pharmacyInventory,
            builder: (context, state) => const InventoryPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacyDispensingQueue,
            builder: (context, state) => const DispensingQueuePage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacyPatients,
            builder: (context, state) => const PharmacyPatientsPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacyBilling,
            builder: (context, state) => const PharmacyBillingPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacyReports,
            builder: (context, state) => const PharmacyReportsPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacySettings,
            builder: (context, state) => const PharmacySettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.pharmacySettingsLinkedServices,
            builder: (context, state) => const LinkedServicesPage(),
          ),
        ],
      ),
    ],
  );
}

/// Route guard: keeps signed-out users out of the app shells, and signed-in
/// users out of the login and registration pages.
///
/// Returns null to allow the requested location, or a path to redirect to.
String? _guard(Store<AppState> store, GoRouterState state) {
  final auth = store.state.authState;
  final location = state.matchedLocation;

  final isDoctorArea = location.startsWith('/doctor');
  final isPharmacyArea = location.startsWith('/pharmacy');
  final isProtected = isDoctorArea || isPharmacyArea;

  // While the stored session is still being read, let the request through.
  // This listenable fires again once the restore finishes, and the guard runs
  // a second time with the real answer — so a refresh on /doctor/dashboard
  // does not bounce a signed-in doctor to the login page.
  if (auth.isRestoring) return null;

  if (isProtected && !auth.isAuthenticated) return AppRoutes.login;

  if (auth.isAuthenticated) {
    final home = auth.role == AppConstants.roleDoctor
        ? AppRoutes.doctorDashboard
        : AppRoutes.pharmacyDashboard;

    // Already signed in — skip the auth pages.
    const authPages = {
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.registerStep2,
      AppRoutes.splash,
    };
    if (authPages.contains(location)) return home;

    // Signed in with the wrong role for this area.
    if (isDoctorArea && auth.role != AppConstants.roleDoctor) return home;
    if (isPharmacyArea && auth.role != AppConstants.rolePharmacy) return home;
  }

  return null;
}

/// Bridges the Redux [Store] to GoRouter's [Listenable] based refresh.
///
/// Notifies only when the fields the guard actually reads change, so routing
/// is not re-evaluated on every unrelated dispatch.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Store<AppState> store) {
    var last = _snapshot(store);
    _unsubscribe = store.onChange.listen((_) {
      final next = _snapshot(store);
      if (next != last) {
        last = next;
        notifyListeners();
      }
    }).cancel;
  }

  late final Future<void> Function() _unsubscribe;

  static String _snapshot(Store<AppState> store) {
    final a = store.state.authState;
    return '${a.isAuthenticated}|${a.role}|${a.isRestoring}';
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
