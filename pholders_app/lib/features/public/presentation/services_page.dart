import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import 'widgets/public_page_kit.dart';

/// Services — opened from the public navbar.
///
/// The four services PHolders runs, each with what it includes, how to get
/// started, and the questions people ask. In the Features page's look
/// ([PublicPageFrame] and its kit).
///
/// Only what the platform does is offered. The settings' "linked services"
/// (medical aids, calendars, payments, messaging) only switch on screen and
/// connect to nothing yet, so they are not listed; nor are prices, which
/// have not been given.
class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPageFrame(
      children: [
        const HeroBackdrop(child: PublicContentWidth(child: _Hero())),
        const PublicContentWidth(
          child: Reveal(
            child: SectionTitle(
              eyebrow: 'What we run',
              title: 'Four services, one connected platform',
            ),
          ),
        ),
        const SizedBox(height: 56),
        for (var i = 0; i < _services.length; i++) ...[
          PublicContentWidth(
            child: Reveal(
              child: _ServiceRow(service: _services[i], flip: i.isOdd),
            ),
          ),
          SizedBox(height: i == _services.length - 1 ? 0 : 72),
        ],
        const PublicGap(),
        const Reveal(child: _GetStarted()),
        const PublicGap(),
        const PublicContentWidth(child: Reveal(child: _Faq())),
        const PublicGap(),
        const PublicContentWidth(child: Reveal(child: PublicCallToAction())),
        const SizedBox(height: 48),
        const PublicContentWidth(child: PublicFooter()),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── The services ─────────────────────────────────────────────────────────────

class _Service {
  const _Service({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.points,
    required this.tags,
    this.dark = false,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final List<String> points;

  /// Short labels floated on the picture.
  final List<String> tags;

  /// Draws its picture on the dark panel.
  final bool dark;
}

const _services = [
  _Service(
    icon: Icons.medication_outlined,
    eyebrow: 'For doctors',
    title: 'Digital prescribing',
    body: 'Write a prescription for a consultation, check it, sign it, and '
        'it reaches the patient as a QR code and a link.',
    points: [
      'Each medicine with its dosage, form, route and duration',
      'An interaction and contraindication check before signing',
      'Download or print the prescription as a PDF',
      'Revoke a signed prescription that should not stand',
    ],
    tags: ['Signed', 'QR code', 'Revocable'],
    dark: true,
  ),
  _Service(
    icon: Icons.folder_shared_outlined,
    eyebrow: 'For doctors and patients',
    title: 'Consented health records',
    body: 'A patient shares their record with a doctor by booking with them. '
        'The doctor sees it; no one else does.',
    points: [
      'Vitals, current medication, visit history and documents',
      'Vitals recorded at the consultation, seen by the patient',
      'Only what is on the record: nothing estimated or filled in',
    ],
    tags: ['Vitals', 'History', 'Documents'],
  ),
  _Service(
    icon: Icons.event_available_outlined,
    eyebrow: 'For doctors and patients',
    title: 'Appointments and consultations',
    body: 'Patients book from the PHolders app; doctors run their day from '
        'one schedule.',
    points: [
      'Accept bookings and see the day at a glance',
      'Mark each consultation complete',
      'See what patients have paid',
      'Notifications for bookings, changes and reviews',
    ],
    tags: ['Bookings', 'Payments', 'Reviews'],
    dark: true,
  ),
  _Service(
    icon: Icons.local_pharmacy_outlined,
    eyebrow: 'For pharmacies',
    title: 'Pharmacy dispensing',
    body: 'Prescriptions patients send to a pharmacy arrive ready to '
        'dispense, and can be trusted when they do.',
    points: [
      'One queue for the prescriptions patients send you',
      'Each prescription opens from its QR code only once',
      'Orders taken from accepted to picked up, or declined with a reason',
      'The prescribing doctor sees where, and when, it was dispensed',
    ],
    tags: ['Queue', 'Opens once', 'Orders'],
  ),
];

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
                    child: const Icon(Icons.bolt_rounded,
                        size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Services',
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
                Text('Services that', textAlign: textAlign, style: headline),
                Text('keep care', textAlign: textAlign, style: headline),
                GradientText('moving.', align: textAlign, style: headline),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Reveal(
            delay: 0.2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                'Prescribing, health records, consultations and dispensing, '
                'run as one service, so nothing is retyped and nothing is '
                'lost between the people who need it.',
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
                    child: Reveal(delay: 0.25, child: _FannedCards()),
                  ),
                ],
              )
            : Column(children: [
                copy,
                if (!small) ...[
                  const SizedBox(height: 56),
                  const Reveal(delay: 0.3, child: _FannedCards()),
                ],
              ]),
      );
    });
  }
}

