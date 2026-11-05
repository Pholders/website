import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/models/doctor_registration_draft.dart';
import 'widgets/practice_details_form.dart';
import 'widgets/signup_kit.dart';

/// /register/step-2: step 2 of signing up on a page of its own.
///
/// Step 1 shows step 2 in its own place now ([SignupPanel]), so this page is
/// what an old link or bookmark reaches. The form is the same
/// ([PracticeDetailsForm]).
class DoctorRegisterStep2Page extends StatelessWidget {
  const DoctorRegisterStep2Page({super.key, this.draft});

  /// The personal details captured on step 1. Null when the user landed here
  /// directly (a bookmark, or a refresh, which loses GoRouter's `extra`).
  final DoctorRegistrationDraft? draft;

  @override
  Widget build(BuildContext context) {
    final draft = this.draft;
    // Without step 1's details there is nothing to submit; send the user
    // back rather than submitting half a form.
    if (draft == null) return const _MissingDraftNotice();
    return SignupPageFrame(
      child: PracticeDetailsForm(
        draft: draft,
        compact: MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint,
        onBack: () => context.go(AppRoutes.register),
      ),
    );
  }
}

/// Shown when step 2 is opened without step 1's details.
class _MissingDraftNotice extends StatelessWidget {
  const _MissingDraftNotice();

  @override
  Widget build(BuildContext context) {
    return SignupPageFrame(
      maxWidth: 480,
      child: SignupCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: signupGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restart_alt_rounded,
                    size: 30, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const SignupHeading(
              title: 'Start from the beginning',
              subtitle: 'Your personal details were not carried over, which '
                  'happens after a refresh. Please fill in step 1 again.',
              center: true,
            ),
            const SizedBox(height: 26),
            SignupButton(
              label: 'Back to step 1',
              icon: Icons.arrow_back_rounded,
              onTap: () => context.go(AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }
}
