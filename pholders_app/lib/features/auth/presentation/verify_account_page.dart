import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import 'widgets/signup_kit.dart';
import 'widgets/verify_code_form.dart';

/// /verify: step 3 of signing up on a page of its own.
///
/// Step 2 shows step 3 in its own place now ([SignupPanel]), so this page is
/// what an old link, a bookmark or the standalone step 2 page reaches. The
/// form is the same ([VerifyCodeForm]).
class VerifyAccountPage extends StatelessWidget {
  const VerifyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignupPageFrame(
      maxWidth: 600,
      child: VerifyCodeForm(
        compact: MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint,
      ),
    );
  }
}
