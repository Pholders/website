import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/app/app_reducer.dart';
import 'package:pholders_app/app/app_state.dart';
import 'package:pholders_app/core/auth/token_storage.dart';
import 'package:pholders_app/core/network/api_client.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/appointments/data/appointments_repository.dart';
import 'package:pholders_app/features/doctor/appointments/data/models/appointment.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_actions.dart';
import 'package:pholders_app/features/doctor/appointments/redux/appointments_middleware.dart';
import 'package:redux/redux.dart';

/// Accepting or completing an appointment marks it busy, and the dialog shows
/// a spinner in place of its buttons while that lasts. The mark used to be
/// cleared only on failure, so after a successful accept, reopening the
/// appointment to mark it complete showed a spinner that never stopped.
class _NoSession extends TokenStorage {
  const _NoSession() : super(const FlutterSecureStorage());
}

class _FakeRepository extends AppointmentsRepository {
  _FakeRepository({this.fail = false})
      : super(ApiClient(tokenStorage: const _NoSession()));

  final bool fail;

  @override
  Future<List<Appointment>> fetch({
    AppointmentScope scope = AppointmentScope.all,
    int limit = 50,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<void> accept(int appointmentId) async {
    if (fail) throw const ApiException(message: 'Could not accept');
  }

  @override
  Future<void> complete(
    int appointmentId, {
    String? notes,
    String? diagnosis,
    bool prescriptionRequired = false,
  }) async {
    if (fail) throw const ApiException(message: 'Could not complete');
  }
}

void main() {
  Store<AppState> store(AppointmentsRepository repository) => Store<AppState>(
        appReducer,
        initialState: AppState.initial(),
        middleware: createAppointmentsMiddleware(repository: repository),
      );

  Set<int> busy(Store<AppState> s) => s.state.appointmentsState.pendingActionIds;

  test('a successful accept leaves the appointment ready for its next step', () async {
    final s = store(_FakeRepository());
    s.dispatch(const AcceptAppointmentAction(appointmentId: 46));
    expect(busy(s), contains(46), reason: 'busy while the request is out');
    await pumpEventQueue();
    expect(busy(s), isNot(contains(46)));
  });

  test('a successful complete clears the busy mark too', () async {
    final s = store(_FakeRepository());
    s.dispatch(const CompleteAppointmentAction(appointmentId: 46));
    await pumpEventQueue();
    expect(busy(s), isEmpty);
  });

  test('a failed accept still clears it, and says why', () async {
    final s = store(_FakeRepository(fail: true));
    s.dispatch(const AcceptAppointmentAction(appointmentId: 46));
    await pumpEventQueue();
    expect(busy(s), isEmpty);
    expect(s.state.appointmentsState.errorMessage, 'Could not accept');
  });
}
