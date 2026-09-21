# Pholders — Phase 1 Requirements

> Last updated: 14 June 2026
> Source: Pholders SRS v1.00 (22 April 2026)
> Status: ✅ = Done | ◐ = Partial | 🔲 = To Do
>
> Phases come from SRS 3.2.1.1. Note the PHR / patient-records work
> is **Phase 3**, not Phase 2.

---

## DOCTOR APP — Phase 1 Requirements

### Authentication & Onboarding

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| D-01 | Doctor Registration (Step 1) | FR-G-001 | Critical | ✅ | Registration form: license number, practice number, doctor type indicator, username, mobile number, password |
| D-02 | Doctor Registration (Step 2) | FR-G-006 | Critical | ✅ | Full profile: email, first name, surname, qualification, practice names, practice numbers, logo, profile picture, gender, signature, consultation rate, operating hours |
| D-03 | OTP Verification | FR-G-002 | Critical | ✅ | OTP verification wired: verify-email + resend-verification |
| D-04 | Post-verification landing (new) | FR-G-003 | Critical | 🔲 | New doctor → lands on Template screen to set up prescription layout |
| D-05 | Post-verification landing (existing) | FR-G-004 | Critical | ✅ | Existing doctor → lands on Dashboard |
| D-06 | Forgot Password | — | High | ✅ | Password reset flow |
| D-07 | Doctor Profile Template | FR-G-005 | High | 🔲 | Doctor supplies profile info on a template showing how prescriptions will look |

### Dashboard

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| D-08 | Doctor Dashboard | FR-G-007, FR-G-008 | Critical | 🔲 | After login, land on dashboard. Show reports: Total Patients, Total Scripts, Patients Per Drug, Prescriptions Per Patient, Drugs Issued, practice insights (patient volume, adherence trends) |

### Prescription Management (Core Feature)

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| D-09 | Create New Prescription | FR-G-010 | Critical | ◐ | Create prescription + medicines + AES sign all live. Speech-to-text and NAPPI codes not done |
| D-10 | Create Prescription for new patient | FR-G-011 | Critical | 🔲 | Doctor can create script for patient not yet on system |
| D-11 | SMS invite to new patient | FR-G-012 | High | 🔲 | System sends patient an SMS with app download link |
| D-12 | Preview Prescription | FR-G-013 | Critical | 🔲 | Doctor views/reviews prescription before publishing to pharmacy network |
| D-13 | Publish to Pharmacy Network | FR-G-013 | Critical | 🔲 | After preview, doctor publishes script → sent to connected pharmacies |
| D-14 | Link Patient to Doctor | FR-G-019 | Critical | 🔲 | When doctor publishes script, patient is automatically linked to that doctor |
| D-15 | Search Scripts | FR-G-014 | High | 🔲 | Search by patient, drug, medical aid, reference number, from date, to date |
| D-16 | View/Email/Print Script | FR-G-015 | High | 🔲 | After search, doctor can view, email, or print a script |
| D-17 | Create/Update/Delete Scripts | FR-G-020 | Critical | ◐ | Create works. Update and delete have no endpoint; revoke is the withdrawal path |

### Appointments & Calendar

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| D-18 | Calendar View | FR-G-009 | High | ✅ | Doctor views appointments in calendar format |

### Sick Notes

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| D-19 | Create/Update/Delete Sick Notes | FR-G-018 | High | 🔲 | Doctor manages sick notes for patients |

### Navigation

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| D-20 | Sidebar/Sliding Menu | FR-G-016, FR-G-017 | Critical | ✅ | Menu items: Dashboard, New Script, Search Scripts, Templates, Calendar, Profile, Settings |

### Settings

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| D-21 | Settings Page (shell) | — | Medium | ✅ | Settings sidebar with categories |
| D-22 | Linked Services | — | Medium | ✅ | Medical Aid, Calendar, Payments, Communication integrations |
| D-23 | Doctor Profile Settings | FR-G-006 | High | ◐ | Personal and Contact Information load and save. Email and HPCSA read-only, the endpoint strips them |
| D-24 | Professional Details Settings | — | High | 🔲 | Medical credentials, practice info |
| D-25 | Fees Setup | — | Medium | ◐ | Consultation fee saves via PUT /users/doctor/profile. Video, phone, time-based and special fees have no column yet |
| D-26 | Notifications Settings | — | Medium | 🔲 | Push/email/SMS notification preferences |
| D-27 | Security Settings | — | Medium | 🔲 | Password, biometric, 2FA, auto-logout |
| D-28 | Device Management | — | Medium | ✅ | Device Management reads GET /users/doctor/sessions |
| D-29 | Login Activity | — | Low | ✅ | Login Activity reads GET /users/doctor/activity-log |

