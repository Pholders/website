import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pholders_app/core/routing/app_router.dart';
import 'package:pholders_app/core/routing/app_routes.dart';
import 'package:redux/redux.dart';
import 'package:pholders_app/store/app_state.dart';

void main() {
  test('Settings navigation test', () async {
    // Create a test store
    final store = Store<AppState>(
      (state, action) => state,
      initialState: AppState.initial(),
    );

    // Create router
    final router = createRouter(store);

    // Test that all settings routes are properly configured
    expect(router.canNavigate(AppRoutes.doctorSettings), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsProfile), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsProfessional), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsFees), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsPractice), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsNotifications), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsSecurity), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsDevices), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsLoginActivity), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsPreferences), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsLinkedServices), true);
    expect(router.canNavigate(AppRoutes.doctorSettingsSupportLegal), true);

    print('All settings routes are properly configured!');
  });
}
