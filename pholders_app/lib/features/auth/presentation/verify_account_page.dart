import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/routing/app_routes.dart';
import '../../../features/auth/data/models/signup_session.dart';
import 'widgets/auth_widgets.dart';

/// Pharmacy OTP verification screen.
///
/// Matches Figma frame "Verify your account".
///
/// Only pharmacies land here. Doctor signup activates the account immediately
/// and sends no code, so doctors go straight from signup to login.
///
/// There is deliberately no resend button. Resending issues a code with the
/// 'email_verification' purpose, which this endpoint (purpose 'signup') will
/// not accept; the endpoint that does accept it never flips `status` to
/// 'active', leaving the account permanently unable to log in. Until that is
/// fixed server-side, an expired code cannot be recovered from the client.
class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({super.key});

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  static const _codeLifetime = Duration(minutes: 10);

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  Timer? _ticker;
  Duration _remaining = _codeLifetime;

  bool get _hasExpired => _remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    final session = SignupSession();
    final email = session.email;

    // The session is in-memory only, so a refresh on this page loses the
    // address the code was sent to.
    if (email == null) {
      _showMessage('We lost track of your signup. Please register again.');
      context.go(AppRoutes.register);
      return;
    }

    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      _showMessage('Please enter the complete verification code.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Must be /verify-otp with `otp_code`. /verify-email checks a different
      // OTP purpose and would leave the account unable to log in.
      await sl<ApiClient>().dio.post(
        '/users/pharmacy/verify-otp',
        data: {'email': email, 'otp_code': otp},
      );

      if (!mounted) return;
      // Verification returns no token — the user still has to log in.
      session.clear();
      _showMessage('Account verified. Please log in.');
      context.go(AppRoutes.login);
    } catch (e) {
      _showMessage(
        apiErrorMessage(e, fallback: 'Verification failed. Please try again.'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _countdownLabel {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: size.width * 0.18,
            top: size.height * 0.32,
            child: Container(
              width: size.width * 0.64,
              height: size.height * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6DD0D8).withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF6DD0D8).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: Color(0xFF309CA3),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verify Your Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        SignupSession().email == null
                            ? 'Enter the verification code sent to your email to activate your account.'
                            : 'Enter the code sent to ${SignupSession().email} to activate your account.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          return Container(
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextFormField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              enabled: !_hasExpired,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF309CA3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty && i < 5) {
                                  _focusNodes[i + 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      if (_hasExpired)
                        _ExpiredNotice(
                          onStartOver: () {
                            SignupSession().clear();
                            context.go(AppRoutes.register);
                          },
                        )
                      else
                        Text(
                          'This code expires in $_countdownLabel',
                          style: TextStyle(
                            fontSize: 13,
                            color: _remaining.inMinutes < 2
                                ? Colors.orange.shade800
                                : Colors.black45,
                            fontWeight: _remaining.inMinutes < 2
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      const SizedBox(height: 32),

                      if (!_hasExpired)
                        AuthSubmitButton(
                          label: 'Verify',
                          isLoading: _isLoading,
                          onPressed: _isLoading ? () {} : _verify,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown once the code has expired.
///
/// Deliberately offers no resend: see the note on [VerifyAccountPage].
class _ExpiredNotice extends StatelessWidget {
  const _ExpiredNotice({required this.onStartOver});

  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'This code has expired.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please register again using a different email address, or contact '
            'support to have this one activated.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onStartOver,
            child: const Text('Start over'),
          ),
        ],
      ),
    );
  }
}
