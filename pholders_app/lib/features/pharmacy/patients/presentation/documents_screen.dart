import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pholders_app/features/pharmacy/patients/presentation/patients_screen.dart' show Patient;
import 'dart:math';

// ─── Colors ───────────────────────────────────────────────────────────────────
class DocColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const tealDark = Color(0xFF1A9E9E);
  static const bg = Color(0xFFF4FAFA);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const cardBg = Color(0xFFFFFFFF);
  static const danger = Color(0xFFFF6B6B);
  static const dangerLight = Color(0xFFFFEEEE);
  static const amber = Color(0xFFF5A623);
  static const amberLight = Color(0xFFFFF3DC);
  static const green = Color(0xFF4CAF50);
  static const greenLight = Color(0xFFE8F5E9);
}

// ─── Document type enum ───────────────────────────────────────────────────────
enum DocType { all, labResult, prescription, report, imaging, other }

extension DocTypeLabel on DocType {
  String get label {
    switch (this) {
      case DocType.all: return 'All';
      case DocType.labResult: return 'Lab Results';
      case DocType.prescription: return 'Prescriptions';
      case DocType.report: return 'Reports';
      case DocType.imaging: return 'Imaging';
      case DocType.other: return 'Other';
    }
  }

  String get displayName {
    switch (this) {
      case DocType.all: return 'All';
      case DocType.labResult: return 'Lab Result';
      case DocType.prescription: return 'Prescription';
      case DocType.report: return 'Report';
      case DocType.imaging: return 'Imaging';
      case DocType.other: return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case DocType.all: return DocColors.teal;
      case DocType.labResult: return const Color(0xFF2EC4C4);
      case DocType.prescription: return const Color(0xFF9B59B6);
      case DocType.report: return const Color(0xFFF5A623);
      case DocType.imaging: return const Color(0xFF3498DB);
      case DocType.other: return const Color(0xFF8A9E9E);
    }
  }

  Color get bgColor {
    switch (this) {
      case DocType.all: return DocColors.tealLight;
      case DocType.labResult: return DocColors.tealLight;
      case DocType.prescription: return const Color(0xFFF3E8FF);
      case DocType.report: return const Color(0xFFFFF3DC);
      case DocType.imaging: return const Color(0xFFE8F4FD);
      case DocType.other: return const Color(0xFFF0F0F0);
    }
  }

  IconData get icon {
    switch (this) {
      case DocType.all: return Icons.folder_outlined;
      case DocType.labResult: return Icons.biotech_outlined;
      case DocType.prescription: return Icons.medication_outlined;
      case DocType.report: return Icons.description_outlined;
      case DocType.imaging: return Icons.image_outlined;
      case DocType.other: return Icons.attach_file_outlined;
    }
  }
}

// ─── Document model ───────────────────────────────────────────────────────────
class MedDocument {
  final String id;
  final String name;
  final DocType type;
  final String patientName;
  final DateTime dateUploaded;
  final String uploadedBy;
  final String fileSize;
  final String fileExtension;
  bool isStarred;

  MedDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.patientName,
    required this.dateUploaded,
    required this.uploadedBy,
    required this.fileSize,
    required this.fileExtension,
    this.isStarred = false,
  });

  MedDocument copyWith({
    String? name,
    DocType? type,
    bool? isStarred,
  }) =>
      MedDocument(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        patientName: patientName,
        dateUploaded: dateUploaded,
        uploadedBy: uploadedBy,
        fileSize: fileSize,
        fileExtension: fileExtension,
        isStarred: isStarred ?? this.isStarred,
      );
}

// ─── Documents Screen ─────────────────────────────────────────────────────────
class DocumentsScreen extends StatefulWidget {
  final Patient patient;

  const DocumentsScreen({super.key, required this.patient});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  DocType _activeFilter = DocType.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sortBy = 'date'; // 'date', 'name', 'type'
  bool _sortAsc = false;

  // Real document list — starts empty, populated via upload dialog
  final List<MedDocument> _documents = [];

  @override
  void initState() {
    super.initState();
    // Pre-seed with realistic documents for this patient
    _documents.addAll(_seedDocuments(widget.patient.name));
  }

