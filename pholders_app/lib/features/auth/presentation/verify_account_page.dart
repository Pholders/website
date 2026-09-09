import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';
import 'package:redux/redux.dart';

import '../../../app/app_state.dart';
import '../../../core/auth/auth_actions.dart';
import '../../../core/routing/app_routes.dart';
import 'widgets/auth_widgets.dart';

/// OTP verification screen.
///
/// Matches Figma frame "Verify your account".
class VerifyAccountPage extends StatefulWidget {
  const VerifyAccountPage({super.key});

  @override
  State<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends State<VerifyAccountPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  /// The six boxes joined into one code.
  String get _code => _controllers.map((c) => c.text.trim()).join();

  void _submit(String? email) {
    if (email == null) {
      // Nothing to verify against, so send the user to sign in instead.
      context.go(AppRoutes.login);
      return;
    }
    if (_code.length != 6) return;
    StoreProvider.of<AppState>(context)
        .dispatch(VerifyEmailRequestAction(email: email, otpCode: _code));
  }

  void _resend(String? email) {
    if (email == null) return;
    for (final c in _controllers) {
      c.clear();
    }
    StoreProvider.of<AppState>(context)
        .dispatch(RequestVerificationOtpAction(email: email));
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
      builder: _buildPage,
    );
  }

  Widget _buildPage(BuildContext context, _VerifyViewModel vm) {
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6DD0D8).withValues(alpha: 0.15),
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
                    const Text(
                      'Enter the verification code sent to your email to activate your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                    const SizedBox(height: 16),

                    // The deployed API still runs in development mode, where
                    // it returns the activation code in the response instead
                    // of only emailing it. Surface it so the code is usable
                    // while no mailbox receives it.
                    if (vm.devOtpCode != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFD9A0)),
                        ),
                        child: Text(
                          'Development mode: your code is ${vm.devOtpCode}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A5300),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (vm.errorMessage != null) ...[
                      Text(
                        vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB3261E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Resend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            vm.email == null
                                ? 'No pending registration'
                                : 'Sent to ${vm.email}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: vm.isLoading ? null : () => _resend(vm.email),
                          child: const Text(
                            "Didn't receive it? Send Again",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF309CA3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    AuthSubmitButton(
                      label: 'Verify',
                      isLoading: vm.isLoading,
                      onPressed: () => _submit(vm.email),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Store bindings ------------------------------------------------------------

class _VerifyViewModel {
  const _VerifyViewModel({
    required this.isLoading,
    required this.isVerified,
    this.email,
    this.devOtpCode,
    this.errorMessage,
  });

  factory _VerifyViewModel.fromStore(Store<AppState> store) {
    final auth = store.state.authState;
    return _VerifyViewModel(
      isLoading: auth.isLoading,
      isVerified: auth.isEmailVerified,
      email: auth.signupEmail,
      devOtpCode: auth.devOtpCode,
      errorMessage: auth.errorMessage,
    );
  }

  final bool isLoading;
  final bool isVerified;

  /// The address registration was started with. Null on a page refresh, since
  /// the store is rebuilt empty.
  final String? email;
  final String? devOtpCode;
  final String? errorMessage;
}
