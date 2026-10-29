import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:pholders_app/core/di/service_locator.dart';
import 'package:pholders_app/core/network/api_exception.dart';
import 'package:pholders_app/features/doctor/patients/data/patient_record_repository.dart';
import 'package:pholders_app/features/doctor/patients/presentation/patients_screen.dart'
    show Patient;

const _teal = Color(0xFF2EC4C4);
const _tealLight = Color(0xFFE6F7F7);
const _textPrimary = Color(0xFF1A2B2B);
const _textSecondary = Color(0xFF8A9E9E);
const _border = Color(0xFFE8F0F0);

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
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open_outlined, size: 18, color: _teal),
                const SizedBox(width: 8),
                const Text("Patient's documents",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
                const Spacer(),
                if (!_loading)
                  IconButton(
                    tooltip: 'Refresh',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh_rounded,
                        size: 18, color: _textSecondary),
                    onPressed: _load,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
          ),
        ),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!,
              style: const TextStyle(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ],
      );
    }
    if (_documents.isEmpty) {
      return const Text(
        'The patient has not stored any documents yet. Files they add in the '
        'Pholders app appear here.',
        style: TextStyle(fontSize: 13, height: 1.5, color: _textSecondary),
      );
    }
    return Column(
      children: [
        for (final d in _documents)
          _DocumentRow(
            document: d,
            downloading: _downloadingId == d.id,
            onDownload: _downloadingId == null ? () => _download(d) : null,
          ),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.downloading,
    required this.onDownload,
  });

  final PatientDocument document;
  final bool downloading;
  final VoidCallback? onDownload;

  static String _day(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String? _size(int? bytes) {
    if (bytes == null) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final d = document;
    final meta = [
      if (d.category != null) d.category!.replaceAll('_', ' '),
      if (_size(d.sizeBytes) != null) _size(d.sizeBytes)!,
      if (d.uploadedAt != null) 'Added ${_day(d.uploadedAt!)}',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insert_drive_file_outlined,
                size: 18, color: _teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary)),
                if (d.description != null) ...[
                  const SizedBox(height: 2),
                  Text(d.description!,
                      style: const TextStyle(fontSize: 13, color: _textPrimary)),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta,
                      style:
                          const TextStyle(fontSize: 12, color: _textSecondary)),
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
                        strokeWidth: 2, color: _teal),
                  ),
                )
              : IconButton(
                  tooltip: 'Download',
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined,
                      size: 20, color: _teal),
                ),
        ],
      ),
    );
  }
}