---

## PHARMACY APP — Phase 1 Requirements

### Authentication & Onboarding

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| P-01 | Pharmacist Registration | FR-G-048 | Critical | 🔲 | Registration: pharmacist registration number, pharmacy name, pharmacy practice number, pharmacist indicator, username, mobile, password |
| P-02 | OTP Verification | FR-G-049 | Critical | 🔲 | Send OTP to verify pharmacist's account |
| P-03 | Post-verification landing | FR-G-050 | Critical | 🔲 | After verification → land on Dashboard |
| P-04 | Pharmacist Profile | FR-G-051, FR-G-052 | Critical | 🔲 | Full profile: username, mobile, email, password, first name, surname, pharmacist reg number, pharmacy name, pharmacy practice number, logo, profile picture, gender |

### Dashboard

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| P-05 | Pharmacy Dashboard | FR-G-053, FR-G-054 | Critical | ✅ | After login, land on dashboard. View all scripts published to network. Stats: New Prescriptions, Pending Dispensing, Ready for Pickup, Completed |

### Prescription Management

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| P-06 | View Published Scripts | FR-G-054 | Critical | ✅ | Pharmacist views all scripts published to the pharmacy network |
| P-07 | Claim Script | FR-G-054, BR-026 | Critical | 🔲 | Pharmacist claims a prescription — locks it for that pharmacy only (prevents duplicate dispensing). Real-time status: pending → claimed → preparing → ready |
| P-08 | View Claimed Script Details | FR-G-055 | Critical | 🔲 | After claiming: view script details, additional self-medication, patient personal/medical aid details, collection/delivery choice, generic substitution choice, payment status |
| P-09 | Print Claimed Script | FR-G-054 | High | 🔲 | Print prescription for physical dispensing |
| P-10 | Mark Script as Processed | FR-G-056 | Critical | 🔲 | Pharmacist marks script as processed/dispensed |
| P-11 | Notify Patient | FR-G-057 | Critical | 🔲 | System notifies patient when pharmacist has viewed, printed, or processed their script |

### Orders & Fulfillment

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| P-12 | Orders List | — | High | ✅ | View all orders with status filters |
| P-13 | Order Detail | — | High | ✅ | View order details: patient info, items, totals, linked prescription, payment info |
| P-14 | Mark Order Ready | — | High | 🔲 | Update order status to ready for collection/delivery |
| P-15 | Delivery/Collection Management | BR-029, BR-030 | High | 🔲 | Track whether patient chose collection or delivery. Manage delivery logistics |

### Inventory

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| P-16 | Inventory List | — | High | ✅ | View medication stock with filters |
| P-17 | Stock Management | BR-028 | Medium | 🔲 | Update stock levels, flag low stock, manage availability |
| P-18 | Stock Visibility to Patients | BR-028 | Medium | 🔲 | Real-time stock info shown to patients (optional) |

### Navigation & Settings

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| P-19 | Pharmacy Sidebar | — | Critical | ✅ | Navigation: Dashboard, Prescriptions, Orders, Inventory, Dispensing Queue, Patients, Reports, Billing, Settings |
| P-20 | Settings Page (shell) | — | Medium | ✅ | Settings sidebar with categories |
| P-21 | Linked Services | — | Medium | ✅ | Medical Aid, Calendar, Payments integrations |
| P-22 | Pharmacy Profile Settings | FR-G-052 | High | 🔲 | Edit pharmacy details |

---

## PATIENT APP — Phase 1 Requirements

### Authentication & Onboarding

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-01 | Patient Registration | FR-G-021 | Critical | 🔲 | Indicate patient role, provide username, mobile number, password |
| PT-02 | OTP Verification | FR-G-022 | Critical | 🔲 | OTP sent to verify patient's account |
| PT-03 | Post-verification (has scripts) | FR-G-023 | Critical | 🔲 | If patient received scripts but isn't on system → land on Search Scripts after verification |
| PT-04 | Post-verification (no scripts) | FR-G-025 | Critical | 🔲 | If patient has no scripts and is new → land on Welcome screen |
| PT-05 | Post-login landing | FR-G-026 | Critical | 🔲 | After login → land on Dashboard |

### Dashboard

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-06 | Patient Dashboard | FR-G-027 | Critical | 🔲 | Summary showing: Total Scripts, Nearest Pharmacy, Medical Aid Name/Plan/Number, Last Doctor Visit, Last Medication Received, Next Collection Date, Last Pharmacy Visited, Favorite Pharmacy. Patient can manage which variables to show |

