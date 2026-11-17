import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../../app/app_state.dart';
import '../data/models/signing_receipt.dart';
import '../redux/prescriptions_actions.dart';

const _textPrimary = Color(0xFF1A2B2B);
const _textSecondary = Color(0xFF8A9E9E);
const _border = Color(0xFFE8F0F0);
const _teal = Color(0xFF2EC4C4);
const _amber = Color(0xFFF5A623);

/// Shown once, straight after a prescription is signed.
///
/// The QR payload and access link are minted during signing and no
/// doctor-callable endpoint returns them afterwards, so this is the doctor's
/// only chance to capture them. The dialog says as much rather than letting
/// someone close it and find out later.
class SigningReceiptDialog extends StatelessWidget {
  const SigningReceiptDialog({super.key, required this.receipt});

  final SigningReceipt receipt;

  void _close(BuildContext context) {
    StoreProvider.of<AppState>(context).dispatch(
      const ClearSigningReceiptAction(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_outlined, color: _teal, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Prescription signed',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                receipt.prescriptionNumber.isEmpty
                    ? 'Give the patient this code to use at the pharmacy.'
                    : '${receipt.prescriptionNumber} — give the patient this '
                        'code to use at the pharmacy.',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 18),
              Flexible(child: _body(context)),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _teal),
                  onPressed: () => _close(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (receipt.qrPayload.isNotEmpty) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: CustomPaint(
                  size: const Size(190, 190),
                  painter: _QrPainter(receipt.qrPayload),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Scannable once. Valid for 90 days.',
                style: TextStyle(fontSize: 11, color: _textSecondary),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Closing this dialog is irreversible, and that is not obvious.
          const _Notice(
            icon: Icons.info_outline,
            colour: _amber,
            text: 'This code is shown only now. It cannot be retrieved after '
                'you close this window, and the prescription cannot be signed '
                'again.',
          ),

          if (receipt.accessLink.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Label('Secure link'),
            _CopyRow(value: receipt.accessLink),
            if (receipt.linkIsUnreachable) ...[
              const SizedBox(height: 8),
              const _Notice(
                icon: Icons.link_off,
                colour: _amber,
                text: 'This link points at localhost, so it will not open for '
                    'the patient. The server needs its public address '
                    'configured before the link can be shared.',
              ),
            ],
          ],

          const SizedBox(height: 16),
          const _Label('Signature'),
          _DetailLine('Method', receipt.signatureMethod ?? '—'),
          if (receipt.signedBy != null) _DetailLine('Signed by', receipt.signedBy!),
          if (receipt.signedAt != null)
            _DetailLine('Signed at', _formatTimestamp(receipt.signedAt!)),
          if (receipt.medicineCount != null)
            _DetailLine('Medicines', '${receipt.medicineCount}'),
          if (receipt.signatureFingerprint != null)
            _DetailLine('Fingerprint', receipt.signatureFingerprint!),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

/// Paints the QR using the `barcode` package already bundled for prescription
/// PDFs, so this needs no new dependency.
class _QrPainter extends CustomPainter {
  const _QrPainter(this.data);

  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0D1B1B);
    for (final element in Barcode.qrCode().make(
      data,
      width: size.width,
      height: size.height,
    )) {
      if (element is BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width,
            element.height,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.data != data;
}

class _CopyRow extends StatefulWidget {
  const _CopyRow({required this.value});
  final String value;

  @override
  State<_CopyRow> createState() => _CopyRowState();
}

class _CopyRowState extends State<_CopyRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              widget.value,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, color: _textPrimary),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.value));
              if (mounted) setState(() => _copied = true);
            },
            icon: Icon(_copied ? Icons.check : Icons.copy, size: 15),
            label: Text(_copied ? 'Copied' : 'Copy'),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.colour,
    required this.text,
  });

  final IconData icon;
  final Color colour;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: colour),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: _textPrimary),
            ),
          ),
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

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _textSecondary)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, color: _textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
