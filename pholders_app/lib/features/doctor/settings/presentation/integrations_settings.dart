// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/settings_shell.dart';
import '../../../../shared/widgets/settings_sidebar.dart';
import '../../../../store/actions/integrations_actions.dart';
import '../../../../store/app_state.dart';
import '../../../../store/integration_state.dart';

class IntegrationsSettings extends StatelessWidget {
  const IntegrationsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings sidebar ──────────────────────────────────────────────
          SettingsSidebar(
            selectedItemId: 'linked_services',
            onMenuItemSelected: (id) => _navigate(context, id),
          ),
          // ── Content area ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: StoreConnector<AppState, _IntegrationsViewModel>(
                converter: (store) => _IntegrationsViewModel.fromStore(store),
                builder: (context, viewModel) {
                  return SettingsContentCard(
                    title: 'Linked Services',
                    children: [
                      for (var index = 0;
                          index < viewModel.sections.length;
                          index++) ...[
                        _IntegrationSection(
                          section: viewModel.sections[index],
                          onToggleIntegration: viewModel.toggleIntegration,
                        ),
                        if (index < viewModel.sections.length - 1)
                          const _ThinDivider(),
                      ],
                      const SizedBox(height: 18),
                      const SettingsFullWidthAction('Manage Integrations'),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String id) {
    switch (id) {
      case 'profile':
        context.go(AppRoutes.doctorSettingsProfile);
        break;
      case 'professional':
        context.go(AppRoutes.doctorSettingsProfessional);
        break;
      case 'fees_setup':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=0');
        break;
      case 'practice_settings':
        context.go(AppRoutes.doctorSettingsPractice);
        break;
      case 'notification_settings':
        context.go('${AppRoutes.doctorSettingsPractice}?tab=1');
        break;
      case 'notification_center':
        context.go(AppRoutes.doctorNotifications);
        break;
      case 'security_settings':
        context.go(AppRoutes.doctorSettingsSecurity);
        break;
      case 'device_management':
        context.go(AppRoutes.doctorSettingsDevices);
        break;
      case 'login_activity':
        context.go(AppRoutes.doctorSettingsLoginActivity);
        break;
      case 'preferences_settings':
        context.go(AppRoutes.doctorSettingsPreferences);
        break;
      case 'linked_services':
        context.go(AppRoutes.doctorSettingsLinkedServices);
        break;
      case 'help_center':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=0');
        break;
      case 'privacy_policy':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=1');
        break;
      case 'terms_of_service':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=2');
        break;
      case 'contact_support':
        context.go('${AppRoutes.doctorSettingsSupportLegal}?tab=3');
        break;
      default:
        break;
    }
  }
}

class _IntegrationSection extends StatelessWidget {
  const _IntegrationSection({
    required this.section,
    required this.onToggleIntegration,
  });

  final IntegrationSectionState section;
  final ValueChanged<String> onToggleIntegration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle(section.title),
          const SizedBox(height: 8),
          for (final integration in section.integrations)
            _IntegrationRow(
              integration: integration,
              onTap: () => onToggleIntegration(integration.id),
            ),
        ],
      ),
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({
    required this.integration,
    required this.onTap,
  });

  final IntegrationItemState integration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Row(
        children: [
          Image.asset(
            integration.iconAsset,
            width: 24,
            height: 24,
            color: Color(integration.colorValue),
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.extension,
                color: Color(integration.colorValue),
                size: 24,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(integration.title, style: const TextStyle(fontSize: 14)),
                if (integration.lastSynced != null)
                  Text(integration.lastSynced!,
                      style: const TextStyle(fontSize: 9, color: Colors.black)),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onTap,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SettingsShell.panelMint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCFECEE)),
                ),
                child: Text(
                  integration.actionLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationsViewModel {
  const _IntegrationsViewModel({
    required this.sections,
    required this.toggleIntegration,
  });

  factory _IntegrationsViewModel.fromStore(Store<AppState> store) {
    return _IntegrationsViewModel(
      sections: store.state.integrationsState.sections,
      toggleIntegration: (integrationId) {
        store.dispatch(
          ToggleIntegrationConnectionAction(integrationId: integrationId),
        );
      },
    );
  }

  final List<IntegrationSectionState> sections;
  final ValueChanged<String> toggleIntegration;
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: SettingsShell.divider, thickness: 2, height: 2),
    );
  }
}
