import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/prescription_document.dart';

/// Builds an A4 prescription PDF aligned with SA e-prescribing standards.
class PrescriptionDocumentPdf {
  static const PdfColor _teal = PdfColor.fromInt(0xFF309CA3);
  static const PdfColor _tealLight = PdfColor.fromInt(0xFFE8F8F8);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _verifiedBlue = PdfColor.fromInt(0xFF2563EB);

  static Future<Uint8List> build(PrescriptionDocument document) async {
    final pdf = pw.Document(
      title: 'Prescription ${document.referenceNumber}',
      author: document.prescriber.name,
      creator: 'Pholders Platform',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (context) => [
          _buildHeader(document),
          pw.SizedBox(height: 14),
          _buildMetaRow(document),
          pw.SizedBox(height: 12),
          _buildTwoColumnSection(
            'Patient Details',
            [
              _field('Full Name', document.patient.name),
              _field('ID / Passport', document.patient.idNumber),
              _field('Date of Birth', document.patient.dateOfBirth),
              _field('Gender', document.patient.gender),
              _field('Address', document.patient.address),
              _field('Contact', '${document.patient.phone} · ${document.patient.email}'),
            ],
            'Medical Aid',
            [
              _field('Scheme', document.medicalAid.schemeName),
              _field('Plan', document.medicalAid.plan),
              _field('Member No.', document.medicalAid.memberNumber),
              _field('Dependent', '${document.medicalAid.dependentCode} — ${document.medicalAid.dependentDescription}'),
              _field('Practice No.', document.prescriber.practiceNumber),
              _field('Authorization', document.medicalAid.authorizationNumber),
            ],
          ),
          if (document.diagnosis != null) ...[
            pw.SizedBox(height: 12),
            _buildSection(
              'Diagnosis (ICD-10)',
              [document.diagnosis!.display],
            ),
          ],
          pw.SizedBox(height: 12),
          _buildMedicationsSection(document),
          if (document.additionalSelfMedication.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildSection(
              'Additional Self-Medication (Patient Reported)',
              document.additionalSelfMedication,
            ),
          ],
          pw.SizedBox(height: 12),
          _buildTwoColumnSection(
            'Fulfillment',
            [
              _field('Collection / Delivery', document.collection.preference),
              _field('Pharmacy', document.collection.pharmacyName),
              if (document.collection.pharmacyAddress.isNotEmpty)
                _field('Pharmacy Address', document.collection.pharmacyAddress),
              _field('Generic Substitution', document.genericSubstitution),
            ],
            'Payment',
            [
              _field('Method', document.payment.method),
              _field('Status', document.payment.status),
            ],
          ),
          pw.SizedBox(height: 12),
          _buildSignatureSection(document),
          pw.SizedBox(height: 10),
          _buildFooter(document),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(PrescriptionDocument document) {
    final prescriber = document.prescriber;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _teal,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ELECTRONIC PRESCRIPTION',
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  prescriber.name,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  prescriber.qualification,
                  style: const pw.TextStyle(color: _white, fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  prescriber.practiceName,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  prescriber.practiceAddress,
                  style: const pw.TextStyle(color: _white, fontSize: 8.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'HPCSA: ${prescriber.hpcsaNumber}  ·  Practice No: ${prescriber.practiceNumber}',
                  style: const pw.TextStyle(color: _white, fontSize: 8.5),
                ),
                pw.Text(
                  'Tel: ${prescriber.contactNumber}',
                  style: const pw.TextStyle(color: _white, fontSize: 8.5),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: _white,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: document.qrPayload,
                  width: 72,
                  height: 72,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Scan to verify',
                style: pw.TextStyle(
                  color: _white,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                document.referenceNumber,
                style: const pw.TextStyle(color: _white, fontSize: 7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaRow(PrescriptionDocument document) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _tealLight,
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _metaItem('Script Reference', document.referenceNumber),
          _metaItem('Date Issued', document.issuedDateFormatted),
          _metaItem('Valid Until', document.validUntilFormatted),
          _metaItem('Status', document.currentStatus),
        ],
      ),
    );
  }

  static pw.Widget _metaItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7.5,
            color: _textMuted,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: _textDark,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTwoColumnSection(
    String leftTitle,
    List<_PdfField> leftFields,
    String rightTitle,
    List<_PdfField> rightFields,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildFieldSection(leftTitle, leftFields)),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildFieldSection(rightTitle, rightFields)),
      ],
    );
  }

  static pw.Widget _buildFieldSection(String title, List<_PdfField> fields) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: _border, height: 1),
          pw.SizedBox(height: 6),
          ...fields.map(_buildFieldRow),
        ],
      ),
    );
  }

  static pw.Widget _buildFieldRow(_PdfField field) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 78,
            child: pw.Text(
              field.label,
              style: const pw.TextStyle(fontSize: 8, color: _textMuted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              field.value,
              style: pw.TextStyle(
                fontSize: 8.5,
                color: _textDark,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(String title, List<String> lines) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 6),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                line,
                style: const pw.TextStyle(fontSize: 8.5, color: _textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMedicationsSection(PrescriptionDocument document) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Prescribed Medications',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _textDark,
          ),
        ),
        pw.SizedBox(height: 8),
        ...document.medications.map(_buildMedicationCard),
      ],
    );
  }

  static pw.Widget _buildMedicationCard(PrescriptionMedication med) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _tealLight,
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${med.lineNumber}. ${med.fullName}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
              pw.Text(
                'Sched ${med.schedule}',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _teal,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'NAPPI: ${med.nappiCode}',
            style: const pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
          pw.SizedBox(height: 6),
          _medRow('Dosage', '${med.dosage} · ${med.frequency}'),
          _medRow('Route', med.route),
          _medRow('Duration', med.duration),
          _medRow('Quantity', '${med.quantityDisplay} · Repeats: ${med.repeats}'),
          if (med.instructions.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Instructions: ${med.instructions.join(' · ')}',
              style: const pw.TextStyle(fontSize: 8, color: _textDark),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _medRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 56,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: _textMuted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8.5, color: _textDark),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection(PrescriptionDocument document) {
    final sig = document.signature;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 1.2),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Digital Signature & Authentication',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Signed by: ${sig.signedBy}',
                  style: pw.TextStyle(fontSize: 9, color: _textDark, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'HPCSA: ${sig.hpcsaNumber}',
                  style: const pw.TextStyle(fontSize: 8.5, color: _textMuted),
                ),
                pw.Text(
                  sig.verificationMethod,
                  style: const pw.TextStyle(fontSize: 8.5, color: _textMuted),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: _verifiedBlue,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    sig.verifiedStatus.toUpperCase(),
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Signed: ${sig.signedAtFormatted}',
                  style: const pw.TextStyle(fontSize: 8, color: _textMuted),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 120,
            height: 48,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              sig.signedBy,
              style: pw.TextStyle(
                fontSize: 14,
                color: _teal,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(PrescriptionDocument document) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Pholders Platform · Confidential patient health record',
            style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
          ),
          pw.Text(
            'Retain for 5 years per SA regulations',
            style: const pw.TextStyle(fontSize: 7.5, color: _textMuted),
          ),
        ],
      ),
    );
  }

  static _PdfField _field(String label, String value) => _PdfField(label, value);
}

class _PdfField {
  final String label;
  final String value;

  const _PdfField(this.label, this.value);
}
