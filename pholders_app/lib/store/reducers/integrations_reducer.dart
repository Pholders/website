import '../actions/integrations_actions.dart';
import '../integration_state.dart';

IntegrationsState integrationsReducer(
  IntegrationsState state,
  dynamic action,
) {
  if (action is ToggleIntegrationConnectionAction) {
    return state.copyWith(
      sections: state.sections.map((section) {
        return section.copyWith(
          integrations: section.integrations.map((integration) {
            if (integration.id != action.integrationId) {
              return integration;
            }

            return integration.copyWith(
              isConnected: !integration.isConnected,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  return state;
}
