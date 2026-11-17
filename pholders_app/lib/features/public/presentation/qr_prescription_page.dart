import 'package:flutter/material.dart';

import '../data/models/qr_prescription.dart';
import '../data/qr_prescription_repository.dart';

const _bg = Color(0xFFE8F8F8);
const _teal = Color(0xFF309CA3);
const _textDark = Color(0xFF1F2937);
const _textMuted = Color(0xFF6B7280);
const _line = Color(0xFFE5E7EB);

/// The page a prescription QR code opens.
///
/// Public by design — whoever holds the link holds the prescription — and
/// the code can be opened exactly once. So the page checks whether the code
/// is still good, shows what is about to happen, and spends it only when
/// someone taps. Opening on load would let a messaging app's link preview
/// burn the code before the patient ever saw it.
class QrPrescriptionPage extends StatefulWidget {
  const QrPrescriptionPage({super.key, required this.token});

  final String token;

  @override
  State<QrPrescriptionPage> createState() => _QrPrescriptionPageState();
}

enum _Stage { checking, ready, opening, opened, unusable }

class _QrPrescriptionPageState extends State<QrPrescriptionPage> {
  final _repository = QrPrescriptionRepository();

  _Stage _stage = _Stage.checking;
  String? _problem;
  QrPrescription? _prescription;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _stage = _Stage.checking;
      _problem = null;
    });
    try {
      final status = await _repository.checkStatus(widget.token);
      if (!mounted) return;
      setState(() {
        if (status.usable) {
          _stage = _Stage.ready;
        } else {
          _stage = _Stage.unusable;
          _problem = status.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.unusable;
        _problem = 'This link could not be checked. Check your connection and '
            'try again.';
      });
    }
  }

  Future<void> _open() async {
    setState(() => _stage = _Stage.opening);
    try {
      final prescription = await _repository.open(widget.token);
      if (!mounted) return;
      setState(() {
        _prescription = prescription;
        _stage = _Stage.opened;
      });
    } on QrAccessException catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.unusable;
        _problem = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.unusable;
        _problem = 'This prescription could not be opened. Try again in a '
            'moment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: _card(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      padding: const EdgeInsets.all(24),
      child: switch (_stage) {
        _Stage.checking => _message(
            icon: null,
            title: 'Checking this link...',
            body: 'One moment.',
            busy: true,
          ),
        _Stage.ready => _confirm(),
        _Stage.opening => _message(
            icon: null,
            title: 'Opening the prescription...',
            body: 'This takes a moment on first use.',
            busy: true,
          ),
        _Stage.unusable => _message(
            icon: Icons.link_off,
            title: 'This link cannot be opened',
            body: _problem ?? 'The prescription is not available.',
            action: TextButton(onPressed: _check, child: const Text('Try again')),
          ),
        _Stage.opened => _prescriptionView(_prescription!),
      },
    );
  }

  Widget _message({
    IconData? icon,
    required String title,
    required String body,
    bool busy = false,
    Widget? action,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: CircularProgressIndicator(color: _teal),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Icon(icon, size: 38, color: _textMuted),
          ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: _textMuted, height: 1.45),
        ),
        if (action != null) ...[const SizedBox(height: 12), action],
      ],
    );
  }

  Widget _confirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: _teal, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Prescription ready',
                style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w700, color: _textDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'This code opens one prescription, once. After you open it the link '
          'stops working, so open it when you are with the pharmacist or ready '
          'to read it.',
          style: TextStyle(fontSize: 14.5, color: _textMuted, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: _open,
            child: const Text('Open the prescription'),
          ),
        ),
      ],
    );
  }

  Widget _prescriptionView(QrPrescription p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          p.number.isEmpty ? 'Prescription' : p.number,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 4),
        Text(
          p.isSigned
              ? 'Signed by the doctor and valid for dispensing'
              : 'Not yet signed — a pharmacy cannot dispense this',
          style: TextStyle(
            fontSize: 13,
            color: p.isSigned ? const Color(0xFF1B7F4B) : const Color(0xFFB3261E),
          ),
        ),
        const SizedBox(height: 20),
        if (p.patientName != null) _detailRow('Patient', p.patientName!),
        if (p.prescriberName != null)
          _detailRow(
            'Prescriber',
            p.prescriberHpcsa == null
                ? p.prescriberName!
                : '${p.prescriberName!}  ·  HPCSA ${p.prescriberHpcsa!}',
          ),
        if (p.prescriberPhone != null) _detailRow('Contact', p.prescriberPhone!),
        if (p.diagnosis != null) _detailRow('Diagnosis', p.diagnosis!),
        if (p.signedAt != null) _detailRow('Signed', _date(p.signedAt!)),
        const SizedBox(height: 18),
        const Text(
          'Medicines',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 8),
        if (p.medicines.isEmpty)
          const Text('No medicines are listed on this prescription.',
              style: TextStyle(fontSize: 14, color: _textMuted))
        else
          ...p.medicines.map(_medicine),
        if (p.clinicalNotes != null) ...[
          const SizedBox(height: 16),
          _detailRow('Notes', p.clinicalNotes!),
        ],
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'This link has now been used and will not open again. The pharmacy '
            'can still retrieve the prescription from its own system.',
            style: TextStyle(fontSize: 12.5, color: _textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _medicine(QrMedicine m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textDark),
                ),
              ),
              if (m.schedule != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Schedule ${m.schedule}',
                    style: const TextStyle(fontSize: 11, color: _teal),
                  ),
                ),
            ],
          ),
          if (m.detail.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(m.detail,
                style: const TextStyle(fontSize: 13.5, color: _textMuted)),
          ],
          if (m.instructions != null) ...[
            const SizedBox(height: 4),
            Text(m.instructions!,
                style: const TextStyle(
                    fontSize: 13, color: _textDark, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: _textMuted)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14, color: _textDark),
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = value.toLocal();
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}
