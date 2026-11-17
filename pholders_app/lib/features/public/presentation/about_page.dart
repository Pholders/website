import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import 'widgets/public_page_kit.dart';

/// About — opened from the public navbar.
///
/// Why PHolders exists, what changes with it, what it holds to, and who it
/// is for. In the Features page's look ([PublicPageFrame] and its kit).
///
/// Only what is true of the platform is said. There are no founders,
/// dates, places, figures or quotes, since none have been given to say.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicPageFrame(
      children: [
        HeroBackdrop(child: PublicContentWidth(child: _Hero())),
        PublicContentWidth(child: Reveal(child: _Mission())),
        PublicGap(),
        PublicContentWidth(child: Reveal(child: _BeforeAfter())),
        PublicGap(),
        PublicContentWidth(child: Reveal(child: _Principles())),
        PublicGap(),
        Reveal(child: _WhoFor()),
        PublicGap(),
        PublicContentWidth(child: Reveal(child: PublicCallToAction())),
        SizedBox(height: 48),
        PublicContentWidth(child: PublicFooter()),
        SizedBox(height: 32),
      ],
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final split = c.maxWidth >= 980;
      final small = c.maxWidth < 600;
      final align =
          split ? CrossAxisAlignment.start : CrossAxisAlignment.center;
      final textAlign = split ? TextAlign.start : TextAlign.center;
      final headline = TextStyle(
        fontSize: small ? 42 : 72,
        fontWeight: FontWeight.w800,
        letterSpacing: small ? -1.2 : -2.8,
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
                    child: const Icon(Icons.favorite_rounded,
                        size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('About PHolders',
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
                Text('Prescriptions,', textAlign: textAlign, style: headline),
                GradientText('without the', align: textAlign, style: headline),
                GradientText('paper trail.', align: textAlign, style: headline),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            delay: 0.2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                'PHolders brings the doctor, the patient and the pharmacy '
                'together around one secure, digital prescription, and '
                'around a health record the patient decides who sees.',
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: small ? 16 : 19,
                  height: 1.65,
                  color: PublicColors.body,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Reveal(
            delay: 0.3,
            child: Wrap(
              alignment: split ? WrapAlignment.start : WrapAlignment.center,
              spacing: 14,
              runSpacing: 12,
              children: [
                PillButton(
                  label: 'Get started',
                  dark: true,
                  onTap: () => context.go(AppRoutes.register),
                ),
                PillButton(
                  label: 'Explore features',
                  onTap: () => context.go(AppRoutes.features),
                ),
              ],
            ),
          ),
        ],
      );

      return Padding(
        padding:
            EdgeInsets.only(top: small ? 130 : 180, bottom: small ? 64 : 110),
        child: split
            ? Row(
                children: [
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 40),
                  const Expanded(
                    flex: 10,
                    child: Reveal(delay: 0.25, child: _ConnectionArt()),
                  ),
                ],
              )
            : Column(children: [
                copy,
                if (!small) ...[
                  const SizedBox(height: 56),
                  const Reveal(delay: 0.3, child: _ConnectionArt()),
                ],
              ]),
      );
    });
  }
}

/// PHolders at the centre, joined to the three people it serves: the
/// platform as a picture. Shapes and labels only, no data.
class _ConnectionArt extends StatelessWidget {
  const _ConnectionArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 460,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        const h = 460.0;
        final centre = Offset(w * 0.52, h * 0.5);
        // Where each card sits, and the point its line meets.
        final doctor = Offset(w * 0.26, h * 0.14);
        final pharmacy = Offset(w * 0.74, h * 0.34);
        final patient = Offset(w * 0.3, h * 0.86);

