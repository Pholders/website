# Requirements Document

## Introduction

A Flutter web application serving two distinct roles: **Pharmacy** and **Doctor**. The app provides role-based navigation with shared layout components (sidebar, top navbar, footer) and a clean, modular codebase designed for team collaboration. The project is web-first and scaffolded from a Figma design, with empty pages created for every screen before implementation begins.

Authentication is handled via a real REST API: the Auth_Service calls an external endpoint, receives a JWT token and role in the response, and stores the token for subsequent requests. All application state — authentication, navigation, and feature-level state — flows through a centralised Redux_Store using the `flutter_redux` package, with one Reducer per feature module. The layout is fully responsive across three breakpoints (mobile, tablet, desktop), with the Sidebar adapting its presentation at each breakpoint.

## Glossary

- **App**: The Flutter web application described in this document.
- **Pharmacy_User**: An authenticated user with the Pharmacy role.
- **Doctor_User**: An authenticated user with the Doctor role.
- **Auth_Service**: The module responsible for authentication, session management, and role resolution. It communicates with the REST_API to obtain a JWT token and the user's role.
- **Router**: The Go Router (or equivalent) module responsible for declarative, URL-based navigation.
- **Shell_Layout**: The shared scaffold wrapping all authenticated pages, containing the Top_Navbar, Sidebar, and Footer.
- **Top_Navbar**: The horizontal navigation bar displayed at the top of every authenticated page.
- **Sidebar**: The vertical navigation panel displayed on the left side of every authenticated page on desktop viewports, with role-specific menu items.
- **Footer**: The horizontal bar displayed at the bottom of every authenticated page.
- **Page**: A full-screen Flutter widget mapped to a unique URL route.
- **Feature_Module**: A self-contained folder grouping all files (UI, logic, models) for a single feature or screen.
- **Shared_Module**: A folder containing widgets, utilities, constants, and theme files reused across feature modules.
- **Figma_Design**: The Figma file provided by the user that defines the visual structure of all screens.
- **REST_API**: The external HTTP API that the Auth_Service calls to authenticate users and retrieve a JWT token and role.
- **Redux_Store**: The single, centralised state container for the App, implemented using the `flutter_redux` package. All application state is read from and written to the Redux_Store.
- **Reducer**: A pure function that takes the current state and an Action and returns the next state. Each Feature_Module defines its own Reducer.
- **Action**: A plain Dart object that describes a state change intent. Actions are dispatched to the Redux_Store and processed by the appropriate Reducer.
- **Breakpoint**: A viewport-width threshold at which the Shell_Layout changes its structural presentation. Three breakpoints are defined: Mobile (< 768 px), Tablet (768 px – 1023 px), and Desktop (≥ 1024 px).

---

## Requirements

### Requirement 1: Role-Based Authentication

**User Story:** As a user, I want to log in with my credentials and be directed to the correct role-specific area, so that Pharmacy users and Doctor users each see only their relevant interface.

#### Acceptance Criteria

1. WHEN a user submits valid credentials, THE Auth_Service SHALL send the credentials to the REST_API authentication endpoint and receive a JWT token and a role value (`pharmacy` or `doctor`) in the response.
2. WHEN the REST_API returns a successful authentication response, THE Auth_Service SHALL store the JWT token in secure browser storage (e.g., `flutter_secure_storage` or an equivalent mechanism) and dispatch an Action to the Redux_Store recording the authenticated user's role.
3. WHEN authentication succeeds, THE Router SHALL redirect the user to the default home page for their resolved role.
4. IF a user submits invalid credentials, THEN THE Auth_Service SHALL return a descriptive error message without exposing internal system details or the raw REST_API error body.
5. WHEN an unauthenticated user attempts to access a protected route, THE Router SHALL redirect the user to the login page.
6. WHEN an authenticated user attempts to access a route belonging to the opposite role, THE Router SHALL redirect the user to their own role's home page.
7. WHEN a user logs out, THE Auth_Service SHALL remove the stored JWT token, dispatch a logout Action to the Redux_Store, and THE Router SHALL redirect the user to the login page.
8. WHEN the JWT token has expired and the user attempts an authenticated action, THE Auth_Service SHALL attempt a token refresh using the REST_API refresh endpoint; IF the refresh fails, THEN THE Auth_Service SHALL treat the session as expired and redirect the user to the login page.
9. WHILE a valid JWT token is stored, THE Auth_Service SHALL attach the token as a Bearer token in the `Authorization` header of every outgoing REST_API request.

