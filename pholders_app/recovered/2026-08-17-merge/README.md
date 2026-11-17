# Code recovered from the 2026-08-17 merge

Merge commit `b5a82e0` ("Merge branch 'Prince' ... into Prince") resolved its
conflicts by dropping files instead of merging them. 70 files and roughly
20,700 lines of working code disappeared from the main line, and several more
files were reverted to placeholder stubs. That is why the doctor dashboard,
billing, pharmacy reports and the patient/prescription screens were empty.

Everything recoverable was taken from `9068f13`, the commit immediately before
that merge.

## What went back into `lib/`

All the UI: the doctor dashboard, billing, the doctor and pharmacy patient and
prescription screens, pharmacy reports, pharmacy settings, notifications, the
dispensing queue, the PDF helpers and the route constants they need.

## What is parked here, and why

This folder holds a **second, parallel architecture** that also went missing: a
clean-architecture auth stack (repositories, use cases, entities), an admin
login/OTP/dashboard flow, and a separate Redux store under `store/`.

It is not wired into the app because it overlaps with the Redux + repository
auth layer now in `lib/core/`. Both cannot own authentication at once, so
reintegrating it is a deliberate decision for the team, not an automatic merge.

Notable pieces worth reviewing before discarding any of it:

- `lib/core/network/legacy_api_client.dart` — a Dio client with redaction of
  passwords, tokens and OTPs from logs, and cold-start-aware timeouts.
- `lib/features/auth/domain/usecases/` — login, admin login, admin OTP verify
  and session restore as explicit use cases.
- `lib/features/admin/` — an admin dashboard the current app has no equivalent of.
- `lib/store/` — an alternative Redux store with integrations state.
- `test/auth_reducer_test.dart`, `test/integrations_reducer_test.dart` — tests
  for the above.

`analysis_options.yaml` excludes this folder, so nothing here affects the build.
Delete the folder only once the team has decided what to keep.