        Widget at(Offset p, Widget child) => Positioned(
              left: p.dx,
              top: p.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: child,
              ),
            );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // A soft disc behind it all.
            Positioned(
              left: centre.dx - 190,
              top: centre.dy - 190,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    PublicColors.aqua.withValues(alpha: 0.28),
                    PublicColors.aqua.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _LinksPainter(
                    centre: centre, ends: [doctor, pharmacy, patient]),
              ),
            ),
            at(
              centre,
              Container(
                width: 132,
                height: 132,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: PublicColors.aqua.withValues(alpha: 0.5),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: PublicColors.teal.withValues(alpha: 0.25),
                      blurRadius: 50,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Image.asset('assets/PHolders-icon.png',
                    fit: BoxFit.contain),
              ),
            ),
            at(
                doctor,
                const _NodeCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Doctor',
                    line: 'Prescribes and signs')),
            at(
                pharmacy,
                const _NodeCard(
                    icon: Icons.local_pharmacy_outlined,
                    title: 'Pharmacy',
                    line: 'Opens and dispenses')),
            at(
                patient,
                const _NodeCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Patient',
                    line: 'Books and shares')),
          ],
        );
      }),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard(
      {required this.icon, required this.title, required this.line});
  final IconData icon;
  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PublicColors.hairline),
        boxShadow: [
          BoxShadow(
            color: PublicColors.deep.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: publicBrandGradient,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PublicColors.ink)),
              const SizedBox(height: 2),
              Text(line,
                  style: const TextStyle(
                      fontSize: 12.5, color: PublicColors.body)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dashed gradient lines from the centre out to each card.
class _LinksPainter extends CustomPainter {
  const _LinksPainter({required this.centre, required this.ends});
  final Offset centre;
  final List<Offset> ends;

  @override
  void paint(Canvas canvas, Size size) {
    for (final end in ends) {
      final paint = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF309CA3), Color(0xFF8FE0E6)],
        ).createShader(Rect.fromPoints(centre, end));
      final delta = end - centre;
      final length = delta.distance;
      final dir = delta / length;
      const dash = 7.0, gap = 7.0;
      for (var d = 0.0; d < length; d += dash + gap) {
        final from = centre + dir * d;
        final to = centre + dir * (d + dash).clamp(0, length);
        canvas.drawLine(from, to, paint);
      }
      // A dot where the line meets the card.
      canvas.drawCircle(end, 4,
          Paint()..color = const Color(0xFF309CA3).withValues(alpha: 0.6));
    }
  }

  @override
  bool shouldRepaint(covariant _LinksPainter old) =>
      old.centre != centre || old.ends != ends;
}

// ─── Mission ──────────────────────────────────────────────────────────────────

/// The purpose in one oversized sentence, its key phrases in the gradient.
class _Mission extends StatelessWidget {
  const _Mission();

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
    final size = small ? 28.0 : 50.0;
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: small ? -0.6 : -1.6,
      height: 1.25,
      color: PublicColors.ink,
    );

    return LayoutBuilder(builder: (context, c) {
      // One gradient across the block, so each highlighted phrase takes the
      // colour of where it sits.
      final shader = publicBrandGradient
          .createShader(Rect.fromLTWH(0, 0, c.maxWidth, size * 6));
      // A style with a paint cannot also have a colour, so it is built
      // afresh rather than copied from [base].
      final lit = TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: small ? -0.6 : -1.6,
        height: 1.25,
        foreground: Paint()..shader = shader,
      );
      final faint = base.copyWith(color: const Color(0xFFB4C1C3));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OUR MISSION',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: PublicColors.teal,
            ),
          ),
          const SizedBox(height: 22),
          RichText(
            text: TextSpan(style: base, children: [
              const TextSpan(text: 'Every prescription should be '),
              TextSpan(text: 'signed', style: lit),
              const TextSpan(text: ', '),
              TextSpan(text: 'checked', style: lit),
              const TextSpan(text: ' and '),
              TextSpan(text: 'trusted', style: lit),
              const TextSpan(
                  text: ' from the doctor\'s desk to the '
                      'pharmacy counter, '),
              TextSpan(
                  text: 'with the patient in control of their record.',
                  style: faint),
            ]),
          ),
        ],
      );
    });
  }
}

