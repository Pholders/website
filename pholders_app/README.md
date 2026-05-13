# PHolders — Flutter Web App

Healthcare platform for **Doctors** and **Pharmacies**.

---

## Running the project

```bash
cd pholders_app
flutter pub get
flutter run -d chrome
```

---

## Folder structure

```
lib/
├── main.dart                  # Entry point — creates Redux store, runs app
├── app/
│   ├── app_state.dart         # Root AppState (composes all feature slices)
│   └── app_reducer.dart       # Root reducer (delegates to feature reducers)
├── core/
│   ├── auth/                  # AuthState, AuthActions, authReducer
│   ├── routing/               # AppRoutes (all route strings), AppRouter (GoRouter config)
│   ├── di/                    # service_locator.dart (GetIt setup)
│   └── network/               # Dio HTTP client setup (add as needed)
├── shared/
│   ├── theme/                 # AppTheme — colors, spacing, breakpoints, MaterialTheme
│   ├── constants/             # AppConstants — API URL, role strings, storage keys
│   ├── utils/                 # ResponsiveHelper — isMobile / isTablet / isDesktop
│   └── widgets/               # ShellLayout, AppSidebar, AppTopNavbar (shared across roles)
└── features/
    ├── auth/                  # Login, Register, Verify, ForgotPassword pages
    ├── doctor/                # All doctor-role screens
    │   ├── dashboard/
    │   ├── patients/          # List, Detail, Medication, Prescriptions, Appointments, Documents, History
    │   ├── prescriptions/
    │   ├── appointments/
    │   ├── billing/
    │   └── settings/
    └── pharmacy/              # All pharmacy-role screens
        ├── dashboard/
        ├── prescriptions/
        ├── orders/
        ├── inventory/
        ├── dispensing_queue/
        ├── patients/
        ├── billing/
        └── settings/
```

Each feature module follows the **presentation / domain / data** split:
- `presentation/` — Flutter widgets and pages
- `domain/` — models, use cases, repository interfaces
- `data/` — repository implementations, API data sources

---

## State management — Redux

All app state flows through a single Redux store.

| Concept | Location |
|---|---|
| Root state | `lib/app/app_state.dart` |
| Root reducer | `lib/app/app_reducer.dart` |
| Auth slice | `lib/core/auth/auth_state.dart` |
| Auth actions | `lib/core/auth/auth_actions.dart` |
| Auth reducer | `lib/core/auth/auth_reducer.dart` |

**Adding a new feature slice:**
1. Create `YourFeatureState` in `features/your_feature/domain/`
2. Create actions in `features/your_feature/domain/your_feature_actions.dart`
3. Create `yourFeatureReducer` in `features/your_feature/domain/your_feature_reducer.dart`
4. Add the slice to `AppState` and call the reducer in `appReducer`

---

## Routing

All route paths live in `lib/core/routing/app_routes.dart`. Never hardcode a path string in a widget — always use `AppRoutes.someRoute`.

Navigation uses `context.go(AppRoutes.someRoute)` from GoRouter.

---

## Responsiveness

Three breakpoints defined in `AppTheme`:

| Breakpoint | Width | Layout |
|---|---|---|
| Mobile | < 768px | Bottom nav / drawer |
| Tablet | 768–1023px | Icon-only sidebar rail |
| Desktop | ≥ 1024px | Full sidebar |

Use `ResponsiveHelper.isDesktop(context)` etc. in widgets.

---

## Adding a new page

1. Create the page file in the correct feature's `presentation/` folder
2. Add the route string to `AppRoutes`
3. Add the `GoRoute` entry in `AppRouter` (inside the correct `ShellRoute`)
4. Add the sidebar nav item to `AppSidebar` if it needs a menu entry
