import 'package:equatable/equatable.dart';

class IntegrationsState extends Equatable {
  const IntegrationsState({required this.sections});

  factory IntegrationsState.initial() {
    return const IntegrationsState(
      sections: [
        IntegrationSectionState(
          title: 'Medical Aid',
          integrations: [
            IntegrationItemState(
              id: 'discovery',
              iconAsset: 'assets/discovery-icon.png',
              colorValue: 0xFFE94162,
              title: 'Discovery',
              lastSynced: 'Last synced 2 hours ago',
              isConnected: true,
            ),
            IntegrationItemState(
              id: 'bonitas',
              iconAsset: 'assets/bonitas-icon.png',
              colorValue: 0xFF77A5FF,
              title: 'Bonitas',
            ),
            IntegrationItemState(
              id: 'momentum',
              iconAsset: 'assets/momentum-icon.png',
              colorValue: 0xFF3A9EA5,
              title: 'Momentum',
            ),
          ],
        ),
        IntegrationSectionState(
          title: 'Calendar',
          integrations: [
            IntegrationItemState(
              id: 'google_calendar',
              iconAsset: 'assets/google-calender-icon.png',
              colorValue: 0xFF4285F4,
              title: 'Google Calendar',
              lastSynced: 'Last synced 5 minutes ago',
            ),
            IntegrationItemState(
              id: 'outlook_calendar',
              iconAsset: 'assets/outlook-icon.png',
              colorValue: 0xFF2D9CDB,
              title: 'Outlook Calendar',
              lastSynced: 'Last synced 5 minutes ago',
              isConnected: true,
            ),
          ],
        ),
        IntegrationSectionState(
          title: 'Payments',
          integrations: [
            IntegrationItemState(
              id: 'paypal',
              iconAsset: 'assets/paypal-icon.png',
              colorValue: 0xFF1B73E8,
              title: 'PayPal',
              lastSynced: 'Last synced 4 hours ago',
            ),
          ],
        ),
        IntegrationSectionState(
          title: 'Communication',
          integrations: [
            IntegrationItemState(
              id: 'whatsapp_notifications',
              iconAsset: 'assets/whatsapp-icon.png',
              colorValue: 0xFF25D366,
              title: 'WhatsApp Notifications',
            ),
          ],
        ),
      ],
    );
  }

  final List<IntegrationSectionState> sections;

  IntegrationsState copyWith({
    List<IntegrationSectionState>? sections,
  }) {
    return IntegrationsState(sections: sections ?? this.sections);
  }

  @override
  List<Object?> get props => [sections];
}

class IntegrationSectionState extends Equatable {
  const IntegrationSectionState({
    required this.title,
    required this.integrations,
  });

  final String title;
  final List<IntegrationItemState> integrations;

  IntegrationSectionState copyWith({
    String? title,
    List<IntegrationItemState>? integrations,
  }) {
    return IntegrationSectionState(
      title: title ?? this.title,
      integrations: integrations ?? this.integrations,
    );
  }

  @override
  List<Object?> get props => [title, integrations];
}

class IntegrationItemState extends Equatable {
  const IntegrationItemState({
    required this.id,
    required this.iconAsset,
    required this.colorValue,
    required this.title,
    this.lastSynced,
    this.isConnected = false,
  });

  final String id;
  final String iconAsset;
  final int colorValue;
  final String title;
  final String? lastSynced;
  final bool isConnected;

  String get actionLabel => isConnected ? 'Disconnect' : 'Connect';

  IntegrationItemState copyWith({
    String? id,
    String? iconAsset,
    int? colorValue,
    String? title,
    String? lastSynced,
    bool? isConnected,
  }) {
    return IntegrationItemState(
      id: id ?? this.id,
      iconAsset: iconAsset ?? this.iconAsset,
      colorValue: colorValue ?? this.colorValue,
      title: title ?? this.title,
      lastSynced: lastSynced ?? this.lastSynced,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props =>
      [id, iconAsset, colorValue, title, lastSynced, isConnected];
}
