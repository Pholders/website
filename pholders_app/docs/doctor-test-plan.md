# Doctor app — what is integrated, and how to test it

Every doctor obligation in SRS 3.2.1.1 now has code. Nothing below has been
verified against the live API yet: the backend fixes are merged to
`Backend-System` `main` but Render does not auto-deploy. See
`pending-deploy-verification.md` for the deploy checklist.

Test account: `claude.testdoc.integration@pholders.test` / `TestDoc!2026xY`
(doctor id 3).

---

## What is integrated

| Area | Endpoint | State |
|---|---|---|
| Signup, email verification, login, logout | `/users/doctor/*` | live |
| Session restore, route guards | — | live |
| Profile — personal and contact | `GET`/`PUT /users/doctor/profile` | live |
| Professional details, medical aids, consulting hours | same | awaiting deploy |
| Consultation fee | same | live |
| Practice location geocoding | same | awaiting deploy |
| Appointments — inbox, diary, accept, complete | `/users/doctor/appointments` | diary awaiting deploy |
| Prescriptions — list, create, add medicines, sign, revoke | `/prescriptions/*` | live |
| Signing receipt — QR and secure link | `POST /:id/sign` | live |
| Dispensing and revoke detail on the row | `/prescriptions/doctor/all` | awaiting deploy |
| Drug interaction check | `POST /:id/check-interactions` | live |
| Rating from patient reviews | `/users/appointments/doctors/:id/reviews/summary` | awaiting deploy |
| Login activity, device management | `/users/doctor/activity-log`, `/sessions` | live |

---

## Stories the doctor can be tested on alone

These need no other role and no seeded data beyond the test account.

**D1 — Sign in**
Given a registered, active doctor
When they sign in with valid credentials
Then they land on the dashboard, and a reload keeps them signed in.

**D2 — Deep link while signed out**
Given no session
When `/doctor/prescriptions` is opened directly
Then the app shows the login screen, not the page.

**D3 — Edit personal information**
Given a signed-in doctor on Settings › Account › Personal Information
When they change their name or phone and save
Then the change persists across a reload.
And email and HPCSA cannot be edited — the endpoint strips both.

**D4 — Edit professional details**
Given Settings › Account › Professional Details
When they change specialization, practice name, city, province or postal code
and save
Then all of it persists, and nothing they did not touch is blanked.

**D5 — A relocated practice moves on the map**  *(needs the deploy)*
Given the test doctor, whose address reads Sandton but whose coordinates are
Johannesburg CBD
When the profile is saved
Then the coordinates move to roughly -26.104, 28.054.
And if the address cannot be placed at all, the response warns rather than
leaving the doctor silently in the wrong place.

**D6 — Medical aids accepted**  *(needs the deploy)*
Given Professional Details
When they tick schemes and save
Then the selection persists.
And unticking everything persists as "accepts none", not as "unchanged".

**D7 — Consulting hours**  *(needs the deploy)*
Given Professional Details
When they untick a day and change a window, then save
Then the change persists.
And a malformed time is refused with a message, not sent.

**D8 — Consultation fee**
Given Settings › Practice › Fees
When a fee is set
Then it persists. Without one, a patient cannot book — the booking fails on a
not-null violation.

**D9 — Login activity and devices**
Given Settings › Security
Then recent sign-ins and active sessions are listed for this doctor.

---

## Stories that need a patient

Only a patient can book, so none of these can run without one. We have been
seeding via the API: register a patient, log in — patient login returns
`data.tokens.accessToken`, not `data.token` — then `POST
/users/appointments/book`.

**D10 — See a new booking**
Given a patient has booked and paid
When the doctor opens Appointments
Then the booking is listed with the patient's name, date, slot and fee.

**D11 — Accept a booking, and keep it**  *(needs the deploy)*
When the doctor accepts
Then it stays visible in the diary.
Before the fix it vanished, because the endpoint only returned unaccepted
bookings — and with it went the only appointment a script could be written
against.

**D12 — Write and sign a script**
Given an appointment with a patient already on the system
When the doctor creates a prescription, adds medicines and signs
Then the status becomes signed, and the QR and secure link are shown once.
And the dialog says the code cannot be recovered, because it cannot — the
token exists only in that response.

**D13 — Check interactions before signing**
When "Check Interactions" is run on a prescription
Then severities, contraindications and recommended actions are shown.
Note the backend assumes a 35-year-old, 70kg patient unless told otherwise.

**D14 — Withdraw a script**
When the doctor revokes with a reason
Then it reads as revoked, and the reason shows on the row.
A signed script cannot be edited — BR-123 — so revoke is the only withdrawal.

**D15 — Rating**  *(needs the deploy and a patient review)*
Given patients have reviewed this doctor
Then the dashboard shows the count, stars and average.
And a doctor nobody has rated reads "No reviews yet", never 0.0 out of 5.

**D16 — Found by cover**  *(needs the deploy)*
Given a patient whose scheme is in the catalogue
When they search with `coveredByMyMedicalAid`
Then only doctors accepting that scheme are returned.
And a patient whose scheme is not in the catalogue gets an unfiltered list
with `medical_aid_filter_applied: false` — which must never be shown as
"covered by your plan".

---

## Stories that need a pharmacy

**D17 — Dispensing shows on the row**  *(needs the deploy)*
Given a pharmacy has dispensed a signed script
Then the doctor's row reads Dispensed, with the pharmacy and date beneath it,
and the Dispensed filter stops being empty.
There is deliberately no control — pharmacies dispense, doctors display.

**This cannot run today.** A pharmacy cannot be activated: signup issues a
`signup` OTP by email, `verify-otp` is the only thing that sets
`status = 'active'`, and `resend-verification` issues an `email_verification`
OTP that `verify-otp` rejects. A pharmacy whose signup email never arrived is
stuck. Either fix that, or register one with a mailbox the team controls.

---

## Order worth following

1. Deploy, and set `FRONTEND_URL`. Nine items are queued behind it.
2. Run D1–D9. They need nobody else and will catch most regressions.
3. Seed a patient and run D10–D14. These are the phase 1 loop.
4. Fix pharmacy activation, then D17 closes the loop.
5. D15 and D16 need Prince's side to write a review and hold a scheme.
