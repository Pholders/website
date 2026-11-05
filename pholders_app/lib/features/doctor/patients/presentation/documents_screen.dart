import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;
import 'package:pholders_app/features/doctor/patients/presentation/record_card.dart';

/// The Documents tab of a patient's profile: the files the patient stored in
/// the patient app, with a real download. Read-only.
///
/// It used to start with eight invented files ("Blood Test Report", "uploaded
/// by Dr Smith"), and upload, preview, download and "copy link" only
/// pretended. Doctors cannot upload to a patient's record yet, so that is not
/// offered.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.patient, this.repository});

  final Patient patient;
  final PatientRecordRepository? repository;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final PatientRecordRepository _repo =
      widget.repository ?? sl<PatientRecordRepository>();

  List<PatientDocument> _documents = const [];
  bool _loading = true;
  String? _error;
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final documents = await _repo.fetchDocuments(widget.patient.id);
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _download(PatientDocument doc) async {
    setState(() => _downloadingId = doc.id);
    try {
      final bytes = await _repo.downloadDocument(widget.patient.id, doc.id);
      await Printing.sharePdf(bytes: bytes, filename: doc.name);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RecordCard(
      icon: Icons.folder_open_outlined,
      title: 'Documents',
      subtitle: 'Files the patient has stored in their record',
      child: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const RecordMessage();
    if (_error != null) {
      return RecordMessage(
        text: _error,
        action: TextButton(onPressed: _load, child: const Text('Try again')),
      );
    }
    if (_documents.isEmpty) {
      return const RecordMessage(
        text: 'The patient has not stored any documents yet. Files they add '
            'in the Pholders app appear here.',
      );
    }
    final newest = _documents.toList()
      ..sort((a, b) =>
          (b.uploadedAt ?? DateTime(0)).compareTo(a.uploadedAt ?? DateTime(0)));
    return Column(
      children: [
        for (final d in newest)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DocumentRow(
              document: d,
              downloading: _downloadingId == d.id,
              onDownload: _downloadingId == null ? () => _download(d) : null,
            ),
          ),
      ],
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A file on a pale tile: a file icon, its name and what it is, when it was
/// added, and a download.
class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.downloading,
    required this.onDownload,
  });

  final PatientDocument document;
  final bool downloading;
  final VoidCallback? onDownload;

  static String? _size(int? bytes) {
    if (bytes == null) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final d = document;
    final added = d.uploadedAt?.toLocal();
    final meta = [
      if (d.category != null) d.category!.replaceAll('_', ' '),
      if (_size(d.sizeBytes) != null) _size(d.sizeBytes)!,
    ].join(' · ');

    return RecordTile(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file_outlined,
                size: 20, color: RecordColors.darkTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: RecordColors.ink)),
                if (d.description != null) ...[
                  const SizedBox(height: 3),
                  Text(d.description!,
                      style: const TextStyle(
                          fontSize: 13, color: RecordColors.ink)),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(meta,
                      style: const TextStyle(
                          fontSize: 12, color: RecordColors.muted)),
                ],
                if (added != null) ...[
                  const SizedBox(height: 3),
                  Text(
                      'Added ${added.day} ${_months[added.month - 1]} '
                      '${added.year}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: RecordColors.label)),
                ],
              ],
            ),
          ),
          downloading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: RecordColors.darkTeal),
                  ),
                )
              : IconButton(
                  tooltip: 'Download',
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined,
                      size: 22, color: RecordColors.darkTeal),
                ),
        ],
      ),
    );
  }
}
