import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/hide_on_scroll_header.dart';
import '../../../shared/widgets/public_navbar.dart';
import 'widgets/public_page_kit.dart';

/// Features — opened from the public navbar.
///
/// Says what PHolders does for each of the three people it serves, how a
/// prescription travels between them, and how the patient stays in control.
///
/// Every feature named here is one the platform has. Things still to come
/// (sick notes, pharmacy stock and reports) are left out, and there are no
/// figures, testimonials or sample patients, since none have been gathered.
class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

/// Who a set of features is for.
enum Audience {
  doctors('For Doctors'),
  pharmacies('For Pharmacies'),
  patients('For Patients');

  const Audience(this.label);
  final String label;
}

class _Feature {
  const _Feature(this.icon, this.title, this.body, {this.wide = false});
  final IconData icon;
  final String title;
  final String body;

  /// Two columns wide in the three-column grid, so each row is full.
  final bool wide;
}

const _features = <Audience, List<_Feature>>{
  Audience.doctors: [
    _Feature(
      Icons.medication_outlined,
      'Digital prescriptions',
      'Write a prescription for a consultation, with each medicine\'s '
          'dosage, form, route and duration, then sign it. The patient '
          'gets a QR code and a link; you can download, print or revoke it.',
      wide: true,
    ),
    _Feature(
      Icons.science_outlined,
      'Interaction checks',
      'Check the medicines for interactions and contraindications '
          'before you sign.',
    ),
    _Feature(
      Icons.event_available_outlined,
      'Appointments',
      'Accept bookings, see your day at a glance and mark each '
          'consultation complete.',
    ),
    _Feature(
      Icons.folder_shared_outlined,
      'Patient records, with consent',
      'When a patient books with you, they share their record: vitals, '
          'medication, history and documents.',
    ),
    _Feature(
      Icons.monitor_heart_outlined,
      'Vitals',
      'Record blood pressure, heart rate, glucose, weight and more. The '
          'patient sees them in their app.',
    ),
    _Feature(
      Icons.payments_outlined,
      'Payments',
      'See what patients have paid for their consultations.',
    ),
    _Feature(
      Icons.notifications_none_outlined,
      'Notifications',
      'Bookings to accept, cancellations, dispensed prescriptions and new '
          'reviews, in one inbox.',
    ),
    _Feature(
      Icons.star_outline_rounded,
      'Reviews',
      'See how patients rate their consultations with you.',
    ),
  ],
  Audience.pharmacies: [
    _Feature(
      Icons.playlist_add_check,
      'Dispensing queue',
      'Prescriptions patients send to your pharmacy arrive in one queue, '
          'ready to dispense.',
      wide: true,
    ),
    _Feature(
      Icons.qr_code_scanner,
      'Opened by QR, once',
      'A prescription opens from its QR code, and only once, so a '
          'forwarded copy cannot be used again.',
    ),
    _Feature(
      Icons.shopping_bag_outlined,
      'Orders',
      'Take each order from accepted to picked up, or decline it with a '
          'reason the patient can see.',
    ),
    _Feature(
      Icons.local_pharmacy_outlined,
      'Dispensed, on record',
      'Once you dispense, the prescribing doctor sees which pharmacy '
          'filled it, and when.',
      wide: true,
    ),
  ],
  Audience.patients: [
    _Feature(
      Icons.lock_outline,
      'Your record, your choice',
      'Booking is how you share your record with a doctor. No one else '
          'sees it, and your documents and vitals stay in one place.',
      wide: true,
    ),
    _Feature(
      Icons.calendar_month_outlined,
      'Book a doctor',
      'Find a doctor on PHolders and book a consultation from the app.',
    ),
    _Feature(
      Icons.receipt_long_outlined,
      'Prescriptions on your phone',
      'Your signed prescription arrives with its QR code. Send it to the '
          'pharmacy you choose.',
    ),
    _Feature(
      Icons.description_outlined,
      'Your documents',
      'Keep lab results and other files in your record, ready for your '
          'next consultation.',
    ),
    _Feature(
      Icons.favorite_border,
      'Your vitals',
      'Readings your doctor takes appear in your app, so you can follow '
          'them over time.',
    ),
  ],
};

