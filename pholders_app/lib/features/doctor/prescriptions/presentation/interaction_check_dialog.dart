import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../app/app_state.dart';
import '../data/models/safety_report.dart';
import '../redux/prescriptions_actions.dart';

const _textPrimary = Color(0xFF1A2B2B);
const _textSecondary = Color(0xFF8A9E9E);
const _border = Color(0xFFE8F0F0);
const _teal = Color(0xFF2EC4C4);
const _amber = Color(0xFFF5A623);
const _danger = Color(0xFFFF6B6B);

/// Shows the drug interaction check for one prescription.
///
/// Runs the check when it opens, so the doctor sees a result rather than a
/// button they have to press twice.
class InteractionCheckDialog extends StatefulWidget {
  const InteractionCheckDialog({
    super.key,
    required this.prescriptionId,
    required this.patientName,
  });

  final int prescriptionId;
  final String patientName;

  @override
  State<InteractionCheckDialog> createState() => _InteractionCheckDialogState();
}

class _InteractionCheckDialogState extends State<InteractionCheckDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StoreProvider.of<AppState>(context).dispatch(
          CheckInteractionsAction(prescriptionId: widget.prescriptionId),
        );
      }
    });
  }

  void _close() {
    // Clear the report so reopening on another prescription cannot flash the
    // previous result.
    StoreProvider.of<AppState>(context)
        .dispatch(const ClearInteractionsReportAction());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _CheckViewModel>(
      converter: _CheckViewModel.fromStore,
      builder: (context, vm) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Interaction check',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prescription for ${widget.patientName}',
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Flexible(child: _body(vm)),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _close,
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(_CheckViewModel vm) {
    if (vm.isChecking) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _teal),
              SizedBox(height: 14),
              Text('Checking medicines...',
                  style: TextStyle(fontSize: 13, color: _textSecondary)),
            ],
          ),
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36, color: _textSecondary),
            const SizedBox(height: 12),
            Text(vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => StoreProvider.of<AppState>(context).dispatch(
                CheckInteractionsAction(prescriptionId: widget.prescriptionId),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final report = vm.report;
    if (report == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Banner(report: report),
          const SizedBox(height: 16),

          if (report.medicinesChecked.isNotEmpty) ...[
            const _Label('Medicines checked'),
            Text(
              report.medicinesChecked.join(', '),
              style: const TextStyle(fontSize: 13, color: _textPrimary),
            ),
            const SizedBox(height: 16),
          ],

          if (report.severe.isNotEmpty) ...[
            const _Label('Severe'),
            ...report.severe.map((i) => _InteractionTile(i, _danger)),
            const SizedBox(height: 12),
          ],
          if (report.moderate.isNotEmpty) ...[
            const _Label('Moderate'),
            ...report.moderate.map((i) => _InteractionTile(i, _amber)),
            const SizedBox(height: 12),
          ],
          if (report.mild.isNotEmpty) ...[
            const _Label('Mild'),
            ...report.mild.map((i) => _InteractionTile(i, _textSecondary)),
            const SizedBox(height: 12),
          ],
          if (report.contraindications.isNotEmpty) ...[
            const _Label('Patient contraindications'),
            ...report.contraindications.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• ${c.warning}',
                    style: const TextStyle(fontSize: 13, color: _textPrimary)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (report.recommendedActions.isNotEmpty) ...[
            const _Label('Recommended'),
            ...report.recommendedActions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $a',
                    style: const TextStyle(fontSize: 13, color: _textPrimary)),
              ),
            ),
          ],

          // The backend assumes a 35-year-old, 70kg patient unless told
          // otherwise, which is worth knowing before trusting a dosage review.
          const SizedBox(height: 16),
          const Text(
            'Checked against the medicines on this prescription only, using '
            'default patient age and weight.',
            style: TextStyle(fontSize: 11, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.report});

  final SafetyReport report;

  @override
  Widget build(BuildContext context) {
    late final Color colour;
    late final IconData icon;
    switch (report.level) {
      case SafetyLevel.safe:
        colour = _teal;
        icon = Icons.check_circle_outline;
      case SafetyLevel.cautionRequired:
      case SafetyLevel.requiresReview:
        colour = _amber;
        icon = Icons.warning_amber_outlined;
      case SafetyLevel.highRisk:
        colour = _danger;
        icon = Icons.dangerous_outlined;
      case SafetyLevel.unknown:
        colour = _textSecondary;
        icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colour, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              report.headline,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: colour),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionTile extends StatelessWidget {
  const _InteractionTile(this.interaction, this.colour);

  final DrugInteraction interaction;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            interaction.pair,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: colour),
          ),
          const SizedBox(height: 4),
          Text(interaction.interaction,
              style: const TextStyle(fontSize: 12, color: _textPrimary)),
          if (interaction.recommendation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(interaction.recommendation,
                style: const TextStyle(fontSize: 12, color: _textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: _textPrimary),
      ),
    );
  }
}

// Store bindings ------------------------------------------------------------

class _CheckViewModel {
  const _CheckViewModel({
    required this.isChecking,
    this.report,
    this.errorMessage,
  });

  factory _CheckViewModel.fromStore(Store<AppState> store) {
    final state = store.state.prescriptionsState;
    return _CheckViewModel(
      isChecking: state.isCheckingInteractions,
      report: state.safetyReport,
      errorMessage: state.errorMessage,
    );
  }

  final bool isChecking;
  final SafetyReport? report;
  final String? errorMessage;
}
