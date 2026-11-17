import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import 'widgets/public_page_kit.dart';

/// How it works — opened from the public navbar.
///
/// One prescription followed from booking to collection, step by step, then
/// each person's part in it. In the Features page's look
/// ([PublicPageFrame] and its kit).
///
/// Each step is what the platform does today, in the order it does it.
class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicPageFrame(
      children: [
        HeroBackdrop(child: PublicContentWidth(child: _Hero())),
        PublicContentWidth(child: Reveal(child: _Walkthrough())),
        PublicGap(),
        Reveal(child: _Roles()),
        PublicGap(),
        PublicContentWidth(child: Reveal(child: PublicCallToAction())),
        SizedBox(height: 48),
        PublicContentWidth(child: PublicFooter()),
        SizedBox(height: 32),
      ],
    );
  }
}

// ─── The journey ──────────────────────────────────────────────────────────────

class _Step {
  const _Step({
    required this.icon,
    required this.who,
    required this.title,
    required this.body,
    required this.points,
  });

  final IconData icon;

  /// Whose step it is: Patient, Doctor or Pharmacy.
  final String who;
  final String title;
  final String body;
  final List<String> points;
}

const _journey = [
  _Step(
    icon: Icons.calendar_month_outlined,
    who: 'Patient',
    title: 'Books a consultation',
    body: 'The patient finds a doctor in the PHolders app and books a time.',
    points: [
      'Booking shares the patient\'s record with that doctor',
      'No other doctor sees it',
    ],
  ),
  _Step(
    icon: Icons.event_available_outlined,
    who: 'Doctor',
    title: 'Accepts the booking',
    body: 'The booking reaches the doctor\'s notifications and schedule, '
        'waiting to be accepted.',
    points: [
      'The day\'s appointments in one place',
      'Cancellations and moves arrive as notifications',
    ],
  ),
  _Step(
    icon: Icons.monitor_heart_outlined,
    who: 'Doctor',
    title: 'Sees the patient',
    body: 'At the consultation the doctor has the patient\'s record to hand, '
        'and records what they measure.',
    points: [
      'Vitals, current medication, history and documents',
      'New vitals appear in the patient\'s app',
      'The consultation is marked complete',
    ],
  ),
  _Step(
    icon: Icons.edit_note,
    who: 'Doctor',
    title: 'Writes the prescription',
    body: 'A prescription for the consultation, with each medicine set out '
        'in full, checked before it goes anywhere.',
    points: [
      'Dosage, form, route and duration for each medicine',
      'An interaction and contraindication check',
    ],
  ),
  _Step(
    icon: Icons.draw_outlined,
    who: 'Doctor',
    title: 'Signs it',
    body: 'Signing makes the prescription valid and dispensable. The patient '
        'receives it with a QR code and a link.',
    points: [
      'A signed prescription cannot be edited',
      'If it should not stand, the doctor revokes it',
      'It can be downloaded or printed as a PDF',
    ],
  ),
  _Step(
    icon: Icons.send_outlined,
    who: 'Patient',
    title: 'Sends it to a pharmacy',
    body: 'The patient chooses a pharmacy, and the prescription arrives in '
        'that pharmacy\'s queue.',
    points: [
      'Any pharmacy on PHolders the patient chooses',
      'The QR code opens the prescription only once',
    ],
  ),
  _Step(
    icon: Icons.local_pharmacy_outlined,
    who: 'Pharmacy',
    title: 'Dispenses, and the patient collects',
    body: 'The pharmacy prepares the order and dispenses it, and the patient '
        'collects it when it is ready.',
    points: [
      'The order moves from accepted to ready to picked up',
      'Or it is declined, with a reason the patient sees',
      'The doctor sees which pharmacy dispensed it, and when',
    ],
  ),
];

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final small = c.maxWidth < 600;
      final split = c.maxWidth >= 980;
      final align =
          split ? CrossAxisAlignment.start : CrossAxisAlignment.center;
      final textAlign = split ? TextAlign.start : TextAlign.center;
      final headline = TextStyle(
        fontSize: small ? 42 : 76,
        fontWeight: FontWeight.w800,
        letterSpacing: small ? -1.2 : -3,
        height: 1.0,
        color: PublicColors.ink,
      );

      final copy = Column(
        crossAxisAlignment: align,
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: PublicColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      gradient: publicBrandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.route_rounded,
                        size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('How it works',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PublicColors.body)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            delay: 0.1,
            child: Column(
              crossAxisAlignment: align,
              children: [
                Text('From booking', textAlign: textAlign, style: headline),
                GradientText('to pharmacy,', align: textAlign, style: headline),
                Text('in seven steps.', textAlign: textAlign, style: headline),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            delay: 0.2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                'Follow one prescription through PHolders: who does what, '
                'what each of them sees, and what keeps it safe on the way.',
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: small ? 16 : 19,
                  height: 1.65,
                  color: PublicColors.body,
                ),
              ),
            ),
          ),
        ],
      );

      return Padding(
        padding:
            EdgeInsets.only(top: small ? 130 : 180, bottom: small ? 56 : 88),
        child: split
            ? Row(
                children: [
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 48),
                  const Expanded(
                    flex: 9,
                    child: Reveal(delay: 0.25, child: _Cascade()),
                  ),
                ],
              )
            : Column(children: [
                copy,
                const SizedBox(height: 44),
                const Reveal(delay: 0.3, child: _Track()),
              ]),
      );
    });
  }
}

