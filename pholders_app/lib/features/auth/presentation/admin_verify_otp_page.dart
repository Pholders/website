import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_actions.dart';
import '../../../store/app_state.dart';
import '../../../core/routing/app_routes.dart';
import '../data/models/admin_login_session.dart';
import 'admin_login_page.dart' show AdminNotice;
import 'widgets/auth_widgets.dart';

/// Admin sign-in, step two of two.
///
/// Exchanges the emailed 6-digit code for a session. This is the only page in
/// the app that produces an admin token.
class AdminVerifyOtpPage extends StatefulWidget {
  const AdminVerifyOtpPage({super.key});

  @override
  State<AdminVerifyOtpPage> createState() => _AdminVerifyOtpPageState();
}

class _AdminVerifyOtpPageState extends State<AdminVerifyOtpPage> {
  /// Matches the ten minutes the server stamps on the OTP row.
  static const _codeLifetime = Duration(minutes: 10);

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _ticker;
  Duration _remaining = _codeLifetime;

  bool get _hasExpired => _remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });

    // The email lives in memory only, so a browser refresh on this page loses
    // it. Send the admin back rather than posting a null address.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AdminLoginSession().email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your sign-in timed out. Please start again.'),
          ),
        );
        context.go(AppRoutes.adminLogin);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  String get _countdownLabel {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _submit(BuildContext context) {
    final email = AdminLoginSession().email;
    if (email == null) {
      context.go(AppRoutes.adminLogin);
      return;
    }

    if (_code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter all six digits.')),
      );
      return;
    }

    StoreProvider.of<AppState>(context).dispatch(
      AdminVerifyOtpAction(email: email, otpCode: _code),
    );
  }

  /// There is no resend endpoint for admin — a fresh code is only issued by
  /// logging in again, which re-checks the password.
  void _startOver(BuildContext context) {
    AdminLoginSession().clear();
    context.go(AppRoutes.adminLogin);
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final email = AdminLoginSession().email;

    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      distinct: true,
      onDidChange: (prevState, state) {
        if (prevState?.authState.isAuthenticated ==
            state.authState.isAuthenticated) {
          return;
        }
        if (state.authState.isAuthenticated) {
          AdminLoginSession().clear();
          context.go(AppRoutes.adminDashboard);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF309CA3).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF309CA3),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Check your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      email == null
                          ? 'Enter the 6-digit code we sent you.'
                          : 'Enter the 6-digit code sent to $email.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (state.authState.errorMessage != null) ...[
                      AdminNotice(
                        message: state.authState.errorMessage!,
                        isError: true,
                      ),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < 6; i++)
                          SizedBox(
                            width: 52,
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              enabled: !_hasExpired,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF309CA3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (v) => _onDigitChanged(i, v),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _hasExpired
                          ? 'That code has expired.'
                          : 'Code expires in $_countdownLabel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasExpired
                            ? Colors.redAccent
                            : Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AuthSubmitButton(
                      label: 'Verify and sign in',
                      isLoading: state.authState.isLoading,
                      onPressed: _hasExpired
                          ? () => _startOver(context)
                          : () => _submit(context),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => _startOver(context),
                        child: const Text(
                          'Start again with a new code',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF003BFC),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      // Failed codes count toward the same five-per-hour limit
                      // as failed passwords, so this is a real warning.
                      'Repeated incorrect codes will temporarily lock this '
                      'email out of signing in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
