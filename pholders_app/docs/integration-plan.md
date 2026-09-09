# Integration plan

Working list for wiring the Flutter app to the API at
`https://backend-system-u8s2.onrender.com/api`.

**Rule for this work:** do not redesign screens. Bind data to the UI that is
already there. Only touch layout to fix something broken — a button that does
nothing, a list that cannot scroll.

**Contracts come from the controllers, not `docs/api/roles/*.md`.** The docs
have been wrong about login, signing, signup fields and the medicine payload.

---

## Done

- [x] API client, token storage, auth middleware, route guard
- [x] Doctor signup, email verification, login, logout
- [x] Session restore across reload; guard blocks deep links when signed out
- [x] Doctor profile read (`GET /users/doctor/profile`)
- [x] Doctor profile update (`PUT /users/doctor/profile`)
- [x] Appointments list (`GET /users/doctor/appointments`)
- [x] Prescriptions list (`GET /prescriptions/doctor/all`)
- [x] Create prescription + add medicines + sign
- [x] Revoke wired (confirm dialog); not yet exercised against a real script
- [x] Appointment accept + complete — tap an appointment card to open actions
- [x] Doctor activity log into the Login Activity screen
- [x] Doctor sessions into the Device Management screen
- [x] Pharmacy login — real call, replacing the demo session (see blocker 5)

## To do

- [ ] **Exercise revoke** once against a real prescription.
- [ ] **Drug interaction check** — `POST /prescriptions/:id/check-interactions`.
      Repository method exists, needs a trigger and somewhere to show results.
- [ ] **Doctor settings forms** — bind the practice and account settings
      screens to `PUT /users/doctor/profile`.
- [ ] **Pharmacy prescription queue** — `GET /prescriptions/pharmacy/claimed`,
      `/pharmacy/dispense-history`, `/pharmacy/dispense-stats`,
      `/pharmacy/medicines/:id`, and `POST /:id/dispense`. Blocked on being
      able to sign a pharmacy in at all — see blocker 5.

---

## Blockers

Things that cannot be integrated from the frontend. Grouped by cause.

### 1. Doctor cannot discover a patient id — blocks the whole Patients section

Five PHR endpoints exist for doctors and would fill the patient screens:

```
POST /users/phr/:patientId/access-request
GET  /users/phr/:patientId
GET  /users/phr/:patientId/personal-card
GET  /users/phr/:patientId/vitals
GET  /users/phr/:patientId/medications
```

All need a `patientId`. **No doctor-callable endpoint returns one.**
`GET /users/doctor/appointments` returns `patientName`, `patientEmail` and
`patientPhone` but no id. `GET /prescriptions/doctor/all` returns a patient
name only. There is no doctor-to-patient list endpoint at all.

*Ask:* add `patientId` to the doctor appointments and prescriptions payloads,
or add a doctor patients endpoint. One line in the appointments mapper would
unblock the entire patient section.

Two further problems found by running the flow end to end with a real patient
(doctor 3 / patient 15), so these are confirmed, not assumed:

**Access is per patient and only the patient can grant it.** The doctor's
`access-request` works and the patient's approve works, but until that
handshake completes every read returns "You do not have access to this patient
PHR". Any patient list would therefore be mostly locked rows.

**Two of the four doctor PHR endpoints are broken server-side**, with SQL
errors rather than empty results:

| Endpoint | Result |
|---|---|
| `GET /users/phr/:id` | 500 — `column "status" does not exist` |
| `GET /users/phr/:id/personal-card` | works |
| `GET /users/phr/:id/vitals` | works |
| `GET /users/phr/:id/medications` | 500 — `column "route" does not exist` |

So even with an id and approval, the full record and the medication list — the
two the patient screens most need — cannot be read.

### 2. No endpoints at all

| Feature | Note |
|---|---|
| Edit prescription | No `PUT`/`PATCH`. Probably correct — the signature is computed over the contents — but the button exists in the UI. |
| Delete prescription | No `DELETE`. `revoke` is the intended withdrawal and keeps an audit trail. |
| Send to pharmacy | Nothing implements it. |
| Doctor billing | No endpoint. The recovered billing screen shows sample data. |
| Sick notes | No endpoint anywhere. |

### 3. Wrong role

| Feature | Note |
|---|---|
| Mark as dispensed | `POST /prescriptions/:id/dispense` requires the pharmacy role; a doctor cannot call it, but the button is on the doctor's screen. |
| Notifications | Every `/notifications` route is `requireRole('patient')`. The recovered doctor and pharmacy notification screens have no API. |

### 4. Backend defects

1. **QR access link points at localhost.** Signing returns
   `accessLink: http://localhost:3000/prescriptions/qr/...` from the deployed
   server, so a scanned prescription will not resolve.
2. **`preventAuthenticated` locks users out.** Logging in again while a server
   session exists is rejected with "Already logged in as doctor. Please log out
   first." Close the tab without logging out and correct credentials fail
   until cookies are cleared.
3. **Live server runs `NODE_ENV=development`.** `resend-verification` returns
   the OTP in the HTTP response, so anyone can request a code for any
   unverified account and read it. Escalate this one first.
4. **Booking fails when a doctor has no consultation fee** — a not-null
   violation surfaced as "Failed to book appointment". Needs either a default
   or a clearer error.

### 5. A pharmacy that loses its signup email can never activate

Found while trying to create a test pharmacy. Two endpoints disagree about
which OTP they are talking about:

| Endpoint | OTP purpose | Effect |
|---|---|---|
| `POST /users/pharmacy/verify-otp` | `signup` | sets `status = 'active'` — the only thing that lets a pharmacy log in |
| `POST /users/pharmacy/resend-verification` | `email_verification` | issues a code `verify-otp` will always reject |
| `POST /users/pharmacy/verify-email` | `email_verification` | sets `email_verified`, but **not** `status` |

So the only route to an active pharmacy is the code in the original signup
email. Nothing can reissue a `signup`-purpose OTP. Confirmed live: after
`verify-email` the API replies "Email verified successfully. You can now log
in", and the very next login attempt returns "Account is inactive. Please
contact support."

Doctors do not have this problem — doctor signup creates the account already
active.

*Consequence for the app:* pharmacy login is wired and the response shape is
taken from the controller, but it could not be exercised end to end, because no
pharmacy account can be activated without a real mailbox.

*Ask:* have `verify-email` also set `status = 'active'`, or have
`resend-verification` issue a `signup`-purpose OTP.
