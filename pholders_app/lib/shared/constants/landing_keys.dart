import 'package:flutter/material.dart';

/// Global keys for the landing page sections.
///
/// Defined in shared/constants so both [LandingPage] and [PublicNavbar]
/// reference the exact same key instances — enabling scroll-to-section.
class LandingKeys {
  LandingKeys._();

  static final GlobalKey features = GlobalKey(debugLabel: 'section_features');
  static final GlobalKey about = GlobalKey(debugLabel: 'section_about');
  static final GlobalKey services = GlobalKey(debugLabel: 'section_services');
  static final GlobalKey howItWorks =
      GlobalKey(debugLabel: 'section_howItWorks');
  static final GlobalKey support = GlobalKey(debugLabel: 'section_support');
}
