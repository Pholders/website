import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/hide_on_scroll_header.dart';
import '../../../../shared/widgets/public_navbar.dart';
import '../../../public/presentation/widgets/public_page_kit.dart';

/// The pieces the sign-up steps are built from, so step 1, step 2 and
/// verifying the account share one look: the white card, the step progress,
/// section labels, fields and dropdowns with floating labels, the gradient
/// button, and a message banner.

abstract final class SignupColors {
  static const teal = Color(0xFF309CA3);
  static const aqua = Color(0xFF6DD0D8);
  static const ink = Color(0xFF0F1A1B);
  static const body = Color(0xFF55636A);
  static const hairline = Color(0xFFE3ECED);
  static const field = Color(0xFFF6F9FA);
  static const danger = Color(0xFFD64545);
  static const deep = Color(0xFF0E2B2E);
}

const signupGradient = LinearGradient(
  colors: [Color(0xFF1F8A92), Color(0xFF4CC3CC)],
);

/// A white card with a soft shadow: what each step sits on.
class SignupCard extends StatelessWidget {
  const SignupCard({super.key, required this.child, this.compact = false});
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          compact ? 20 : 30, compact ? 22 : 26, compact ? 20 : 30, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(compact ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: SignupColors.deep.withValues(alpha: 0.18),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// "Step 1 of 2 · Your details" over a bar in as many parts as there are
/// steps, the ones reached filled.
class SignupProgress extends StatelessWidget {
  const SignupProgress({
    super.key,
    required this.step,
    required this.of,
    required this.label,
  });

  final int step;
  final int of;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'Step $step of $of',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SignupColors.teal,
                  fontSize: 13),
            ),
            TextSpan(
              text: '  ·  $label',
              style: const TextStyle(color: SignupColors.body, fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 1; i <= of; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: i <= step ? signupGradient : null,
                    color: i <= step ? null : const Color(0xFFE6EEEF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A step's heading and the line under it.
class SignupHeading extends StatelessWidget {
  const SignupHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.compact = false,
    this.center = false,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
            color: SignupColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
              fontSize: 14.5, height: 1.5, color: SignupColors.body),
        ),
      ],
    );
  }
}

class SignupSectionLabel extends StatelessWidget {
  const SignupSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: SignupColors.body,
      ),
    );
  }
}

InputDecoration _decoration({
  required String label,
  required IconData icon,
  String? error,
  Widget? suffix,
  bool enabled = true,
}) {
  OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    errorText: error,
    labelStyle: const TextStyle(fontSize: 14, color: SignupColors.body),
    floatingLabelStyle: const TextStyle(
        fontSize: 14, color: SignupColors.teal, fontWeight: FontWeight.w600),
    prefixIcon: Icon(icon, size: 19, color: SignupColors.body),
    suffixIcon: suffix,
    filled: true,
    fillColor: enabled ? SignupColors.field : const Color(0xFFF0F3F4),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(vertical: 16),
    enabledBorder: border(SignupColors.hairline),
    disabledBorder: border(SignupColors.hairline),
    focusedBorder: border(SignupColors.aqua, 2),
    errorBorder: border(SignupColors.danger),
    focusedErrorBorder: border(SignupColors.danger, 2),
    errorStyle: const TextStyle(fontSize: 12, color: SignupColors.danger),
  );
}

/// A field with its label floating above once filled, a leading icon, an
/// aqua ring when focused, and, for passwords, an eye to show it.
class SignupField extends StatelessWidget {
  const SignupField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.error,
    this.trailingOk = false,
    this.autofillHints,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;

  /// Shows the eye toggle when set.
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// What is wrong, under the field.
  final String? error;

