import 'package:flutter/material.dart';

/// Dispensing Queue — Shows scripts currently being processed.
/// Filters: Accepted, In-Progress, Ready (the active dispensing pipeline).
class DispensingQueuePage extends StatefulWidget {
  const DispensingQueuePage({super.key});

  @override
  State<DispensingQueuePage> createState() => _DispensingQueuePageState();
}

class _DispensingQueuePageState extends State<DispensingQueuePage> {
  int _selectedTab = 0;

  static const Color _teal = Color(0xFF309CA3);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  final List<String> _tabs = ['All', 'Accepted', 'In-Progress', 'Ready'];

  final List<_QueueItem> _queue = [
    _QueueItem(patient: 'Maria Wilson', medication: 'Panado', doctor: 'Dr Sara Smith', time: '08:20 AM', status: 'Accepted'),
    _QueueItem(patient: 'Prince Mashumu', medication: 'Isotretinoin', doctor: 'Dr Sam Smith', time: '08:45 AM', status: 'In-Progress'),
    _QueueItem(patient: 'John Doe', medication: 'Amoxicillin', doctor: 'Dr Sara Smith', time: '09:10 AM', status: 'In-Progress'),
    _QueueItem(patient: 'Sarah Nkosi', medication: 'Metformin', doctor: 'Dr Sam Smith', time: '09:30 AM', status: 'Ready'),
    _QueueItem(patient: 'David Moyo', medication: 'Atorvastatin', doctor: 'Dr Sara Smith', time: '09:55 AM', status: 'Accepted'),
    _QueueItem(patient: 'Lisa Ndlovu', medication: 'Omeprazole', doctor: 'Dr Sam Smith', time: '10:15 AM', status: 'Accepted'),
  ];

  List<_QueueItem> get _filtered {
    if (_selectedTab == 0) return _queue;
    return _queue.where((q) => q.status == _tabs[_selectedTab]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F8),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 4),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dispensing Queue', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _textDark)),
              SizedBox(height: 4),
              Text('Scripts currently being prepared', style: TextStyle(fontSize: 14, color: _textMuted)),
            ],
          ),
        ),
        Text('${6} in queue', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textMuted)),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabs.length, (i) {
        final isActive = _selectedTab == i;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            onTap: () => setState(() => _selectedTab = i),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_tabs[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? Colors.white : _textMuted)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTable() {
    final data = _filtered;
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            Container(width: 11, color: const Color(0xFF6DD0D8)),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Patient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 3, child: Text('Medication', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 3, child: Text('Doctor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                        Expanded(flex: 2, child: Text('Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (_, i) => _buildRow(data[i]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_QueueItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x33309CA3), border: Border.all(color: _teal, width: 1)), child: const Icon(Icons.person, size: 14, color: _teal)),
            const SizedBox(width: 10),
            Expanded(child: Text(item.patient, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textDark), overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: 3, child: Text(item.medication, style: const TextStyle(fontSize: 13, color: _textDark))),
          Expanded(flex: 3, child: Text(item.doctor, style: const TextStyle(fontSize: 13, color: _textDark))),
          Expanded(flex: 2, child: Text(item.time, style: TextStyle(fontSize: 13, color: _textMuted))),
          Expanded(flex: 2, child: _StatusDot(status: item.status)),
          Expanded(flex: 2, child: InkWell(
            onTap: () => _advanceStatus(item),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFF6DD0D8), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.black.withValues(alpha: 0.1))),
              child: Text(_actionLabel(item.status), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          )),
        ],
      ),
    );
  }

  String _actionLabel(String status) {
    switch (status) {
      case 'Accepted': return 'Process';
      case 'In-Progress': return 'Mark Ready';
      case 'Ready': return 'Dispense';
      default: return 'View';
    }
  }

  void _advanceStatus(_QueueItem item) {
    String? next;
    switch (item.status) {
      case 'Accepted': next = 'In-Progress'; break;
      case 'In-Progress': next = 'Ready'; break;
      case 'Ready': next = 'Dispensed'; break;
    }
    if (next == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Move to "$next"?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('${item.patient} — ${item.medication}\nPatient will be notified.', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (next == 'Dispensed') {
                  _queue.remove(item);
                } else {
                  item.status = next!;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('✓ ${item.patient} — $next'),
                backgroundColor: _teal,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  Color get _color {
    switch (status) {
      case 'Accepted': return const Color(0xFF3B82F6);
      case 'In-Progress': return const Color(0xFFF97316);
      case 'Ready': return const Color(0xFF34D399);
      default: return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _color)),
      const SizedBox(width: 6),
      Text(status, style: TextStyle(fontSize: 12, color: _color)),
    ]);
  }
}

class _QueueItem {
  final String patient;
  final String medication;
  final String doctor;
  final String time;
  String status;

  _QueueItem({required this.patient, required this.medication, required this.doctor, required this.time, required this.status});
}
