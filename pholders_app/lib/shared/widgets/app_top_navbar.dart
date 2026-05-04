import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_state.dart';
import '../../core/auth/auth_actions.dart';
import '../../core/routing/app_routes.dart';
import '../theme/app_theme.dart';

/// The horizontal top navigation bar shown on every authenticated page.
///
/// Displays the app logo, current page breadcrumb, a search bar,
/// notification bell, and the logged-in user's name with a logout action.
class AppTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  /// The authenticated user's role — used to show role-specific content.
  final String role;

  /// Called when the hamburger menu icon is tapped (mobile only).
  /// Pass null on desktop/tablet where the sidebar is always visible.
  final VoidCallback? onMenuTap;

  const AppTopNavbar({
    super.key,
    required this.role,
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _NavbarViewModel>(
      converter: (store) => _NavbarViewModel(
        userName: store.state.authState.userName ?? 'User',
        onLogout: () {
          store.dispatch(const LogoutAction());
          context.go(AppRoutes.login);
        },
      ),
      builder: (context, vm) {
        return Container(
          height: 64,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              bottom: BorderSide(color: AppTheme.divider),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Row(
            children: [
              // Hamburger (mobile only)
              if (onMenuTap != null) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onMenuTap,
                  tooltip: 'Open menu',
                ),
                const SizedBox(width: AppTheme.spacingSm),
              ],

              // Logo / App name
              Text(
                'PHolders',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),

              const Spacer(),

              // User name + logout
              Text(
                vm.userName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Logout',
                onPressed: vm.onLogout,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavbarViewModel {
  final String userName;
  final VoidCallback onLogout;

  const _NavbarViewModel({
    required this.userName,
    required this.onLogout,
  });
}
