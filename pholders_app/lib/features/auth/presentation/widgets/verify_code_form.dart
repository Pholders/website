import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../../../../core/auth/auth_actions.dart';
import '../../../../core/routing/app_routes.dart';
import 'signup_kit.dart';

/// Step 3 of signing up, the last: the six-digit code emailed to the new
/// account, which activates it. Then on to signing in.
///
/// Shown by step 2 in its place ([SignupPanel]) once the account is
/// created, and by the /verify page ([VerifyAccountPage]).
///
/// Typing moves along the boxes and backspace moves back; a code pasted into
/// any box fills them all; a full code verifies itself.
class VerifyCodeForm extends StatefulWidget {
  const VerifyCodeForm({super.key, this.compact = false});

  static const length = 6;

  /// Phones: smaller gaps between the boxes.
  final bool compact;

  @override
  State<VerifyCodeForm> createState() => _VerifyCodeFormState();
}

class _VerifyCodeFormState extends State<VerifyCodeForm> {
  final List<TextEditingController> _controllers =
      List.generate(VerifyCodeForm.length, (_) => TextEditingController());
  // Each box hears backspace first, before the field acts on it.
  late final List<FocusNode> _focusNodes = List.generate(
    VerifyCodeForm.length,
    (i) => FocusNode(onKeyEvent: (_, e) => _onKey(i, e)),
  );

  /// Set when the code was asked for again, to say so.
  bool _resent = false;

  /// The boxes joined into one code.
  String get _code => _controllers.map((c) => c.text.trim()).join();

  void _submit(String? email) {
    if (email == null) {
      // Nothing to verify against, so send the user to sign in instead.
      context.go(AppRoutes.login);
      return;
    }
    if (_code.length != VerifyCodeForm.length) return;
    StoreProvider.of<AppState>(context)
        .dispatch(VerifyEmailRequestAction(email: email, otpCode: _code));
  }

