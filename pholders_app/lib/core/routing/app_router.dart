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
import '../../features/auth/presentation/verify_account_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';

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
import '../../features/doctor/appointments/presentation/appointments_page.dart';
import '../../features/doctor/billing/presentation/billing_page.dart';
import '../../features/doctor/settings/presentation/settings_page.dart';

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
import '../../features/pharmacy/settings/presentation/pharmacy_settings_page.dart';

// ─── Shell layouts ────────────────────────────────────────────────────────────
import '../../shared/widgets/shell_layout.dart';

/// Builds and returns the [GoRouter] instance.
///
/// The router reads auth state from the Redux [Store] to handle redirects.
/// All route strings come from [AppRoutes] — never hardcoded here.
GoRouter createRouter(Store<AppState> store) {
  return GoRouter(
    // Let GoRouter use the browser URL instead of forcing splash.
    // initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    // TODO: Re-enable auth guards once authentication is implemented.
    // redirect: (BuildContext context, GoRouterState state) { ... },
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
        builder: (context, state) => const DoctorRegisterStep2Page(),
      ),
      GoRoute(
        path: AppRoutes.verifyAccount,
        builder: (context, state) => const VerifyAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
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
            path: AppRoutes.pharmacySettings,
            builder: (context, state) => const PharmacySettingsPage(),
          ),
        ],
      ),
    ],
  );
}