/// The seven steps as a cascade of cards, each a little further across,
/// joined by the gradient line.
class _Cascade extends StatelessWidget {
  const _Cascade();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const rowHeight = 64.0;
      final shift = (c.maxWidth - 260) / (_journey.length - 1);
      return SizedBox(
        height: rowHeight * _journey.length,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CascadeLine(
                    count: _journey.length, rowHeight: rowHeight, shift: shift),
              ),
            ),
            for (var i = 0; i < _journey.length; i++)
              Positioned(
                left: shift * i,
                top: rowHeight * i + 6,
                child: _CascadeCard(
                  number: i + 1,
                  step: _journey[i],
                  lit: i == _journey.length - 1,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _CascadeCard extends StatelessWidget {
  const _CascadeCard(
      {required this.number, required this.step, required this.lit});
  final int number;
  final _Step step;

  /// The last step, in the dark.
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      decoration: BoxDecoration(
        color: lit ? PublicColors.deep : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: lit ? null : Border.all(color: PublicColors.hairline),
        boxShadow: [
          BoxShadow(
            color: PublicColors.deep.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: publicBrandGradient,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(step.icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$number · ${step.who}',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: lit ? PublicColors.aqua : PublicColors.teal,
                    )),
                Text(step.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: lit ? Colors.white : PublicColors.ink,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The line the cascade's cards sit on, from each icon to the next.
class _CascadeLine extends CustomPainter {
  const _CascadeLine(
      {required this.count, required this.rowHeight, required this.shift});
  final int count;
  final double rowHeight;
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    Offset point(int i) => Offset(shift * i + 26, rowHeight * i + 32);
    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < count; i++) {
      final a = point(i - 1), b = point(i);
      path.cubicTo(
          a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = const LinearGradient(
          colors: [Color(0xFF309CA3), Color(0xFF8FE0E6)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _CascadeLine old) =>
      old.count != count || old.rowHeight != rowHeight || old.shift != shift;
}

/// The three people as stops on one line: the journey at a glance.
class _Track extends StatelessWidget {
  const _Track();

  @override
  Widget build(BuildContext context) {
    const stops = [
      (Icons.person_outline_rounded, 'Patient'),
      (Icons.medical_services_outlined, 'Doctor'),
      (Icons.person_outline_rounded, 'Patient'),
      (Icons.local_pharmacy_outlined, 'Pharmacy'),
    ];
    final small = MediaQuery.sizeOf(context).width < 600;
    final size = small ? 44.0 : 60.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // The line, behind the stops.
          Positioned(
            top: size / 2 - 1.5,
            left: size / 2,
            right: size / 2,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: publicBrandGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (icon, label) in stops)
                Column(
                  children: [
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: PublicColors.aqua.withValues(alpha: 0.7),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: PublicColors.teal.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(icon,
                          size: size * 0.45, color: PublicColors.teal),
                    ),
                    const SizedBox(height: 10),
                    Text(label,
                        style: TextStyle(
                          fontSize: small ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: PublicColors.ink,
                        )),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Walkthrough ──────────────────────────────────────────────────────────────

/// The seven steps: a list to choose from, and the chosen one in full.
class _Walkthrough extends StatefulWidget {
  const _Walkthrough();

  @override
  State<_Walkthrough> createState() => _WalkthroughState();
}

class _WalkthroughState extends State<_Walkthrough> {
  int _at = 0;

  void _go(int i) => setState(() => _at = i.clamp(0, _journey.length - 1));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(
          eyebrow: 'Step by step',
          title: 'One prescription, start to finish',
        ),
        const SizedBox(height: 48),
        LayoutBuilder(builder: (context, c) {
          final split = c.maxWidth >= 900;
          final list = Column(
            children: [
              for (var i = 0; i < _journey.length; i++)
                _StepTab(
                  number: i + 1,
                  step: _journey[i],
                  selected: i == _at,
                  done: i < _at,
                  last: i == _journey.length - 1,
                  onTap: () => _go(i),
                ),
            ],
          );
          final detail = _StepDetail(
            number: _at + 1,
            step: _journey[_at],
            onBack: _at == 0 ? null : () => _go(_at - 1),
            onNext: _at == _journey.length - 1 ? null : () => _go(_at + 1),
          );
          if (!split) {
            // On a narrow screen the chosen step sits above the list.
            return Column(children: [detail, const SizedBox(height: 24), list]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: list),
              const SizedBox(width: 40),
              Expanded(flex: 7, child: detail),
            ],
          );
        }),
      ],
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({
    required this.number,
    required this.step,
    required this.selected,
    required this.done,
    required this.last,
    required this.onTap,
  });

  final int number;
  final _Step step;
  final bool selected;

  /// Before the chosen step: its line is filled.
  final bool done;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The progress line, with this step's dot.
          SizedBox(
            width: 40,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(top: 14),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: selected || done ? publicBrandGradient : null,
                    color: selected || done ? null : Colors.white,
                    shape: BoxShape.circle,
                    border: selected || done
                        ? null
                        : Border.all(color: PublicColors.hairline, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : Text('$number',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : PublicColors.body,
                          )),
                ),
                if (!last)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 2,
                      color: done ? PublicColors.aqua : PublicColors.hairline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFF3FAFB) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? PublicColors.aqua.withValues(alpha: 0.6)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.who.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: PublicColors.teal,
                                )),
                            const SizedBox(height: 3),
                            Text(step.title,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: selected
                                      ? PublicColors.ink
                                      : PublicColors.body,
                                )),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: selected ? 1 : 0,
                        child: const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: PublicColors.teal),
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

/// The chosen step in full, on the dark panel.
class _StepDetail extends StatelessWidget {
  const _StepDetail({
    required this.number,
    required this.step,
    required this.onBack,
    required this.onNext,
  });

  final int number;
  final _Step step;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
    return Container(
      constraints: const BoxConstraints(minHeight: 460),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2427), PublicColors.deep, Color(0xFF14464A)],
        ),
        boxShadow: [
          BoxShadow(
            color: PublicColors.deep.withValues(alpha: 0.25),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -110,
            top: -110,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    PublicColors.aqua.withValues(alpha: 0.35),
                    PublicColors.aqua.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          // The step number, large and faint, behind the words.
          Positioned(
            right: 28,
            bottom: -30,
            child: Text(
              number.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: small ? 120 : 190,
                fontWeight: FontWeight.w900,
                letterSpacing: -8,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(small ? 26 : 40),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position:
                      Tween(begin: const Offset(0.03, 0), end: Offset.zero)
                          .animate(a),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, if (current != null) current],
              ),
              child: Column(
                key: ValueKey(number),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: publicBrandGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(step.icon, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14)),
                        ),
                        child: Text(
                          'Step $number of ${_journey.length} · ${step.who}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBE3E6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // How far along the journey this step is.
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: number / _journey.length,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: publicBrandGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: small ? 28 : 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    step.body,
                    style: const TextStyle(
                        fontSize: 17, height: 1.6, color: Color(0xFFB7CDD0)),
                  ),
                  const SizedBox(height: 26),
                  for (final p in step.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: PublicColors.aqua.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 14, color: PublicColors.aqua),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(p,
                                style: const TextStyle(
                                    fontSize: 15.5,
                                    height: 1.5,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  _StepScreen(index: number - 1),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Previous step',
                        onTap: onBack,
                      ),
                      const SizedBox(width: 10),
                      _RoundButton(
                        icon: Icons.arrow_forward_rounded,
                        tooltip: 'Next step',
                        onTap: onNext,
                        filled: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? Colors.white : Colors.transparent,
              border: filled
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon,
                size: 20, color: filled ? PublicColors.ink : Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─── Each person's part ───────────────────────────────────────────────────────

enum _Role {
  doctor('Doctors', Icons.medical_services_outlined),
  pharmacy('Pharmacies', Icons.local_pharmacy_outlined),
  patient('Patients', Icons.person_outline_rounded);

  const _Role(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _parts = <_Role, List<(String, String)>>{
  _Role.doctor: [
    (
      'Sign up and verify',
      'Create your account, add your practice '
          'details, and confirm it with a one-time code.'
    ),
    (
      'Run your day',
      'Accept bookings, see your schedule and your '
          'patients\' records.'
    ),
    (
      'Prescribe safely',
      'Write, check and sign prescriptions; revoke one '
          'that should not stand.'
    ),
    (
      'Follow up',
      'See where each prescription was dispensed, and what '
          'patients have paid.'
    ),
  ],
  _Role.pharmacy: [
    (
      'Sign up and verify',
      'Create your pharmacy\'s account and confirm it '
          'with a one-time code.'
    ),
    (
      'Receive prescriptions',
      'Prescriptions patients send you arrive in '
          'your dispensing queue.'
    ),
    ('Open by QR', 'Each prescription opens from its QR code, once.'),
    (
      'Fill the order',
      'Take it from accepted to picked up, or decline it '
          'with a reason.'
    ),
  ],
  _Role.patient: [
    ('Get the app', 'Patients use the PHolders app, not this website.'),
    (
      'Book a doctor',
      'Booking shares your record with that doctor, and no '
          'one else.'
    ),
    ('Receive your prescription', 'It arrives signed, with its QR code.'),
    (
      'Choose a pharmacy',
      'Send it where you like, and collect it when it '
          'is ready.'
    ),
  ],
};

/// A dark band: choose a role to see its four steps.
class _Roles extends StatefulWidget {
  const _Roles();

  @override
  State<_Roles> createState() => _RolesState();
}

class _RolesState extends State<_Roles> {
  _Role _role = _Role.doctor;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
    final parts = _parts[_role]!;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2427), PublicColors.deep, Color(0xFF123C40)],
        ),
      ),
      child: PublicContentWidth(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: small ? 64 : 104),
          child: Column(
            children: [
              const SectionTitle(
                eyebrow: 'Your part in it',
                title: 'What it looks like for you',
                light: true,
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final r in _Role.values)
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => setState(() => _role = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: r == _role
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: r == _role ? 1 : 0.14)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(r.icon,
                                size: 18,
                                color: r == _role
                                    ? PublicColors.teal
                                    : const Color(0xFFCBE3E6)),
                            const SizedBox(width: 8),
                            Text(r.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: r == _role
                                      ? PublicColors.ink
                                      : const Color(0xFFCBE3E6),
                                )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: LayoutBuilder(
                  key: ValueKey(_role),
                  builder: (context, c) {
                    final columns = c.maxWidth >= 980
                        ? 4
                        : c.maxWidth >= 600
                            ? 2
                            : 1;
                    const gap = 18.0;
                    final w = (c.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var i = 0; i < parts.length; i++)
                          Container(
                            width: w,
                            constraints: const BoxConstraints(minHeight: 200),
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GradientText(
                                  '${i + 1}'.padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.4,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(parts[i].$1,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: Colors.white,
                                    )),
                                const SizedBox(height: 8),
                                Text(parts[i].$2,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.6,
                                      color: Color(0xFFA9C2C5),
                                    )),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),
              TextButton(
                onPressed: () => context.go(AppRoutes.services),
                style: TextButton.styleFrom(foregroundColor: PublicColors.aqua),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See our services',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step screens ─────────────────────────────────────────────────────────────

/// A small drawn app screen for each step: shapes and button words, not
/// data. The grey bars stand for text, so no patient or medicine is shown.
class _StepScreen extends StatelessWidget {
  const _StepScreen({required this.index});

  /// Which step, from 0.
  final int index;

  static Widget bar(double w, {double h = 8, Color? c}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c ?? const Color(0xFFE6EDEE),
          borderRadius: BorderRadius.circular(5),
        ),
      );

  static Widget chip(String text, {bool on = true, IconData? icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: on ? publicBrandGradient : null,
          color: on ? null : const Color(0xFFF0F5F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 12, color: on ? Colors.white : PublicColors.body),
              const SizedBox(width: 4),
            ],
            Text(text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : PublicColors.body,
                )),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final body = switch (index) {
      0 => _book(),
      1 => _accept(),
      2 => _vitals(),
      3 => _write(),
      4 => _sign(),
      5 => _send(),
      _ => _dispense(),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A window bar.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: PublicColors.hairline)),
              ),
              child: Row(
                children: [
                  for (final c in const [
                    Color(0xFFFF6B6B),
                    Color(0xFFF5C451),
                    Color(0xFF5DD39E),
                  ]) ...[
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  bar(70, h: 7),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(18), child: body),
          ],
        ),
      ),
    );
  }

  /// A month of days, one chosen, and a Book button.
  Widget _book() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(110, h: 10, c: const Color(0xFFD5E9EB)),
          const SizedBox(height: 14),
          for (var r = 0; r < 3; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++)
                    Expanded(
                      child: Container(
                        height: 26,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient:
                              r == 1 && d == 3 ? publicBrandGradient : null,
                          color:
                              r == 1 && d == 3 ? null : const Color(0xFFF2F6F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(children: [bar(90), const Spacer(), chip('Book')]),
        ],
      );

  /// Bookings in a list, the first waiting to be accepted.
  Widget _accept() => Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < 2 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F4F5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar([110.0, 90.0, 120.0][i]),
                        const SizedBox(height: 5),
                        bar([70.0, 60.0, 80.0][i], h: 6),
                      ],
                    ),
                  ),
                  i == 0
                      ? chip('Accept', icon: Icons.check_rounded)
                      : chip('Accepted', on: false),
                ],
              ),
            ),
        ],
      );

  /// Four measurement tiles.
  Widget _vitals() {
    const icons = [
      Icons.favorite_border_rounded,
      Icons.monitor_heart_outlined,
      Icons.scale_outlined,
      Icons.device_thermostat_rounded,
    ];
    Widget tile(IconData icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: PublicColors.teal),
                const SizedBox(height: 10),
                bar(54, h: 12, c: const Color(0xFFD5E9EB)),
                const SizedBox(height: 6),
                bar(36, h: 6),
              ],
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [
          tile(icons[0]),
          const SizedBox(width: 10),
          tile(icons[1])
        ]),
        const SizedBox(height: 10),
        Row(children: [
          tile(icons[2]),
          const SizedBox(width: 10),
          tile(icons[3])
        ]),
      ],
    );
  }

  /// Medicines in rows, and the check before signing.
  Widget _write() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: PublicColors.aqua, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  bar([130.0, 100.0, 150.0][i]),
                  const Spacer(),
                  bar(40, h: 7),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(children: [
            chip('Check interactions', icon: Icons.shield_outlined),
            const Spacer(),
            bar(50, h: 7),
          ]),
        ],
      );

  /// A signature over its line, and the Signed mark.
  Widget _sign() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(120),
          const SizedBox(height: 6),
          bar(90, h: 6),
          const SizedBox(height: 14),
          const SizedBox(
            height: 50,
            width: double.infinity,
            child: CustomPaint(painter: _SignaturePainter()),
          ),
          Container(height: 1.2, color: PublicColors.hairline),
          const SizedBox(height: 12),
          Row(children: [
            chip('Signed', icon: Icons.check_circle_rounded),
            const SizedBox(width: 8),
            chip('QR code', on: false, icon: Icons.qr_code_2_rounded),
          ]),
        ],
      );

  /// The QR code beside a choice of pharmacies.
  Widget _send() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.qr_code_2_rounded,
                size: 76, color: PublicColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? PublicColors.aqua.withValues(alpha: 0.14)
                          : const Color(0xFFF7FAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: i == 0
                              ? PublicColors.aqua
                              : PublicColors.hairline),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_pharmacy_outlined,
                            size: 15, color: PublicColors.teal),
                        const SizedBox(width: 8),
                        Expanded(child: bar([80.0, 70.0, 90.0][i], h: 7)),
                        if (i == 0)
                          const Icon(Icons.check_circle_rounded,
                              size: 15, color: PublicColors.teal),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );

  /// The order's stages, the last reached.
  Widget _dispense() {
    const stages = ['Accepted', 'Ready', 'Picked up'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.local_pharmacy_outlined,
              size: 18, color: PublicColors.teal),
          const SizedBox(width: 8),
          bar(120),
        ]),
        const SizedBox(height: 18),
        // Wraps on a narrow screen rather than overflow.
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              if (i > 0)
                const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: PublicColors.aqua),
              chip(stages[i], icon: Icons.check_rounded),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Row(children: [
          const Icon(Icons.medical_services_outlined,
              size: 15, color: PublicColors.body),
          const SizedBox(width: 6),
          bar(150, h: 7),
        ]),
      ],
    );
  }
}

/// A signature's loops.
class _SignaturePainter extends CustomPainter {
  const _SignaturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final path = Path()
      ..moveTo(6, h * 0.7)
      ..cubicTo(30, h * 0.05, 48, h * 0.05, 40, h * 0.8)
      ..cubicTo(36, h * 1.0, 70, h * 0.2, 86, h * 0.55)
      ..cubicTo(96, h * 0.8, 110, h * 0.3, 128, h * 0.5)
      ..cubicTo(146, h * 0.7, 160, h * 0.2, 190, h * 0.45);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = PublicColors.deep,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
