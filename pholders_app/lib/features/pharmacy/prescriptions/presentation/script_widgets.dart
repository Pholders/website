import 'package:flutter/material.dart';

import '../data/pharmacy_script.dart';

const Color scriptTeal = Color(0xFF309CA3);
const Color scriptAqua = Color(0xFF6DD0D8);
const Color scriptTextDark = Color(0xFF1F2937);
const Color scriptTextMuted = Color(0xFF6B7280);
const Color _notifiedGreen = Color(0xFF34D399);

Color stageColour(ScriptStage stage) => switch (stage) {
      ScriptStage.newScript => const Color(0xFFFBBF24),
      ScriptStage.accepted => const Color(0xFF3B82F6),
      ScriptStage.inProgress => const Color(0xFFF97316),
      ScriptStage.ready => _notifiedGreen,
      ScriptStage.collected || ScriptStage.dispensed => const Color(0xFF9CA3AF),
      ScriptStage.closed => const Color(0xFFDC2626),
    };

/// The coloured dot and label for where a script is.
class StageBadge extends StatelessWidget {
  const StageBadge({super.key, required this.stage});
  final ScriptStage stage;

  @override
  Widget build(BuildContext context) {
    final colour = stageColour(stage);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: colour),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            stage.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colour),
          ),
        ),
      ],
    );
  }
}

/// The bell that says the patient has been sent an update.
class PatientNotifiedBell extends StatelessWidget {
  const PatientNotifiedBell({super.key, required this.lastUpdate});

  /// The order step the patient was last told about.
  final String lastUpdate;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Patient notified: $lastUpdate',
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x3334D399),
        ),
        child: const Icon(Icons.notifications_active,
            size: 10, color: _notifiedGreen),
      ),
    );
  }
}