/// The four services as a fanned hand of cards.
class _FannedCards extends StatelessWidget {
  const _FannedCards();

  @override
  Widget build(BuildContext context) {
    const angles = [-0.16, -0.05, 0.06, 0.17];
    const shifts = [-120.0, -40.0, 40.0, 120.0];
    return SizedBox(
      height: 440,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                PublicColors.aqua.withValues(alpha: 0.3),
                PublicColors.aqua.withValues(alpha: 0),
              ]),
            ),
          ),
          for (var i = 0; i < _services.length; i++)
            Transform.translate(
              offset: Offset(shifts[i], i.isEven ? 14 : -6),
              child: Transform.rotate(
                angle: angles[i],
                child: _MiniCard(service: _services[i], lit: i == 3),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.service, required this.lit});
  final _Service service;

  /// The top card, in the dark.
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lit ? PublicColors.deep : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: lit ? null : Border.all(color: PublicColors.hairline),
        boxShadow: [
          BoxShadow(
            color: PublicColors.deep.withValues(alpha: 0.14),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: publicBrandGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(service.icon, color: Colors.white, size: 24),
          ),
          const Spacer(),
          Text(
            service.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: lit ? Colors.white : PublicColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          // Bars stand for text.
          for (final w in const [120.0, 90.0])
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: w,
              height: 7,
              decoration: BoxDecoration(
                color: lit
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFE8EFF0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── A service ────────────────────────────────────────────────────────────────

/// A service in two halves, picture and words, the sides alternating down
/// the page.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service, required this.flip});
  final _Service service;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final s = service;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.eyebrow.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: PublicColors.teal,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          s.title,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.1,
            color: PublicColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          s.body,
          style: const TextStyle(
              fontSize: 17, height: 1.6, color: PublicColors.body),
        ),
        const SizedBox(height: 24),
        for (final p in s.points)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    gradient: publicBrandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p,
                      style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.5,
                          color: PublicColors.ink)),
                ),
              ],
            ),
          ),
      ],
    );
    final picture = _ServicePicture(service: s);

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 900) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [picture, const SizedBox(height: 32), words],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: flip
            ? [
                Expanded(child: words),
                const SizedBox(width: 64),
                Expanded(child: picture),
              ]
            : [
                Expanded(child: picture),
                const SizedBox(width: 64),
                Expanded(child: words),
              ],
      );
    });
  }
}

/// The service's picture: a large icon on a panel, its tags floating round
/// it.
class _ServicePicture extends StatelessWidget {
  const _ServicePicture({required this.service});
  final _Service service;

  @override
  Widget build(BuildContext context) {
    final dark = service.dark;
    final small = MediaQuery.sizeOf(context).width < AppTheme.mobileBreakpoint;
    final height = small ? 300.0 : 400.0;

    Widget tag(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.18)
                    : PublicColors.hairline),
            boxShadow: dark
                ? null
                : [
                    BoxShadow(
                      color: PublicColors.deep.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: PublicColors.aqua, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(text,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : PublicColors.ink)),
            ],
          ),
        );

    // Where the tags float, as fractions of the panel.
    const spots = [
      Alignment(-0.78, -0.72),
      Alignment(0.8, -0.2),
      Alignment(-0.55, 0.78),
    ];

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B2427),
                  PublicColors.deep,
                  Color(0xFF14464A)
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PublicColors.aqua.withValues(alpha: 0.22),
                  const Color(0xFFF4FAFB),
                ],
              ),
        border: dark ? null : Border.all(color: PublicColors.hairline),
      ),
      child: Stack(
        children: [
          // Rings round the icon.
          for (final r in const [150.0, 230.0, 310.0])
            Center(
              child: Container(
                width: r,
                height: r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (dark ? Colors.white : PublicColors.teal)
                        .withValues(alpha: dark ? 0.08 : 0.12),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          Center(
            child: Transform.rotate(
              angle: -math.pi / 40,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: publicBrandGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: PublicColors.teal.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Icon(service.icon, size: 54, color: Colors.white),
              ),
            ),
          ),
          for (var i = 0; i < service.tags.length && i < spots.length; i++)
            Align(alignment: spots[i], child: tag(service.tags[i])),
        ],
      ),
    );
  }
}

