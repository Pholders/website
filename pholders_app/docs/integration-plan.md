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
- [x] Pharmacy login — real call, replacing the demo session
- [x] Revoke exercised against a real prescription
- [x] Profile form — Personal and Contact Information now load and save
      (`PUT /users/doctor/profile`). Email and HPCSA are read-only because the
      endpoint strips them.

## To do

- [ ] **Professional Details section** of account settings — specialization,
      experience, practice name and address, city, province, postal code all
      map to real columns but are still decorative. Same pattern as the
      Personal Information section, which is now bound.

- [ ] **Drug interaction check** — `POST /prescriptions/:id/check-interactions`.
      Repository method exists, needs a trigger and somewhere to show results.
- [ ] **Pharmacy prescription queue** — `GET /prescriptions/pharmacy/claimed`,
      `/pharmacy/dispense-history`, `/pharmacy/dispense-stats`,
      `/pharmacy/medicines/:id`, and `POST /:id/dispense`. Waiting on being
      able to activate a pharmacy account — see phase 1 issues.

---

## Not in phase 1

The backend is deliberately frozen at phase 1 while the UI runs ahead, so
anything missing below is **phase 2 or 3 roadmap, not a defect**. Per Prince:
"it's not blockers, it's phase one... whenever you find something that is not
included in the backend, say phase two."

What follows is what the app will need when each phase lands, and what was
learned probing the current API, so nobody has to rediscover it.

### Phase 2 — patients and the PHR

Five doctor-side PHR endpoints exist in some form:

```
POST /users/phr/:patientId/access-request
GET  /users/phr/:patientId
GET  /users/phr/:patientId/personal-card
GET  /users/phr/:patientId/vitals
GET  /users/phr/:patientId/medications
```

Run end to end against doctor 3 / patient 15, the current state is:

| Endpoint | Result |
|---|---|
| `access-request` + patient approval | works |
| `personal-card` | works |
| `vitals` | works |
| `GET /users/phr/:id` | 500 — `column "status" does not exist` |
| `GET /users/phr/:id/medications` | 500 — `column "route" does not exist` |

**One thing to carry into phase 2:** no doctor-callable endpoint returns a
`patientId`. `GET /users/doctor/appointments` gives `patientName`,
`patientEmail` and `patientPhone`; `GET /prescriptions/doctor/all` gives a
name. Adding `patientId` to the appointments mapper is one line and is what
lets the UI open a patient record at all.

Access is also per patient and only the patient can grant it, so a patient
list will show mostly locked rows until each handshake completes. Worth
deciding whether that is the intended UX.

### Phase 2 — other modules

| Feature | Note |
|---|---|
| Doctor billing | Recovered billing screen is ready and showing sample data |
| Sick notes | Screen exists; removed from the sidebar until there is an API |
| Doctor notifications | Recovered screen exists. Current `/notifications` routes are patient-only |
| Edit / delete prescription | Revoke covers withdrawal in phase 1. If edit ever arrives it needs a re-signing story, since the signature is computed over the contents |

### Not backend work at all

Clarified by Prince, these are ours to resolve in the UI:

| Item | Why |
|---|---|
| Mark as dispensed | Doctors sign, pharmacies dispense. The endpoint correctly requires the pharmacy role; the button is simply on the wrong screen |
| Send to pharmacy | Prescriptions reach a pharmacy by email or by scanning the QR. There is no separate "send" action to build |

Open question for the team: remove both from the doctor's prescription row
menu, or leave them visible.

---

## Phase 1 issues worth a look

These are not missing features. They are phase 1 endpoints that exist and
misbehave, so they are listed separately from the roadmap above.

### Revoke applies and then returns 500

`POST /prescriptions/:id/revoke` performs the revoke, then crashes with
`EmailService.sendEmail is not a function` and returns 500. Prescription 3 is
`revoked` in the database despite the error response. `EmailService` has no
`sendEmail` method; the call sites are `prescriptionController.js:592` and
`:919`.

The risk is that a doctor sees a failure for something that worked and assumes
the script is still valid. The app refetches after a failed sign or revoke so
the list reflects what the server actually holds, which hides the symptom.

Two related problems on our side, both fixed: the app sent `reason` instead of
`revokeReason`, and treated it as optional when it is required.

### A pharmacy cannot be activated without its original signup email

Three endpoints disagree about which OTP they mean:

| Endpoint | OTP purpose | Effect |
|---|---|---|
| `POST /users/pharmacy/verify-otp` | `signup` | sets `status = 'active'`, the only thing that lets a pharmacy log in |
| `POST /users/pharmacy/resend-verification` | `email_verification` | issues a code `verify-otp` always rejects |
| `POST /users/pharmacy/verify-email` | `email_verification` | sets `email_verified` but not `status` |

Confirmed live: after `verify-email` the API says "Email verified
successfully. You can now log in", and the next login returns "Account is
inactive." Doctors are unaffected — doctor signup creates the account active.

Pharmacy login is wired from the controller's response shape but could not be
exercised end to end for this reason.

### Smaller ones

1. **QR link points at localhost.** Signing returns
   `accessLink: http://localhost:3000/prescriptions/qr/...` from the deployed
   server. Since scanning at the pharmacy is a real path, this matters.
2. **Re-login is refused while a stale session exists.** `preventAuthenticated`
   returns "Already logged in as doctor. Please log out first." Close the tab
   without logging out and correct credentials fail until cookies are cleared.
3. **Live server runs `NODE_ENV=development`**, so `resend-verification`
   returns the OTP in the HTTP response. Anyone can request a code for any
   unverified account and read it.
4. **Booking fails when a doctor has no consultation fee** — a not-null
   violation surfaced as "Failed to book appointment".
5. **Cash bookings auto-cancel.** `appointmentCleanupService` cancels
   `pending_payment` bookings after a timeout, and `cash_on_arrival` starts in
   that state, so appointment 5 vanished before it could be accepted. Worth
   confirming the timeout is meant to apply to cash.
