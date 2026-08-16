/// Redux actions for the doctor settings integrations slice.
///
/// Actions stay as plain data objects. Any API work for real connection flows
/// can later be handled by middleware that reacts to these same actions.
class ToggleIntegrationConnectionAction {
  const ToggleIntegrationConnectionAction({required this.integrationId});

  final String integrationId;
}