  List<MedDocument> _seedDocuments(String patientName) {
    final now = DateTime.now();
    return [
      MedDocument(
        id: _uid(),
        name: 'Blood Test Report',
        type: DocType.labResult,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 2)),
        uploadedBy: 'Dr Smith',
        fileSize: '1.2 MB',
        fileExtension: 'PDF',
      ),
      MedDocument(
        id: _uid(),
        name: 'Chest X-Ray',
        type: DocType.imaging,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 5)),
        uploadedBy: 'Dr Smith',
        fileSize: '4.8 MB',
        fileExtension: 'DICOM',
      ),
      MedDocument(
        id: _uid(),
        name: 'Prescription PDF',
        type: DocType.prescription,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 7)),
        uploadedBy: 'Dr Smith',
        fileSize: '0.5 MB',
        fileExtension: 'PDF',
      ),
      MedDocument(
        id: _uid(),
        name: 'Cardiology Report',
        type: DocType.report,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 10)),
        uploadedBy: 'Dr Mokoena',
        fileSize: '2.1 MB',
        fileExtension: 'PDF',
      ),
      MedDocument(
        id: _uid(),
        name: 'MRI Scan Results',
        type: DocType.imaging,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 14)),
        uploadedBy: 'Dr Smith',
        fileSize: '12.3 MB',
        fileExtension: 'DICOM',
      ),
      MedDocument(
        id: _uid(),
        name: 'Diabetes Follow-up Report',
        type: DocType.report,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 20)),
        uploadedBy: 'Dr Mokoena',
        fileSize: '1.8 MB',
        fileExtension: 'PDF',
      ),
      MedDocument(
        id: _uid(),
        name: 'HbA1c Lab Result',
        type: DocType.labResult,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 25)),
        uploadedBy: 'Dr Smith',
        fileSize: '0.9 MB',
        fileExtension: 'PDF',
      ),
      MedDocument(
        id: _uid(),
        name: 'Ophthalmology Referral',
        type: DocType.other,
        patientName: patientName,
        dateUploaded: now.subtract(const Duration(days: 30)),
        uploadedBy: 'Dr Smith',
        fileSize: '0.3 MB',
        fileExtension: 'DOCX',
      ),
    ];
  }

  String _uid() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(9999).toString();

  List<MedDocument> get _filtered {
    var list = _documents.where((d) {
      final matchesType =
          _activeFilter == DocType.all || d.type == _activeFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.patientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          d.type.displayName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.name.compareTo(b.name);
        case 'type':
          cmp = a.type.displayName.compareTo(b.type.displayName);
        default:
          cmp = a.dateUploaded.compareTo(b.dateUploaded);
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  void _uploadDocument() async {
    final result = await showDialog<MedDocument>(
      context: context,
      builder: (_) => _UploadDocumentDialog(patientName: widget.patient.name),
    );
    if (result != null) {
      setState(() => _documents.insert(0, result));
      _showSnackBar('Document uploaded successfully', isSuccess: true);
    }
  }

  void _deleteDocument(MedDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Document',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to permanently delete "${doc.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: DocColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _documents.removeWhere((d) => d.id == doc.id));
      _showSnackBar('Document deleted', isSuccess: false);
    }
  }

  void _toggleStar(MedDocument doc) {
    setState(() {
      final i = _documents.indexWhere((d) => d.id == doc.id);
      if (i != -1) _documents[i].isStarred = !_documents[i].isStarred;
    });
  }

  void _viewDocument(MedDocument doc) {
    showDialog(
      context: context,
      builder: (_) => _DocumentViewerDialog(doc: doc),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isSuccess ? DocColors.teal : DocColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: DocColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DocColors.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: DocColors.tealLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_copy_outlined,
                      color: DocColors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Medical Documents',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DocColors.textPrimary),
                ),
                const Spacer(),

                // Search bar
                Container(
                  width: 240,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DocColors.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DocColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search documents...',
                      hintStyle: TextStyle(
                          color: DocColors.textSecondary, fontSize: 12),
                      prefixIcon: Icon(Icons.search,
                          size: 17, color: DocColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Sort button
                _SortButton(
                  sortBy: _sortBy,
                  sortAsc: _sortAsc,
                  onChanged: (by, asc) =>
                      setState(() { _sortBy = by; _sortAsc = asc; }),
                ),

                const SizedBox(width: 12),

                // Upload button
                ElevatedButton.icon(
                  onPressed: _uploadDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DocColors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 18),
                  label: const Text('Upload Documents',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Text(
              'Upload, review, and manage patient documents',
              style: TextStyle(
                  fontSize: 13, color: DocColors.textSecondary),
            ),

            const SizedBox(height: 20),

            // ── Filter tabs ──────────────────────────────────────────────────
            Row(
              children: DocType.values.map((type) {
                final active = type == _activeFilter;
                final count = type == DocType.all
                    ? _documents.length
                    : _documents
                        .where((d) => d.type == type)
                        .length;

                return GestureDetector(
                  onTap: () =>
                      setState(() => _activeFilter = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? DocColors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: active
                              ? DocColors.teal
                              : DocColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : DocColors.textSecondary,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withOpacity(0.25)
                                  : DocColors.tealLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : DocColors.teal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Table header ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: DocColors.border)),
              ),
              child: Row(
                children: [
                  const Expanded(
                      flex: 4,
                      child: _DocHeaderCell('Document Name')),
                  const Expanded(
                      flex: 2, child: _DocHeaderCell('Type')),
                  const Expanded(
                      flex: 2, child: _DocHeaderCell('Patient')),
                  const Expanded(
                      flex: 2,
                      child: _DocHeaderCell('Date Uploaded')),
                  const Expanded(
                      flex: 2,
                      child: _DocHeaderCell('Uploaded By')),
                  const Expanded(
                      flex: 1, child: _DocHeaderCell('Size')),
                  const Expanded(
                      flex: 1, child: _DocHeaderCell('Actions')),
                ],
              ),
            ),

            // ── Table rows ───────────────────────────────────────────────────
            filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_outlined,
                              size: 48,
                              color: DocColors.textSecondary
                                  .withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No documents match your search'
                                : 'No documents uploaded yet',
                            style: const TextStyle(
                                color: DocColors.textSecondary,
                                fontSize: 14),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _uploadDocument,
                              icon: const Icon(Icons.upload_outlined,
                                  size: 16),
                              label: const Text('Upload first document'),
                              style: TextButton.styleFrom(
                                  foregroundColor: DocColors.teal),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: filtered
                        .map((doc) => _DocRow(
                              doc: doc,
                              formatDate: _formatDate,
                              onView: () => _viewDocument(doc),
                              onDelete: () => _deleteDocument(doc),
                              onToggleStar: () => _toggleStar(doc),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Sort button ──────────────────────────────────────────────────────────────
class _SortButton extends StatelessWidget {
  final String? sortBy;
  final bool sortAsc;
  final void Function(String, bool) onChanged;

  const _SortButton({
    required this.sortBy,
    required this.sortAsc,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Sort by',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == sortBy) {
          onChanged(value, !sortAsc);
        } else {
          onChanged(value, false);
        }
      },
      itemBuilder: (_) => [
        _sortItem('date', 'Date Uploaded', Icons.calendar_today_outlined),
        _sortItem('name', 'Document Name', Icons.sort_by_alpha_outlined),
        _sortItem('type', 'Document Type', Icons.category_outlined),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: DocColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DocColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort_rounded,
                size: 16, color: DocColors.textSecondary),
            const SizedBox(width: 4),
            Icon(
              sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: DocColors.teal,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
      String value, String label, IconData icon) {
    final isActive = sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isActive ? DocColors.teal : DocColors.textSecondary),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: isActive
                      ? DocColors.teal
                      : DocColors.textPrimary,
                  fontWeight: isActive
                      ? FontWeight.w600
                      : FontWeight.w400)),
          if (isActive) ...[
            const Spacer(),
            Icon(
              sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: DocColors.teal,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Table header cell ────────────────────────────────────────────────────────
class _DocHeaderCell extends StatelessWidget {
  final String label;
  const _DocHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DocColors.textSecondary));
  }
}

// ─── Document row ─────────────────────────────────────────────────────────────
class _DocRow extends StatefulWidget {
  final MedDocument doc;
  final String Function(DateTime) formatDate;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onToggleStar;

  const _DocRow({
    required this.doc,
    required this.formatDate,
    required this.onView,
    required this.onDelete,
    required this.onToggleStar,
  });

  @override
  State<_DocRow> createState() => _DocRowState();
}

class _DocRowState extends State<_DocRow> {
  bool _hovered = false;

  void _showMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (_) => _DocActionsMenu(
        doc: widget.doc,
        onView: widget.onView,
        onDelete: widget.onDelete,
        onToggleStar: widget.onToggleStar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onView,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered
              ? DocColors.tealLight.withOpacity(0.4)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Document name + icon
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: doc.type.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(doc.type.icon,
                          size: 18, color: doc.type.color),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  doc.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: DocColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (doc.isStarred) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded,
                                    size: 14,
                                    color: DocColors.amber),
                              ],
                            ],
                          ),
                          Text(
                            doc.fileExtension,
                            style: const TextStyle(
                                fontSize: 11,
                                color: DocColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Type badge
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: doc.type.bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    doc.type.displayName,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: doc.type.color),
                  ),
                ),
              ),

              // Patient
              Expanded(
                flex: 2,
                child: Text(doc.patientName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: DocColors.textSecondary)),
              ),

              // Date uploaded
              Expanded(
                flex: 2,
                child: Text(
                  widget.formatDate(doc.dateUploaded),
                  style: const TextStyle(
                      fontSize: 13, color: DocColors.textSecondary),
                ),
              ),

              // Uploaded by
              Expanded(
                flex: 2,
                child: Text(doc.uploadedBy,
                    style: const TextStyle(
                        fontSize: 13,
                        color: DocColors.textSecondary)),
              ),

              // File size
              Expanded(
                flex: 1,
                child: Text(doc.fileSize,
                    style: const TextStyle(
                        fontSize: 12,
                        color: DocColors.textSecondary)),
              ),

              // Actions
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => _showMenu(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DocColors.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: DocColors.border),
                    ),
                    child: const Icon(Icons.more_vert,
                        size: 16,
                        color: DocColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Document actions menu ────────────────────────────────────────────────────
class _DocActionsMenu extends StatelessWidget {
  final MedDocument doc;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onToggleStar;

  const _DocActionsMenu({
    required this.doc,
    required this.onView,
    required this.onDelete,
    required this.onToggleStar,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _DocAction(
        label: 'View Document',
        icon: Icons.visibility_outlined,
        onTap: () { Navigator.pop(context); onView(); },
      ),
      _DocAction(
        label: 'Download',
        icon: Icons.download_outlined,
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading ${doc.name}...'),
              backgroundColor: DocColors.teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
      _DocAction(
        label: doc.isStarred ? 'Remove Star' : 'Star Document',
        icon: doc.isStarred
            ? Icons.star_outline_rounded
            : Icons.star_rounded,
        onTap: () { Navigator.pop(context); onToggleStar(); },
      ),
      _DocAction(
        label: 'Copy Link',
        icon: Icons.link_outlined,
        onTap: () {
          Navigator.pop(context);
          Clipboard.setData(
              ClipboardData(text: 'https://doctorapp.com/docs/${doc.id}'));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Link copied to clipboard'),
              backgroundColor: DocColors.teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
      _DocAction(
        label: 'Delete',
        icon: Icons.delete_outline_rounded,
        onTap: () { Navigator.pop(context); onDelete(); },
        isDanger: true,
      ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: DocColors.textPrimary, width: 1.5),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: DocColors.textPrimary),
                    ),
                  ),
                ),
              ),
              ...List.generate(actions.length, (i) {
                final isLast = i == actions.length - 1;
                return Column(
                  children: [
                    _DocActionItem(action: actions[i]),
                    if (!isLast)
                      const Divider(
                          height: 1,
                          color: DocColors.border,
                          indent: 16,
                          endIndent: 16),
                  ],
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;
  const _DocAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });
}

class _DocActionItem extends StatefulWidget {
  final _DocAction action;
  const _DocActionItem({required this.action});

  @override
  State<_DocActionItem> createState() => _DocActionItemState();
}

class _DocActionItemState extends State<_DocActionItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.action.isDanger
        ? DocColors.danger
        : _hovered
            ? DocColors.teal
            : DocColors.textPrimary;
    final bg = widget.action.isDanger && _hovered
        ? DocColors.dangerLight
        : _hovered
            ? DocColors.tealLight
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: bg,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Icon(widget.action.icon, size: 17, color: color),
              const SizedBox(width: 12),
              Text(widget.action.label,
                  style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: _hovered
                          ? FontWeight.w500
                          : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Document viewer dialog ───────────────────────────────────────────────────
class _DocumentViewerDialog extends StatelessWidget {
  final MedDocument doc;
  const _DocumentViewerDialog({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 540,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: doc.type.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(doc.type.icon,
                        size: 20, color: doc.type.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: DocColors.textPrimary)),
                        Text(doc.fileExtension,
                            style: const TextStyle(
                                fontSize: 12,
                                color: DocColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: DocColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: DocColors.border),
              const SizedBox(height: 16),

              // Document details
              _ViewRow(label: 'Patient', value: doc.patientName),
              _ViewRow(label: 'Document Type', value: doc.type.displayName),
              _ViewRow(label: 'File Size', value: doc.fileSize),
              _ViewRow(label: 'File Format', value: doc.fileExtension),
              _ViewRow(
                label: 'Uploaded By',
                value: doc.uploadedBy,
              ),

              const SizedBox(height: 8),

              // Preview area
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: DocColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DocColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(doc.type.icon,
                        size: 48,
                        color: doc.type.color.withOpacity(0.4)),
                    const SizedBox(height: 8),
                    Text(
                      'Preview not available in demo mode.\nConnect to backend to load actual file.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12,
                          color: DocColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.download_outlined,
                          size: 16, color: Colors.white),
                      label: const Text('Download',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DocColors.teal,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ViewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: DocColors.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DocColors.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Upload Document Dialog ───────────────────────────────────────────────────
class _UploadDocumentDialog extends StatefulWidget {
  final String patientName;
  const _UploadDocumentDialog({required this.patientName});

  @override
  State<_UploadDocumentDialog> createState() =>
      _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<_UploadDocumentDialog> {
  final _nameCtrl = TextEditingController();
  DocType _type = DocType.labResult;
  String _uploadedBy = 'Dr Smith';
  String _fileExt = 'PDF';
  String _fileSize = '';
  bool _loading = false;

  final _doctors = ['Dr Smith', 'Dr Mokoena', 'Dr Patel', 'Dr Adams'];
  final _extensions = ['PDF', 'DOCX', 'DICOM', 'JPG', 'PNG', 'XLSX'];

  void _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _loading = true);

    // Simulate upload delay (replace with real file upload logic)
    await Future.delayed(const Duration(milliseconds: 800));

    final doc = MedDocument(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      type: _type,
      patientName: widget.patientName,
      dateUploaded: DateTime.now(),
      uploadedBy: _uploadedBy,
      fileSize: _fileSize.isNotEmpty ? _fileSize : '—',
      fileExtension: _fileExt,
    );

    if (mounted) Navigator.pop(context, doc);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DocColors.tealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.upload_file_outlined,
                        color: DocColors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Upload Document',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: DocColors.textSecondary, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Drop zone
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: DocColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: DocColors.teal.withOpacity(0.4),
                      style: BorderStyle.solid,
                      width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        color: DocColors.teal, size: 28),
                    const SizedBox(height: 6),
                    const Text('Drop file here or',
                        style: TextStyle(
                            fontSize: 13,
                            color: DocColors.textSecondary)),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          foregroundColor: DocColors.teal,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap),
                      child: const Text('browse files',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Document name
              _UploadField(
                label: 'Document Name *',
                child: TextField(
                  controller: _nameCtrl,
                  decoration: _inputDec('e.g. Blood Test Report'),
                ),
              ),

              const SizedBox(height: 12),

              // Type + extension row
              Row(
                children: [
                  Expanded(
                    child: _UploadField(
                      label: 'Document Type',
                      child: DropdownButtonFormField<DocType>(
                        initialValue: _type,
                        decoration: _inputDec(''),
                        isExpanded: true,
                        items: DocType.values
                            .where((t) => t != DocType.all)
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _type = v!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadField(
                      label: 'File Format',
                      child: DropdownButtonFormField<String>(
                        initialValue: _fileExt,
                        decoration: _inputDec(''),
                        isExpanded: true,
                        items: _extensions
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _fileExt = v!),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Uploaded by + file size row
              Row(
                children: [
                  Expanded(
                    child: _UploadField(
                      label: 'Uploaded By',
                      child: DropdownButtonFormField<String>(
                        initialValue: _uploadedBy,
                        decoration: _inputDec(''),
                        isExpanded: true,
                        items: _doctors
                            .map((d) => DropdownMenuItem(
                                value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _uploadedBy = v!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadField(
                      label: 'File Size (optional)',
                      child: TextField(
                        onChanged: (v) => _fileSize = v,
                        decoration: _inputDec('e.g. 2.4 MB'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DocColors.teal,
                    disabledBackgroundColor:
                        DocColors.teal.withOpacity(0.5),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Upload Document',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: DocColors.textSecondary, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DocColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: DocColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: DocColors.teal, width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      );
}

class _UploadField extends StatelessWidget {
  final String label;
  final Widget child;
  const _UploadField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DocColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
