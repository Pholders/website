# End-to-end test plan

Phase 1 is one loop that crosses four apps. The per-app plans check each piece;
this one checks the handoffs between them, which is where every defect we have
found so far actually lived.

Run after the deploy. Nothing here works against the build currently live.

## Accounts needed

| Role | Account |
|---|---|
| Doctor | `claude.testdoc.integration@pholders.test` / `TestDoc!2026xY` (id 3) |
| Patient | `claude.patient.1791366420@pholders.test` / `TestPat!2026xY` (id 16) |
| Pharmacy | None yet — create one, then activate it with `PATCH /users/admin/pharmacies/:id/status` |
| Admin | Existing admin account |

Activate the pharmacy through the admin route rather than email: signup codes
only arrive by post, and the test addresses cannot receive mail.

---

## Journey A — the phase 1 loop

The sentence the SRS opens phase 1 with, end to end. Every step is a different
app; the handoffs are the point.

| # | Role | Action | Expected |
|---|---|---|---|
| A1 | Patient | Search for a doctor near you | Doctors listed by distance, each with a fee |
| A2 | Patient | Book a slot | Appointment created, status `pending_payment` |
| A3 | Patient | Pay — cash, card or medical aid | Status becomes `scheduled` |
| A4 | Doctor | Open Appointments | The booking is listed with the patient's name |
| A5 | Doctor | Accept it | **It stays in the diary.** Before the fix it vanished |
| A6 | Doctor | Complete the consultation | Status `completed` |
| A7 | Doctor | Create a script against it, add medicines, sign | QR and secure link shown **once** |
| A8 | Patient | Open the prescription | It is listed and readable |
| A9 | Patient | Send it to a pharmacy | A pharmacy list appears; after confirming, the script reads claimed |
| A10 | Pharmacy | Open the dispensing queue | **The script is there.** This is the handoff that has never worked |
| A11 | Pharmacy | Dispense it | Moves to Dispensed |
| A12 | Doctor | Reopen the prescription list | Reads Dispensed, naming the pharmacy and date, read-only |
| A13 | Patient | Review the doctor | Accepted |
| A14 | Doctor | Open the dashboard | The Reviews tile shows the count, stars and average |

A5, A10, A12 and A14 are the four handoffs that were broken. They are the ones
worth watching.

### What should fail

| Try | Expect |
|---|---|
| Claim the same script at a second pharmacy | Refused — one pharmacy per script |
| Dispense a script claimed at a different pharmacy | Refused |
| Dispense the same script twice | Refused |
| Sign a prescription with no medicines | Refused |
| Edit a signed prescription | No such action exists — revoke is the only withdrawal |
| Review the same doctor twice | Refused |

---

## Journey B — found by cover

Phase 1: "if under medical aid, doctor that's covered by medical plan".
It spans three apps and fails silently if any one of them is wrong.

| # | Role | Action | Expected |
|---|---|---|---|
| B1 | Doctor | Professional Details, tick accepted schemes, save | Persists across a reload |
| B2 | Patient | Record a medical aid | Saved on the device **and** on the server |
| B3 | Patient | Search with the cover filter on | Only doctors accepting that scheme |
| B4 | Patient | Check the response | `medical_aid_filter_applied: true` |
| B5 | Patient | Book and pay by medical aid | Appointment scheduled |

**The case that matters most:** B2 with a scheme spelled differently — type
"Discovery" where the doctor picked "Discovery Health Medical Scheme". They
should still match; both normalise to the same key.

**And the one that must not mislead:** record a scheme not in the catalogue at
all. The search returns **every** doctor with `medical_aid_filter_applied:
false`. The screen must not label that "covered by your plan".

---

## Journey C — the pharmacy network

Phase 1 bullet 6. All admin, but it decides what the pharmacy app can do.

| # | Role | Action | Expected |
|---|---|---|---|
| C1 | Admin | Open the pharmacy directory | Every pharmacy listed, including any in no group |
| C2 | Admin | Approve a pending pharmacy | Status becomes active; it can now sign in |
| C3 | Admin | Suspend one | It can no longer sign in |
| C4 | Admin | Create a group, add pharmacies | Membership persists |
| C5 | Admin | Create an agreement, activate it | Status reflects it |
| C6 | Admin | Search groups, list expiring agreements | **Both return results.** They were unreachable through a route-ordering fault |
| C7 | Admin | Open compliance and claim routing | Dashboards populate |

---

## Journey D — withdrawal

What happens when a doctor revokes a script the patient already holds. Worth
testing because it crosses all three apps and nobody has run it.

| # | Role | Action | Expected |
|---|---|---|---|
| D1 | Doctor | Revoke a signed, unclaimed script with a reason | **Returns 200**, not a 500 for work it did |
| D2 | Doctor | Check the list | Reads Revoked, with the reason |
| D3 | Patient | Open that prescription | Reflects the revoke |
| D4 | Patient | Try to send it to a pharmacy | Refused |

**Open question for the team, not a test:** what should happen when a doctor
revokes a script a pharmacy has already claimed but not dispensed? The
pharmacy's queue is not notified today. Worth deciding before a real patient
hits it.

---

## Journey E — reminders

| # | Role | Action | Expected |
|---|---|---|---|
| E1 | Patient | Set a reminder on an upcoming appointment | Saved |
| E2 | — | Wait for it to fire | Email arrives |
| E3 | Patient | Open notifications | The in-app reminder is there |

E3 is new. The table it writes to did not exist until this deploy, and the
insert was wrapped in a catch that logged and carried on, so it silently did
nothing. **SMS and push are still console stubs** — do not raise those as
defects.

---

## Cross-cutting

Run these once, in any journey.

| Check | Why |
|---|---|
| Sign out and back in as a different pharmacy | The previous pharmacy's queue and orders must be gone |
| Sign out as a doctor, sign in as another | No prescriptions, appointments or rating carried over |
| Call a pharmacy route with a doctor token | Refused |
| Call an admin route with a patient token | Refused |
| Reload mid-session | Still signed in, same place |
| Open a deep link while signed out | Login, not the page |
| Scan a prescription QR | Opens. If it still points at `localhost`, `FRONTEND_URL` was not set with the deploy |

---

## Known, not defects

Do not file these.

- **SMS and push reminders** are console stubs.
- **Inventory** has no backend at all — no routes, no controller, no model.
- **Refills** do not exist as a concept anywhere.
- **Sick notes** have no API. The requirement exists (FR-G-020) but is not in
  phase 1.
- **Doctor billing** is out of scope in the SRS, twice.
- **PHR / patient records** are phase 3.
- **Editing a signed prescription** is forbidden by BR-123, by design.
- **Dispensing from the doctor app** is not offered; pharmacies dispense,
  doctors display.
