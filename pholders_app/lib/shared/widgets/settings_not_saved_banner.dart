import 'package:flutter/material.dart';

/// Says that the controls below it do not save anywhere yet.
///
/// Several settings screens are drawn but have no server behind them — there
/// are no endpoints for a doctor's notification preferences, two-factor,
/// biometrics or security alerts, so nothing on those screens could be
/// stored by any route through the code.
///
/// Until this, they looked finished: every switch defaulted to on, so a
/// setting read as enabled whether or not it was, and the buttons popped a
/// message saying the label had been tapped. A tester cannot tell that from
/// a save that silently fails, and the two want very different responses.
class SettingsNotSavedBanner extends StatelessWidget {
  const SettingsNotSavedBanner(this.detail, {super.key});

  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8D7A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 17, color: Color(0xFF9A7B22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF6B5410),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