  /// A tick at the end, such as when a confirmation matches.
  final bool trailingOk;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    Widget? suffix;
    if (onToggleObscure != null || trailingOk) {
      suffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingOk)
            const Icon(Icons.check_circle_rounded,
                size: 18, color: Color(0xFF2E9D57)),
          if (onToggleObscure != null)
            IconButton(
              tooltip: obscure ? 'Show password' : 'Hide password',
              onPressed: onToggleObscure,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: SignupColors.body,
              ),
            ),
          const SizedBox(width: 4),
        ],
      );
    }

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      cursorColor: SignupColors.teal,
      style: const TextStyle(fontSize: 14.5, color: SignupColors.ink),
      decoration:
          _decoration(label: label, icon: icon, error: error, suffix: suffix),
    );
  }
}

/// A choice from a list, in the same dress as [SignupField]. Disabled, with
/// [disabledLabel], while [items] is empty.
class SignupDropdown extends StatelessWidget {
  const SignupDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.disabledLabel,
    this.error,
  });

  final String label;
  final IconData icon;

  /// The current choice, or '' for none.
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String? disabledLabel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final enabled = items.isNotEmpty;
    // A value not among the items would assert, as it does for a moment after
    // the province changes and clears the city.
    final selected = items.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label:${items.length}:$selected'),
      initialValue: selected,
      isExpanded: true,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: SignupColors.body),
      style: const TextStyle(fontSize: 14.5, color: SignupColors.ink),
      decoration: _decoration(
        label: enabled ? label : (disabledLabel ?? label),
        icon: icon,
        error: error,
        enabled: enabled,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled
          ? (v) {
              if (v != null) onChanged(v);
            }
          : null,
    );
  }
}

/// The full-width gradient button that moves a step on; a spinner while
/// [busy], when it does nothing.
class SignupButton extends StatefulWidget {
  const SignupButton({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;
  final IconData icon;

  @override
  State<SignupButton> createState() => _SignupButtonState();
}

class _SignupButtonState extends State<SignupButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !widget.busy,
      label: widget.label,
      child: MouseRegion(
        cursor:
            widget.busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.busy ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 54,
            decoration: BoxDecoration(
              gradient: signupGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: SignupColors.teal
                      .withValues(alpha: _hover && !widget.busy ? 0.45 : 0.3),
                  blurRadius: _hover ? 26 : 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: widget.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 180),
                          offset: Offset(_hover ? 0.25 : 0, 0),
                          child:
                              Icon(widget.icon, size: 20, color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A square outlined button beside [SignupButton]: back a step.
class SignupBackButton extends StatelessWidget {
  const SignupBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SignupColors.hairline, width: 1.5),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              size: 20, color: SignupColors.ink),
        ),
      ),
    );
  }
}

/// A coloured note across the card: a problem, or something to know.
class SignupBanner extends StatelessWidget {
  const SignupBanner({super.key, required this.text, this.warning = false});
  final String text;

  /// Amber, for a notice rather than a problem.
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final (bg, edge, fg, icon) = warning
        ? (
            const Color(0xFFFFF6E8),
            const Color(0xFFFFD9A0),
            const Color(0xFF8A5300),
            Icons.info_outline_rounded
          )
        : (
            const Color(0xFFFDEEEE),
            const Color(0xFFF5C2C2),
            const Color(0xFF9B2C2C),
            Icons.error_outline_rounded
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: edge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: fg)),
          ),
        ],
      ),
    );
  }
}

/// A sign-up page after step 1: the navbar, which hides on the way down, over
/// the public pages' backdrop, and the step's card in the middle.
class SignupPageFrame extends StatelessWidget {
  const SignupPageFrame({super.key, required this.child, this.maxWidth = 620});

  /// The step's card.
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
    final gutter = small ? 16.0 : 80.0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: HideOnScrollHeader(
        top: 36,
        left: gutter,
        right: gutter,
        header: const PublicNavbar(
          actionLabel: 'Login',
          actionRoute: AppRoutes.login,
        ),
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
            child: HeroBackdrop(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      small ? 16 : 24, small ? 120 : 160, small ? 16 : 24, 64),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Reveal(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