  void _resend(String? email) {
    if (email == null) return;
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() => _resent = true);
    StoreProvider.of<AppState>(context)
        .dispatch(RequestVerificationOtpAction(email: email));
  }

  /// A box changed. One digit moves on; several (a paste) fill the boxes
  /// from here; the last digit verifies.
  void _onChanged(int i, String value, _VerifyViewModel vm) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    final room = _controllers.length - i;
    if (digits.length == 2) {
      // Typed over the digit already there: keep the new one.
      digits = digits.substring(1);
    } else if (digits.length > room) {
      // A paste: the code is at its end.
      digits = digits.substring(digits.length - room);
    }
    if (digits.length > 1) {
      for (var j = 0; j < digits.length && i + j < _controllers.length; j++) {
        _controllers[i + j].text = digits[j];
      }
      final next = (i + digits.length).clamp(0, _controllers.length - 1);
      _focusNodes[next].requestFocus();
    } else if (digits.length == 1) {
      _controllers[i].text = digits;
      if (i < _controllers.length - 1) _focusNodes[i + 1].requestFocus();
    } else {
      _controllers[i].clear();
    }
    setState(() {});
    if (_code.length == VerifyCodeForm.length && !vm.isLoading) {
      _submit(vm.email);
    }
  }

  /// Backspace in an empty box goes back to the one before.
  KeyEventResult _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[i].text.isEmpty &&
        i > 0) {
      _controllers[i - 1].clear();
      _focusNodes[i - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _VerifyViewModel>(
      converter: _VerifyViewModel.fromStore,
      onWillChange: (previous, next) {
        // Activation succeeded, so hand the user over to sign in.
        if (previous?.isVerified == false && next.isVerified) {
          context.go(AppRoutes.login);
        }
      },
      builder: _card,
    );
  }

  Widget _card(BuildContext context, _VerifyViewModel vm) {
    final compact = widget.compact;
    final email = vm.email;

    return SignupCard(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SignupProgress(step: 3, of: 3, label: 'Verify your email'),
          const SizedBox(height: 20),
          // An envelope, with a ring round it.
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SignupColors.aqua.withValues(alpha: 0.16),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: signupGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SignupColors.teal.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 30, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SignupHeading(
            title: 'Check your email',
            subtitle: email == null
                ? 'There is no sign-up waiting to be verified in this window, '
                    'which happens after a refresh. Sign in, or start again '
                    'from step 1.'
                : 'Enter the ${VerifyCodeForm.length}-digit code we sent '
                    'to $email to activate your account.'
                    '${vm.isPharmacy ? ' It lasts 10 minutes.' : ''}',
            compact: compact,
            center: true,
          ),
          const SizedBox(height: 28),

          // The code, a box a digit.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < VerifyCodeForm.length; i++) ...[
                if (i > 0) SizedBox(width: compact ? 6 : 10),
                if (i == VerifyCodeForm.length ~/ 2)
                  // A gap halfway, so the code reads as two halves.
                  SizedBox(width: compact ? 4 : 10),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 58),
                    child: _CodeBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      autofocus: i == 0,
                      enabled: email != null,
                      onChanged: (v) => _onChanged(i, v, vm),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // The deployed API still runs in development mode, where it returns
          // the activation code in the response instead of only emailing it.
          // Surface it so the code is usable while no mailbox receives it.
          if (vm.devOtpCode != null) ...[
            SignupBanner(
              text: 'Development mode: your code is ${vm.devOtpCode}',
              warning: true,
            ),
            const SizedBox(height: 14),
          ],
          if (vm.errorMessage != null) ...[
            SignupBanner(text: vm.errorMessage!),
            const SizedBox(height: 14),
          ],

          SignupButton(
            label: email == null ? 'Go to sign in' : 'Verify',
            icon: email == null
                ? Icons.arrow_forward_rounded
                : Icons.verified_outlined,
            busy: vm.isLoading,
            onTap: () => _submit(email),
          ),
          const SizedBox(height: 16),
          if (email != null)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _resent ? 'A new code is on its way.' : 'No code?',
                  style:
                      const TextStyle(fontSize: 14, color: SignupColors.body),
                ),
                TextButton(
                  onPressed: vm.isLoading ? null : () => _resend(email),
                  style: TextButton.styleFrom(
                    foregroundColor: SignupColors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(_resent ? 'Send again' : 'Send it again',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One digit of the code.
class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1.4]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    final filled = controller.text.isNotEmpty;

    return AspectRatio(
      aspectRatio: 0.86,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // Room for a pasted code, which is spread across the boxes.
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autofillHints: const [AutofillHints.oneTimeCode],
        onChanged: onChanged,
        cursorColor: SignupColors.teal,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: SignupColors.ink,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: filled
              ? SignupColors.aqua.withValues(alpha: 0.12)
              : SignupColors.field,
          contentPadding: EdgeInsets.zero,
          enabledBorder:
              border(filled ? SignupColors.aqua : SignupColors.hairline),
          disabledBorder: border(SignupColors.hairline),
          focusedBorder: border(SignupColors.aqua, 2.2),
        ),
      ),
    );
  }
}

// Store bindings ------------------------------------------------------------

class _VerifyViewModel {
  const _VerifyViewModel({
    required this.isLoading,
    required this.isVerified,
    required this.isPharmacy,
    this.email,
    this.devOtpCode,
    this.errorMessage,
  });

  factory _VerifyViewModel.fromStore(Store<AppState> store) {
    final auth = store.state.authState;
    return _VerifyViewModel(
      isLoading: auth.isLoading,
      isVerified: auth.isEmailVerified,
      isPharmacy: auth.isPharmacySignup,
      email: auth.signupEmail,
      devOtpCode: auth.devOtpCode,
      errorMessage: auth.errorMessage,
    );
  }

  final bool isLoading;
  final bool isVerified;

  /// A pharmacy's code, which lasts 10 minutes.
  final bool isPharmacy;

  /// The address registration was started with. Null on a page refresh, since
  /// the store is rebuilt empty.
  final String? email;
  final String? devOtpCode;
  final String? errorMessage;
}
