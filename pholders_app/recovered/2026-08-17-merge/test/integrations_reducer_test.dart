import 'package:flutter_test/flutter_test.dart';
import 'package:pholders_app/store/actions/integrations_actions.dart';
import 'package:pholders_app/store/integration_state.dart';
import 'package:pholders_app/store/reducers/integrations_reducer.dart';

void main() {
  group('integrationsReducer', () {
    test('toggles the requested integration connection state', () {
      final state = IntegrationsState.initial();

      final nextState = integrationsReducer(
        state,
        const ToggleIntegrationConnectionAction(integrationId: 'bonitas'),
      );

      final bonitas = nextState.sections
          .expand((section) => section.integrations)
          .firstWhere((integration) => integration.id == 'bonitas');

      expect(bonitas.isConnected, isTrue);
    });

    test('leaves state unchanged for unrelated actions', () {
      final state = IntegrationsState.initial();

      final nextState = integrationsReducer(state, Object());

      expect(nextState, state);
    });
  });
}