### Find & Book Doctor (CORE Phase 1 Flow)

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-07 | Search Nearby Doctors | FR-G-030, FR-G-042 | Critical | 🔲 | Geolocation-based search. Filter by specialty, availability, ratings, medical aid acceptance |
| PT-08 | View Doctor Details | FR-G-031, FR-G-043 | Critical | 🔲 | View doctor's location, consultation fee, contact details, ratings |
| PT-09 | Book Appointment | FR-G-034, FR-G-044 | Critical | 🔲 | Use form with access to doctor's calendar. Send booking form + patient details to doctor |
| PT-10 | Payment for Consultation | FR-G-035, FR-G-045 | Critical | 🔲 | Self-payment online (if no medical aid) OR provide medical aid details to doctor. Payment confirmation releases script |
| PT-11 | Medical Aid Details Sent | FR-G-046 | Critical | 🔲 | If using medical aid, patient's details including medical aid info sent to doctor |
| PT-12 | Booking Confirmation | FR-G-047 | Critical | 🔲 | Booking sent by combining form + patient details + payment details to doctor |
| PT-13 | Cancel Appointment | FR-G-036 | High | 🔲 | Cancel 3+ working days in advance |
| PT-14 | Refund on Cancellation | FR-G-037 | High | 🔲 | Patient refunded when cancellation is made on time |
| PT-15 | Appointment Reminders | BR-093, Phase 1 | High | 🔲 | Push notifications for upcoming appointments |

### Prescriptions & Medication

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-16 | View Prescriptions | FR-G-024 | Critical | 🔲 | Patient can view all their scripts |
| PT-17 | Email/Print Prescription | FR-G-024 | High | 🔲 | Patient can email or print their scripts |
| PT-18 | Medication Scheduler | FR-G-028 | High | 🔲 | Create schedule for medication reminders. Log: taken/skipped/missed with timestamp |
| PT-19 | Upload Medication Photos | Phase 1 scope | Medium | 🔲 | Upload photos of generics/alternatives for personal records and evidence |

### Pharmacy & Purchasing

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-20 | Send Script to Pharmacy | Phase 1 | Critical | 🔲 | Patient sends digital prescription to network of pharmacies |
| PT-21 | Confirm Collection/Delivery | FR-G-041 | Critical | 🔲 | Patient confirms collection at specific pharmacy or delivery. Or go to any pharmacy |
| PT-22 | Generic Substitution Choice | FR-G-040 | High | 🔲 | Patient specifies choice to allow generic substitution on all products |
| PT-23 | Over-the-Counter Basket | FR-G-038 | Medium | 🔲 | Patient uses basket to purchase OTC medication |
| PT-24 | OTC Linked to Script | FR-G-039 | Medium | 🔲 | OTC medication linked to a script reference |

### My Doctors & Reviews

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-25 | View Linked Doctors | FR-G-029 | High | 🔲 | Patient views details of doctors they're linked to |
| PT-26 | Rate & Review Doctor | Phase 1 scope | High | 🔲 | Post-consultation star rating + comments |

### Navigation

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-27 | Patient Sliding Menu | FR-G-032, FR-G-033 | Critical | 🔲 | Menu: Bookings, Dashboard, Search Scripts, Scheduler, My Doctors, Appointments, Profile, Settings |

### Profile & Medical Aid

| # | Task | SRS Ref | Priority | Status | Description |
|---|------|---------|----------|--------|-------------|
| PT-28 | Patient Profile | — | High | 🔲 | Personal details, contact, medical aid info |
| PT-29 | Medical Aid Details | BR-001 | High | 🔲 | Medical aid name, number, plan, dependent number(s) in profile |

---

## Summary Counts

| App | Total Phase 1 Tasks | Done | Remaining |
|-----|--------------------:|-----:|----------:|
| Doctor | 29 | 8 | 21 |
| Pharmacy | 22 | 9 | 13 |
| Patient | 29 | 0 | 29 |
| **Total** | **80** | **17** | **63** |

---

## Recommended Next Picks (Related to Your Previous Work)

### If continuing Pharmacy:
- P-07: Claim Script (extends your prescriptions table)
- P-08: View Claimed Script Details (extends your prescription detail page)
- P-10: Mark Script as Processed (button already in UI)
- P-01–P-04: Pharmacist registration (same auth pattern as doctor)

### If continuing Doctor:
- D-08: Doctor Dashboard (you have the shell)
- D-09–D-13: Create/Preview/Publish Prescription (THE core feature)
- D-03: OTP backend integration

### If starting Patient:
- PT-01–PT-05: Registration + auth (same pattern)
- PT-06: Patient Dashboard
- PT-07–PT-09: Find doctor + book (core Phase 1 loop)