---

### Requirement 2: Redux State Management

**User Story:** As a developer, I want all application state to flow through a single Redux store, so that state changes are predictable, traceable, and consistent across every feature module.

#### Acceptance Criteria

1. THE App SHALL use the `flutter_redux` package as the sole state management solution for all application state, including authentication state, navigation state, and feature-level state.
2. THE App SHALL define a single `AppState` class that composes the state slices of every Feature_Module and the `core/` modules into one top-level Redux_Store.
3. EACH Feature_Module SHALL define its own Reducer, initial state class, and set of Actions in its `domain/` subdirectory; no Feature_Module SHALL directly mutate the state of another Feature_Module.
4. THE `core/auth/` module SHALL define an `AuthState` slice containing at minimum: the JWT token, the authenticated user's role, and a loading/error status; this slice SHALL be managed by a dedicated `authReducer`.
5. WHEN an Action is dispatched to the Redux_Store, THE corresponding Reducer SHALL return a new immutable state object; no Reducer SHALL mutate the existing state in place.
6. THE App SHALL initialise the Redux_Store at application startup in the `app/` directory and provide it to the widget tree via the `StoreProvider` widget from `flutter_redux`.
7. THE App SHALL document the Redux slice organisation (store structure, Action naming conventions, and Reducer locations) in the project `README.md`.
8. WHERE a widget needs to read state from the Redux_Store, THE widget SHALL use `StoreConnector` or `StoreBuilder` from `flutter_redux`; no widget SHALL hold authoritative application state in local `StatefulWidget` state when that state is shared across modules.

---

### Requirement 3: Role-Based Navigation Structure

**User Story:** As a Pharmacy user or Doctor user, I want a navigation structure tailored to my role, so that I can access only the screens relevant to my workflow.

#### Acceptance Criteria

1. WHILE a Pharmacy_User is authenticated, THE Sidebar SHALL display only the navigation items defined for the Pharmacy role.
2. WHILE a Doctor_User is authenticated, THE Sidebar SHALL display only the navigation items defined for the Doctor role.
3. WHEN a user selects a navigation item in the Sidebar, THE Router SHALL navigate to the corresponding Page without a full page reload.
4. THE Router SHALL use URL-based routing so that each Page is accessible via a unique, bookmarkable URL path.
5. WHILE a user is on a given Page, THE Sidebar SHALL visually highlight the active navigation item corresponding to that Page.

---

### Requirement 4: Shared Shell Layout

**User Story:** As a user, I want a consistent layout across all authenticated pages, so that the experience feels unified and predictable regardless of which screen I am on.

#### Acceptance Criteria

1. WHILE a user is authenticated, THE Shell_Layout SHALL render the Top_Navbar, Sidebar, and Footer on every Page.
2. THE Shell_Layout SHALL render the Top_Navbar at the top of the viewport, the Sidebar on the left, the Footer at the bottom, and the Page content in the remaining central area.
3. THE Top_Navbar SHALL display the application logo, the current user's name, and a logout action.
4. THE Footer SHALL display static content (e.g., copyright, version) consistent across both roles.
5. WHERE the Figma_Design specifies role-specific Top_Navbar content, THE Top_Navbar SHALL render the role-specific variant for the authenticated user's role.
6. THE Shell_Layout SHALL NOT be rendered on the login page or any unauthenticated route.

---

### Requirement 5: Figma-Driven Page Scaffolding

**User Story:** As a developer, I want an empty Page widget created for every screen defined in the Figma design, so that the full navigation structure is in place before any screen is implemented.

#### Acceptance Criteria

1. WHEN the Figma design is provided, THE App SHALL contain one Page widget per screen defined in the Figma_Design, each mapped to a unique route.
2. THE App SHALL scaffold each Page as an empty widget displaying the screen's name as a placeholder, with no business logic.
3. THE Router SHALL register all scaffolded Page routes so that every screen is navigable from the Sidebar or Top_Navbar immediately after scaffolding.
4. WHEN a scaffolded Page is navigated to, THE Shell_Layout SHALL render correctly around the empty placeholder content.