// ─── Why ──────────────────────────────────────────────────────────────────────

/// The same moments, on paper and on PHolders, side by side.
class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter();

  static const _paper = [
    'A paper script can be lost, copied or altered, and a pharmacy has no '
        'easy way to tell.',
    'The patient retells their history at every new consultation.',
    'The doctor seldom learns whether, or where, a script was filled.',
    'Checking medicines against each other is left to memory.',
  ];

  static const _pholders = [
    'A signed digital prescription, opened by a QR code that works only '
        'once.',
    'Booking shares the patient\'s record with that doctor: vitals, '
        'medication, history and documents.',
    'The doctor sees which pharmacy dispensed it, and when.',
    'An interaction and contraindication check before signing.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(
          eyebrow: 'Why we built it',
          title: 'A prescription should be as safe as the care behind it',
        ),
        const SizedBox(height: 48),
        LayoutBuilder(builder: (context, c) {
          final side = c.maxWidth >= 860;
          const paper = _Column(
            title: 'On paper',
            icon: Icons.description_outlined,
            points: _paper,
            good: false,
          );
          const digital = _Column(
            title: 'With PHolders',
            icon: Icons.verified_outlined,
            points: _pholders,
            good: true,
          );
          return side
              ? const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: paper),
                      SizedBox(width: 20),
                      Expanded(child: digital),
                    ],
                  ),
                )
              : const Column(
                  children: [paper, SizedBox(height: 20), digital],
                );
        }),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.icon,
    required this.points,
    required this.good,
  });

  final String title;
  final IconData icon;
  final List<String> points;

  /// The PHolders side: dark, with ticks. Paper is pale, with crosses.
  final bool good;

  @override
  Widget build(BuildContext context) {
    final fg = good ? Colors.white : PublicColors.ink;
    final muted = good ? const Color(0xFFB7CDD0) : PublicColors.body;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: good ? PublicColors.deep : const Color(0xFFF5F8F8),
        borderRadius: BorderRadius.circular(28),
        border: good ? null : Border.all(color: PublicColors.hairline),
      ),
      child: Stack(
        children: [
          if (good)
            Positioned(
              right: -90,
              top: -90,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      PublicColors.aqua.withValues(alpha: 0.4),
                      PublicColors.aqua.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: good ? publicBrandGradient : null,
                        color: good ? null : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: good
                            ? null
                            : Border.all(color: PublicColors.hairline),
                      ),
                      child: Icon(icon,
                          size: 24,
                          color: good ? Colors.white : PublicColors.body),
                    ),
                    const SizedBox(width: 14),
                    Text(title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: fg,
                        )),
                  ],
                ),
                const SizedBox(height: 26),
                for (final p in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: good
                                ? PublicColors.aqua.withValues(alpha: 0.2)
                                : const Color(0xFFE9EEEF),
                          ),
                          child: Icon(
                            good ? Icons.check_rounded : Icons.close_rounded,
                            size: 14,
                            color: good ? PublicColors.aqua : PublicColors.body,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p,
                              style: TextStyle(
                                  fontSize: 15.5, height: 1.55, color: muted)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Principles ───────────────────────────────────────────────────────────────

class _Principles extends StatelessWidget {
  const _Principles();

  static const _items = [
    (
      Icons.lock_person_outlined,
      'The patient decides',
      'A record is the patient\'s. A doctor sees it because the patient '
          'booked with them, not by default.'
    ),
    (
      Icons.fact_check_outlined,
      'Only what is recorded',
      'Every screen shows what the record holds. Nothing is estimated, '
          'padded or filled in to look complete.'
    ),
    (
      Icons.health_and_safety_outlined,
      'Safety before speed',
      'Medicines are checked before signing, and a signed prescription can '
          'still be revoked if it should not stand.'
    ),
    (
      Icons.touch_app_outlined,
      'Simple to use',
      'One place for the day\'s work, so care gets the attention, not the '
          'software.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(
          eyebrow: 'What we hold to',
          title: 'Principles behind every screen',
        ),
        const SizedBox(height: 48),
        LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth >= 980
              ? 3
              : c.maxWidth >= 600
                  ? 2
                  : 1;
          const gap = 20.0;
          final w = (c.maxWidth - gap * (columns - 1)) / columns;
          // Three across, the first and last twice as wide, so both rows
          // are full.
          bool wide(int i) =>
              columns == 3 && (i == 0 || i == _items.length - 1);
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < _items.length; i++)
                SizedBox(
                  width: wide(i) ? w * 2 + gap : w,
                  child: _PrincipleCard(
                    lead: i == 0,
                    number: i + 1,
                    icon: _items[i].$1,
                    title: _items[i].$2,
                    body: _items[i].$3,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _PrincipleCard extends StatefulWidget {
  const _PrincipleCard({
    required this.lead,
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  /// The first card: dark, with a glow.
  final bool lead;
  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  State<_PrincipleCard> createState() => _PrincipleCardState();
}

class _PrincipleCardState extends State<_PrincipleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        constraints: const BoxConstraints(minHeight: 250),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: lead ? PublicColors.deep : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: lead
                ? Colors.transparent
                : _hover
                    ? PublicColors.aqua.withValues(alpha: 0.7)
                    : PublicColors.hairline,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (lead ? PublicColors.deep : PublicColors.teal)
                  .withValues(alpha: _hover ? 0.18 : 0.06),
              blurRadius: _hover ? 36 : 20,
              offset: Offset(0, _hover ? 18 : 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (lead)
              Positioned(
                right: -90,
                bottom: -110,
                child: IgnorePointer(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        PublicColors.aqua.withValues(alpha: 0.4),
                        PublicColors.aqua.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: lead ? publicBrandGradient : null,
                          color: lead
                              ? null
                              : PublicColors.aqua.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(widget.icon,
                            size: 27,
                            color: lead ? Colors.white : PublicColors.teal),
                      ),
                      const Spacer(),
                      GradientText(
                        widget.number.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(widget.title,
                      style: TextStyle(
                        fontSize: lead ? 26 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: lead ? Colors.white : PublicColors.ink,
                      )),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(widget.body,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.6,
                          color: lead
                              ? const Color(0xFFB7CDD0)
                              : PublicColors.body,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Who it is for ────────────────────────────────────────────────────────────

/// A dark band: the three people PHolders serves, each with what it gives
/// them, leading to the Features page.
class _WhoFor extends StatelessWidget {
  const _WhoFor();

  static const _people = [
    (
      Icons.medical_services_outlined,
      'Doctors',
      'Appointments, consented patient records, and prescriptions written, '
          'checked and signed in one place.'
    ),
    (
      Icons.local_pharmacy_outlined,
      'Pharmacies',
      'Prescriptions that arrive ready to dispense, and can be trusted when '
          'they do.'
    ),
    (
      Icons.person_outline_rounded,
      'Patients',
      'Their record, prescriptions, documents and vitals in the PHolders '
          'app, shared on their terms.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
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
                eyebrow: 'Who it is for',
                title: 'Three people, one prescription',
                light: true,
              ),
              const SizedBox(height: 48),
              LayoutBuilder(builder: (context, c) {
                final columns = c.maxWidth >= 900 ? 3 : 1;
                const gap = 20.0;
                final w = (c.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (icon, who, what) in _people)
                      Container(
                        width: w,
                        constraints: const BoxConstraints(minHeight: 210),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: publicBrandGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(icon, size: 26, color: Colors.white),
                            ),
                            const SizedBox(height: 22),
                            Text(who,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 8),
                            Text(what,
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
              }),
              const SizedBox(height: 36),
              TextButton(
                onPressed: () => context.go(AppRoutes.features),
                style: TextButton.styleFrom(foregroundColor: PublicColors.aqua),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See every feature',
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
