import 'package:flutter/material.dart';

import '../data/dashboard_summary.dart';

/// A patient's [PatientStatus] as a tinted label with a dot: the Status cell
/// of the dashboard's and the Patients page's tables.
class PatientStatusPill extends StatelessWidget {
  const PatientStatusPill(this.status, {super.key});

  final PatientStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      PatientStatus.awaitingAcceptance => (
          'Awaiting acceptance',
          const Color(0xFFFF5A5F),
          Colors.white,
        ),
      PatientStatus.visitToday => (
          'Visit today',
          const Color(0xFFFFE99A),
          const Color(0xFFF5A623),
        ),
      PatientStatus.upcomingVisit => (
          'Upcoming visit',
          const Color(0xFFE0F4F5),
          const Color(0xFF2E9FA5),
        ),
      PatientStatus.seen => (
          'Seen',
          const Color(0xFFF0F2F2),
          const Color(0xFF7C8B8D),
        ),
    };

    return Container(
      width: 148,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: status == PatientStatus.awaitingAcceptance
                  ? const Color(0xFFD10000)
                  : foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: foreground)),
            ),
          ),
        ],
      ),
    );
  }
}