// ─── Getting started ──────────────────────────────────────────────────────────

/// Signing up, in three steps, on a dark band.
class _GetStarted extends StatelessWidget {
  const _GetStarted();

  static const _steps = [
    (
      Icons.person_add_alt_1_outlined,
      'Create your account',
      'Sign up as a doctor or as a pharmacy.'
    ),
    (
      Icons.badge_outlined,
      'Add your details',
      "Your professional and practice details, or your pharmacy's, so "
          'others know who they are dealing with.'
    ),
    (
      Icons.mark_email_read_outlined,
      'Verify, and begin',
      'Confirm your account with the one-time code we send you, then sign '
          'in.'
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
                eyebrow: 'Getting started',
                title: 'Up and running in three steps',
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
                    for (var i = 0; i < _steps.length; i++)
                      Container(
                        width: w,
                        constraints: const BoxConstraints(minHeight: 230),
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
                            Row(
                              children: [
                                GradientText(
                                  '${i + 1}'.padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.5,
                                    height: 1,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: PublicColors.aqua
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(_steps[i].$1,
                                      size: 23, color: PublicColors.aqua),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            Text(_steps[i].$2,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 8),
                            Text(_steps[i].$3,
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
              const SizedBox(height: 40),
              PillButton(
                label: 'Sign up now',
                onTap: () => context.go(AppRoutes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Questions ────────────────────────────────────────────────────────────────

class _Faq extends StatelessWidget {
  const _Faq();

  static const _items = [
    (
      'Do patients sign up on this website?',
      'No. Doctors and pharmacies sign up here. Patients use the PHolders '
          'app, where they book, keep their record and receive their '
          'prescriptions.'
    ),
    (
      'Who can see a patient\'s record?',
      'A doctor the patient has booked with. Booking is how the patient '
          'shares it; no one else sees it.'
    ),
    (
      'Can a signed prescription be changed?',
      'No. Signing fixes it. If it should not stand, the doctor revokes it, '
          'so it can no longer be dispensed, and writes a new one.'
    ),
    (
      'How does a pharmacy know a prescription is genuine?',
      'It opens from the prescription\'s QR code, and each code opens only '
          'once, so a forwarded copy cannot be used again.'
    ),
    (
      'Does the doctor know when a prescription is dispensed?',
      'Yes. The doctor sees which pharmacy dispensed it, and when.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final split = c.maxWidth >= 900;
      final title = Column(
        crossAxisAlignment:
            split ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const Text(
            'QUESTIONS',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: PublicColors.teal,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'What people ask',
            textAlign: split ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              fontSize: split ? 44 : 30,
              fontWeight: FontWeight.w800,
              letterSpacing: split ? -1.4 : -0.6,
              height: 1.1,
              color: PublicColors.ink,
            ),
          ),
        ],
      );
      final list = Column(
        children: [
          for (final (q, a) in _items) _FaqItem(question: q, answer: a),
        ],
      );
      return split
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: title),
                const SizedBox(width: 48),
                Expanded(flex: 7, child: list),
              ],
            )
          : Column(children: [title, const SizedBox(height: 32), list]);
    });
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _open ? const Color(0xFFF3FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _open
              ? PublicColors.aqua.withValues(alpha: 0.6)
              : PublicColors.hairline,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: PublicColors.ink,
                        )),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _open ? 0.125 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: _open ? publicBrandGradient : null,
                        color: _open ? null : const Color(0xFFF1F6F7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded,
                          size: 20,
                          color: _open ? Colors.white : PublicColors.ink),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12, right: 40),
                        child: Text(widget.answer,
                            style: const TextStyle(
                                fontSize: 15.5,
                                height: 1.6,
                                color: PublicColors.body)),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