class _FeaturesPageState extends State<FeaturesPage> {
  Audience _audience = Audience.doctors;
  final _journeyKey = GlobalKey();

  void _toJourney() {
    final ctx = _journeyKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppTheme.mobileBreakpoint;
    final gutter = isMobile ? 16.0 : 80.0;

    Widget section(Widget child) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1200 + gutter * 2),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: child,
            ),
          ),
        );
    final gap = SizedBox(height: isMobile ? 72 : 120);

    return Scaffold(
      backgroundColor: Colors.white,
      // The navbar slides away on the way down the page and back on the
      // way up.
      body: HideOnScrollHeader(
        top: 36,
        left: gutter,
        right: gutter,
        header: const PublicNavbar(
          actionLabel: 'Login',
          actionRoute: AppRoutes.login,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroBackdrop(
                child: section(Padding(
                  padding: EdgeInsets.only(
                      top: isMobile ? 130 : 170, bottom: isMobile ? 56 : 96),
                  child: _Hero(onSeeHow: _toJourney),
                )),
              ),
              section(Reveal(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(
                      eyebrow: 'Features',
                      title: 'Built for everyone a prescription touches',
                    ),
                    const SizedBox(height: 28),
                    _AudienceSwitch(
                      selected: _audience,
                      onSelected: (a) => setState(() => _audience = a),
                    ),
                    const SizedBox(height: 36),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(0, 0.03),
                                  end: Offset.zero)
                              .animate(a),
                          child: child,
                        ),
                      ),
                      child: _BentoGrid(
                        key: ValueKey(_audience),
                        features: _features[_audience]!,
                      ),
                    ),
                  ],
                ),
              )),
              gap,
              section(Reveal(child: _Journey(key: _journeyKey))),
              gap,
              const Reveal(child: _Privacy()),
              gap,
              section(const Reveal(child: PublicCallToAction())),
              const SizedBox(height: 48),
              section(const PublicFooter()),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.onSeeHow});
  final VoidCallback onSeeHow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final split = c.maxWidth >= 980;
      final small = c.maxWidth < 600;
      final align =
          split ? CrossAxisAlignment.start : CrossAxisAlignment.center;
      final textAlign = split ? TextAlign.start : TextAlign.center;
      final headline = TextStyle(
        fontSize: small ? 40 : 64,
        fontWeight: FontWeight.w700,
        letterSpacing: small ? -1 : -2,
        height: 1.05,
        color: PublicColors.ink,
      );

      final copy = Column(
        crossAxisAlignment: align,
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: PublicColors.hairline),
                boxShadow: [
                  BoxShadow(
                    color: PublicColors.teal.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: publicBrandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PHolders',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'For doctors, pharmacies and patients',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: PublicColors.body),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Reveal(
            delay: 0.1,
            child: Column(
              crossAxisAlignment: align,
              children: [
                Text('One platform,', textAlign: textAlign, style: headline),
                GradientText('from booking', align: textAlign, style: headline),
                Text('to pharmacy.', textAlign: textAlign, style: headline),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Reveal(
            delay: 0.2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'PHolders connects the doctor, the patient and the pharmacy, '
                'so a prescription is written, signed, sent and dispensed '
                'without paper changing hands.',
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: small ? 16 : 19,
                  height: 1.6,
                  color: PublicColors.body,
                ),
              ),
            ),
          ),
          const SizedBox(height: 34),
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
                PillButton(label: 'See how it works', onTap: onSeeHow),
              ],
            ),
          ),
        ],
      );

      if (!split) {
        return Column(children: [
          copy,
          if (!small) ...[
            const SizedBox(height: 56),
            const Reveal(delay: 0.3, child: _HeroArt()),
          ],
        ]);
      }
      return Row(
        children: [
          Expanded(flex: 11, child: copy),
          const SizedBox(width: 40),
          const Expanded(
              flex: 10, child: Reveal(delay: 0.25, child: _HeroArt())),
        ],
      );
    });
  }
}

