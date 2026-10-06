# Waiting on a deploy

Backend fixes are merged to `Backend-System` `main` but the Render service
does not auto-deploy, so the live API is still running the old build. Deploys
are manual and we are waiting on Oratile to get the credentials.

Everything below is **written and tested locally, unverified against the live
API**. Each item says exactly how to check it once the deploy lands.

Nothing here breaks the old backend: every new field is optional and the one
new query parameter defaults to the existing behaviour. The app runs against
either build.

Last checked: 2026-10-06 — live API still returns `Doctor.getById is not a
function`.

---

## What changed

| # | Change | Commit | Repo |
|---|---|---|---|
| 1 | `Doctor.getById` → `findById` (3 call sites) | `07f37e3` | Backend-System |
| 2 | Added the missing `EmailService.sendEmail` | `07f37e3` | Backend-System |
| 3 | Doctor prescription list returns the fields it already queried | `07f37e3` | Backend-System |
| 4 | Doctor appointments return `patientId`; added `scope` | `07f37e3` | Backend-System |
| 5 | Prescription row shows dispensing and revoke detail | `f6f0ce6` | website |
| 6 | Appointments load the whole diary, not just the inbox | pending | website |

Still outstanding, deliberately not done:

- **Medical aid acceptance on `doctors`** — needs a migration against the
  shared database, so it was deferred rather than slipped in with code fixes.
- **`FRONTEND_URL` on Render** — unset, so `QRCodeService` falls back to
  `http://localhost:3000`. The signing dialog warns about it, but the link
  cannot work until the env var is set. Set it at the same time as the deploy.

---

## Verification checklist

Get a token first:

```bash
B=https://backend-system-u8s2.onrender.com/api
T=$(curl -s -X POST $B/users/doctor/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"claude.testdoc.integration@pholders.test","password":"TestDoc!2026xY"}' \
  | python -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
```

### 1. Reviews no longer 500

```bash
curl -s "$B/users/appointments/doctors/3/reviews/summary"
```

- **Before:** `"error": "Doctor.getById is not a function"`
- **After:** `success: true` with a rating summary.

Also worth having Prince check that a patient can now submit a review, since
the same three call sites blocked that.

### 2. Revoke stops returning 500 for work it did

Revoke any signed prescription and watch the status code, not just the list.

- **Before:** the revoke applied and then returned 500 from
  `EmailService.sendEmail is not a function`. A doctor saw a failure for
  something that had worked.
- **After:** 200.

The app refetches after a failed revoke, so this was invisible in the UI. Check
the raw response, not the screen.

The same method also unblocks `POST /prescriptions/:id/share-email`, which is
patient-role — the patient emailing their script. Worth telling Prince.

### 3. Prescription list carries the new fields

```bash
curl -s "$B/prescriptions/doctor/all" -H "Authorization: Bearer $T"
```

Each row should now also carry `patientId`, `appointmentId`, `isRevoked`,
`revokeReason`, `isDispensed`, `dispensedAt`, `dispensedByPharmacyName`.

- **Before:** six keys only — `id, prescriptionNumber, patient, diagnosis,
  status, createdAt`.

### 4. Appointment scopes

```bash
curl -s "$B/users/doctor/appointments"               -H "Authorization: Bearer $T"
curl -s "$B/users/doctor/appointments?scope=upcoming" -H "Authorization: Bearer $T"
curl -s "$B/users/doctor/appointments?scope=all"      -H "Authorization: Bearer $T"
curl -s "$B/users/doctor/appointments?scope=nonsense" -H "Authorization: Bearer $T"
```

- No `scope` must behave exactly as before — unaccepted bookings only. This is
  the important one: anything already built depends on it.
- `upcoming` returns accepted, scheduled, not in the past.
- `all` drops the accepted filter.
- An unknown scope returns 400 rather than silently listing everything.
- Every row should carry `patientId`.

### 5. Dispensing shows on the prescription row

Needs a dispensed prescription, which needs an activated pharmacy — see the
pharmacy activation problem in `integration-plan.md`. Until then this can only
be checked by setting `is_dispensed` directly on a test row.

Expected: the row's badge reads **Dispensed** instead of Approved, with a line
under it naming the pharmacy and date. A revoked row shows its reason. Neither
is editable — pharmacies dispense, doctors display.

The **Dispensed** filter tab should also stop being permanently empty.

### 6. The diary stops losing accepted appointments

Accept an appointment, then reload the appointments page.

- **Before:** it disappeared. The endpoint only returned unaccepted bookings,
  so the doctor's own day was invisible to them — and because the new
  prescription dialog reads the same list, there was no appointment left to
  write a script against.
- **After:** it stays, with the Accept button gone and the status showing it
  was accepted.

This one is the clearest to check through the UI rather than curl.

---

## If something fails

The frontend tolerates both builds, so a bad deploy is not an emergency: roll
the service back and the app keeps working, minus these features. The backend
changes are additive — no column was dropped, no response field removed, no
existing default changed.