---

### Requirement 6: Modular Folder Structure

**User Story:** As a developer on the team, I want a well-defined, modular folder structure, so that I can locate, understand, and modify any part of the codebase without needing to understand the entire project.

#### Acceptance Criteria

1. THE App SHALL organize source code under `lib/` using the following top-level directories: `core/`, `features/`, `shared/`, and `app/`.
2. THE `core/` directory SHALL contain subdirectories for `auth/`, `routing/`, and `di/` (dependency injection).
3. THE `features/` directory SHALL contain one subdirectory per Feature_Module, named after the feature in snake_case.
4. EACH Feature_Module directory SHALL contain subdirectories for `presentation/` (widgets and pages), `domain/` (models and use cases), and `data/` (repositories and data sources) where applicable.
5. THE `shared/` directory SHALL contain subdirectories for `widgets/`, `theme/`, `constants/`, and `utils/`.
6. THE `app/` directory SHALL contain the root `App` widget and the top-level router configuration.
7. THE App SHALL define a single `AppTheme` class in `shared/theme/` that centralises all colors, text styles, and spacing constants used across the application.

---

### Requirement 7: Code Quality and Team Collaboration Standards

**User Story:** As a team member, I want consistent code style and documentation standards enforced across the project, so that any teammate can read, review, and extend any part of the codebase with minimal onboarding.

#### Acceptance Criteria

1. THE App SHALL include an `analysis_options.yaml` file at the project root that enables `flutter_lints` (or `very_good_analysis`) with no overridden rules that reduce strictness.
2. EVERY public class, method, and widget in the `shared/` and `core/` directories SHALL include a Dart doc comment describing its purpose.
3. THE App SHALL define a `README.md` at the project root documenting the folder structure, how to run the project, and how to add a new feature module.
4. WHEN a developer adds a new Page, THE Router configuration SHALL be the single source of truth for all route definitions, with no hardcoded route strings outside the router module.
5. THE App SHALL use a state management solution consistently across all Feature_Modules, with the chosen solution documented in the `README.md`.

---

### Requirement 8: Flutter Web Responsiveness

**User Story:** As a user accessing the app from a browser, I want the layout to adapt to different browser window sizes, so that the app remains usable and well-structured across mobile, tablet, and desktop viewports.

#### Acceptance Criteria

1. THE App SHALL define the following Breakpoints as named constants in `AppTheme`: Mobile (viewport width < 768 px), Tablet (768 px ≤ viewport width < 1024 px), and Desktop (viewport width ≥ 1024 px).
2. WHILE the viewport width is at the Desktop Breakpoint (≥ 1024 px), THE Shell_Layout SHALL display the full Sidebar on the left at its defined fixed width, with the Page content occupying the remaining horizontal space.
3. WHILE the viewport width is at the Tablet Breakpoint (768 px – 1023 px), THE Shell_Layout SHALL replace the full Sidebar with either an icon-only navigation rail or a hamburger-triggered drawer; the Page content SHALL occupy the full width minus the rail (if a rail is used).
4. WHILE the viewport width is at the Mobile Breakpoint (< 768 px), THE Shell_Layout SHALL replace the Sidebar with a bottom navigation bar or a full-screen drawer accessible via a menu icon; no persistent side panel SHALL be visible.
5. WHEN the viewport width crosses a Breakpoint boundary, THE Shell_Layout SHALL transition to the appropriate navigation presentation without requiring a page reload.
6. WHEN the viewport width is 1440 px or wider, THE Shell_Layout SHALL constrain the maximum content width to a value defined in `AppTheme` to prevent excessive line lengths.
7. THE Shell_Layout SHALL render without horizontal scrolling or layout overflow at any viewport width at or above 320 px.
8. WHERE the Figma_Design specifies breakpoint-specific layout details that differ from the above criteria, THE Shell_Layout SHALL implement the Figma_Design specification and the deviation SHALL be documented in the `README.md`.