/// An illustration of a signed prescription and its QR code. Shapes, not
/// data: the grey bars stand for text, so no patient or medicine is shown.
class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, {double h = 10, Color? c}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c ?? const Color(0xFFE8EFF0),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    Widget glass({required Widget child, EdgeInsets? padding}) => Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PublicColors.hairline),
            boxShadow: [
              BoxShadow(
                color: PublicColors.deep.withValues(alpha: 0.10),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        );

    final prescription = glass(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: publicBrandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prescription',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PublicColors.ink)),
                    const SizedBox(height: 6),
                    bar(110, h: 8),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F7EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: Color(0xFF2E9D57)),
                    SizedBox(width: 5),
                    Text('Signed',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E9D57))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < 3; i++) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: PublicColors.aqua, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar([170.0, 140.0, 190.0][i]),
                      const SizedBox(height: 6),
                      bar([110.0, 90.0, 120.0][i], h: 7),
                    ],
                  ),
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: 16),
          ],
          const SizedBox(height: 22),
          Container(height: 1, color: PublicColors.hairline),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.draw_outlined,
                  size: 18, color: PublicColors.teal),
              const SizedBox(width: 8),
              bar(90, h: 8, c: const Color(0xFFCDEBEE)),
              const Spacer(),
              bar(54, h: 8),
            ],
          ),
        ],
      ),
    );

    final qr = glass(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2_rounded,
              size: 76, color: PublicColors.ink),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: PublicColors.aqua.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Opens once',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PublicColors.teal)),
          ),
        ],
      ),
    );

    final check = glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: PublicColors.teal),
          SizedBox(width: 10),
          Text('Interaction check',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: PublicColors.ink)),
        ],
      ),
    );

    return SizedBox(
      height: 440,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // A tinted plate behind the cards.
          Positioned(
            left: 30,
            right: 0,
            top: 30,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PublicColors.aqua.withValues(alpha: 0.25),
                    PublicColors.teal.withValues(alpha: 0.10),
                  ],
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 70, top: 60, child: prescription),
          Positioned(right: 0, top: 0, child: qr),
          Positioned(left: 40, bottom: 0, child: check),
        ],
      ),
    );
  }
}

// ─── Features ─────────────────────────────────────────────────────────────────

/// Three audiences on a track; the dark pill slides to the one chosen.
class _AudienceSwitch extends StatelessWidget {
  const _AudienceSwitch({required this.selected, required this.onSelected});
  final Audience selected;
  final ValueChanged<Audience> onSelected;

  @override
  Widget build(BuildContext context) {
    const height = 50.0;
    final index = Audience.values.indexOf(selected);

    return LayoutBuilder(builder: (context, c) {
      // As wide as the design allows, narrower on a small phone.
      final itemWidth =
          ((c.maxWidth - 12) / Audience.values.length).clamp(0.0, 170.0);
      final small = itemWidth < 150;
      return Center(
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F6F7),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: PublicColors.hairline),
          ),
          child: SizedBox(
            width: itemWidth * Audience.values.length,
            height: height,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * index,
                  top: 0,
                  width: itemWidth,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: PublicColors.ink,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: PublicColors.ink.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final a in Audience.values)
                      SizedBox(
                        width: itemWidth,
                        height: height,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: () => onSelected(a),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontFamily,
                                fontSize: small ? 13 : 15,
                                fontWeight: FontWeight.w600,
                                color: a == selected
                                    ? Colors.white
                                    : PublicColors.body,
                              ),
                              child: Text(a.label),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// The audience's features as a bento grid: three columns where there is
/// room, the lead feature twice as wide and dark.
class _BentoGrid extends StatelessWidget {
  const _BentoGrid({super.key, required this.features});
  final List<_Feature> features;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth >= 980
          ? 3
          : c.maxWidth >= 640
              ? 2
              : 1;
      const gap = 20.0;
      final unit = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < features.length; i++)
            SizedBox(
              width: columns == 3 && features[i].wide ? unit * 2 + gap : unit,
              child: _FeatureCard(feature: features[i], lead: i == 0),
            ),
        ],
      );
    });
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature, required this.lead});
  final _Feature feature;

  /// The first card: dark, with the gradient glow.
  final bool lead;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    final lead = widget.lead;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        constraints: const BoxConstraints(minHeight: 230),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: lead ? PublicColors.deep : Colors.white,
          borderRadius: BorderRadius.circular(28),
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
                right: -80,
                top: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      PublicColors.aqua.withValues(alpha: 0.45),
                      PublicColors.aqua.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: lead ? publicBrandGradient : null,
                      color: lead
                          ? null
                          : PublicColors.aqua.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(f.icon,
                        size: 26,
                        color: lead ? Colors.white : PublicColors.teal),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    f.title,
                    style: TextStyle(
                      fontSize: lead ? 24 : 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: lead ? Colors.white : PublicColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      f.body,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color:
                            lead ? const Color(0xFFB7CDD0) : PublicColors.body,
                      ),
                    ),
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

