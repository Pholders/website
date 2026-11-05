import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "A Smarter Way to Manage Patients" headline with the quoted subtitle, as it
/// sits at the top of the Landing and Login pages on desktop.
///
/// Designed on the 1440-wide Figma frame, where it is [designHeight] tall;
/// [scale] resizes it with the page.
class PublicHeroHeader extends StatelessWidget {
  const PublicHeroHeader({super.key, this.scale = 1});

  final double scale;

  /// Height of the block at scale 1, for pages that lay out around it.
  static const double designHeight = 250;

  @override
  Widget build(BuildContext context) {
    final s = scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 64 * s,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.15,
            ),
            children: const [
              TextSpan(text: 'A '),
              TextSpan(
                text: 'Smarter',
                style: TextStyle(color: AppTheme.landingTeal),
              ),
              TextSpan(text: ' Way to Manage\nPatients'),
            ],
          ),
        ),
        SizedBox(height: 8 * s),

        // Quote mark sits above the subtitle's left edge.
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: Offset(-15 * s, 0),
                child: Image.asset(
                  'assets/inverted-commas-icon.png',
                  width: 30 * s,
                  height: 24 * s,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 12 * s),
              Text(
                'Access patient records, create secure digital prescriptions,\nand monitor health updates all in one platform.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21 * s,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF333333),
                  letterSpacing: 0.3,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