// ─── How a prescription travels ───────────────────────────────────────────────

class _Journey extends StatelessWidget {
  const _Journey({super.key});

  static const _steps = [
    (
      Icons.calendar_month_outlined,
      'The patient books',
      'and, by booking, shares their record with the doctor.'
    ),
    (
      Icons.edit_note,
      'The doctor prescribes',
      'checks for interactions, and signs.'
    ),
    (
      Icons.qr_code_2,
      'The patient sends it',
      'to the pharmacy they choose, with its QR code.'
    ),
    (
      Icons.local_pharmacy_outlined,
      'The pharmacy dispenses',
      'and the doctor sees when, and where, it was filled.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionTitle(
          eyebrow: 'How it works',
          title: 'How a prescription travels',
        ),
        const SizedBox(height: 48),
        LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth >= 980
              ? 4
              : c.maxWidth >= 600
                  ? 2
                  : 1;
          const gap = 20.0;
          final w = (c.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < _steps.length; i++)
                SizedBox(
                  width: w,
                  child: _StepCard(
                    number: i + 1,
                    icon: _steps[i].$1,
                    title: _steps[i].$2,
                    body: _steps[i].$3,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3FAFB), Colors.white],
        ),
        border: Border.all(color: PublicColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientText(
                number.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: PublicColors.hairline),
                ),
                child: Icon(icon, size: 22, color: PublicColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: PublicColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
                fontSize: 15, height: 1.6, color: PublicColors.body),
          ),
        ],
      ),
    );
  }
}

// ─── Privacy ──────────────────────────────────────────────────────────────────

/// A dark band across the page, with frosted cards.
class _Privacy extends StatelessWidget {
  const _Privacy();

  static const _points = [
    (
      Icons.lock_outline,
      'Shared by booking, not by default',
      'A doctor sees a patient\'s record only once the patient has booked '
          'with them.'
    ),
    (
      Icons.draw_outlined,
      'Signed, and revocable',
      'Only a signed prescription can be dispensed, and the doctor can '
          'revoke one if it should not be.'
    ),
    (
      Icons.qr_code_2,
      'One code, one use',
      "A prescription's QR code opens it only once, so a forwarded "
          'copy cannot be reused.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppTheme.mobileBreakpoint;
    final gutter = isMobile ? 16.0 : 80.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2427), PublicColors.deep, Color(0xFF123C40)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    PublicColors.aqua.withValues(alpha: 0.18),
                    PublicColors.aqua.withValues(alpha: 0),
                  ]),
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1200 + gutter * 2),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: gutter, vertical: isMobile ? 64 : 104),
                child: Column(
                  children: [
                    const SectionTitle(
                      eyebrow: 'Privacy and safety',
                      title: 'The patient stays in control',
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
                          for (final (icon, title, body) in _points)
                            Container(
                              width: w,
                              constraints: const BoxConstraints(minHeight: 200),
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
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: PublicColors.aqua
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(icon,
                                        size: 24, color: PublicColors.aqua),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(title,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        color: Colors.white,
                                      )),
                                  const SizedBox(height: 8),
                                  Text(body,
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
