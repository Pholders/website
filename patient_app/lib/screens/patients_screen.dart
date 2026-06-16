import 'package:flutter/material.dart';
import 'package:doctor_app/screens/patient_profile_screen.dart';

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display', // swap for your project font
        scaffoldBackgroundColor: const Color(0xFFF4FAFA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2EC4C4)),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

// ─── Colours ─────────────────────────────────────────────────────────────────
class AppColors {
  static const teal = Color(0xFF2EC4C4);
  static const tealLight = Color(0xFFE6F7F7);
  static const tealDark = Color(0xFF1A9E9E);
  static const amber = Color(0xFFF5A623);
  static const amberLight = Color(0xFFFFF3DC);
  static const stableGreen = Color(0xFF2EC4C4);
  static const stableBg = Color(0xFFD9F3F3);
  static const monitoredOrange = Color(0xFFF5A623);
  static const monitoredBg = Color(0xFFFFF0CE);
  static const sidebar = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4FAFA);
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A2B2B);
  static const textSecondary = Color(0xFF8A9E9E);
  static const border = Color(0xFFE8F0F0);
  static const alertBg = Color(0xFFFFF8E8);
  static const alertBorder = Color(0xFFF5A623);
  static const addButton = Color(0xFFF5A623);
}

// ─── Data model ──────────────────────────────────────────────────────────────
enum PatientStatus { stable, monitored, critical }

enum PatientCategory { outpatient, remoteCare, followUp }

class Patient {
  final String id;
  String name;
  String condition;
  String lastActivity;
  PatientStatus status;
  String priority;
  PatientCategory category;
  String? avatarInitials;

  Patient({
    required this.id,
    required this.name,
    required this.condition,
    required this.lastActivity,
    required this.status,
    required this.priority,
    required this.category,
    this.avatarInitials,
  });

  Patient copyWith({
    String? name,
    String? condition,
    String? lastActivity,
    PatientStatus? status,
    String? priority,
    PatientCategory? category,
  }) =>
      Patient(
        id: id,
        name: name ?? this.name,
        condition: condition ?? this.condition,
        lastActivity: lastActivity ?? this.lastActivity,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        avatarInitials: avatarInitials,
      );
}

// ─── Mock data ───────────────────────────────────────────────────────────────
List<Patient> _generateMockPatients() {
  final names = [
    'Maria Wilson', 'James Carter', 'Sophia Lee', 'Daniel Mokoena',
    'Aisha Patel', 'Luca Rossi', 'Emily Zhang', 'Noah Adams',
    'Fatima Hassan', 'Oliver Brown', 'Priya Nair', 'Ethan Dlamini',
  ];
  final conditions = [
    'Acne Treatment', 'Hypertension', 'Diabetes Type 2', 'Asthma',
    'Migraine', 'Eczema', 'Anxiety Disorder', 'Back Pain',
  ];
  final activities = ['2 hours ago', '30 min ago', '1 day ago', '3 hours ago', 'Just now'];
  final categories = PatientCategory.values;
  final statuses = PatientStatus.values;
  final priorities = ['Low', 'Medium', 'High'];

  return List.generate(names.length, (i) {
    return Patient(
      id: 'P${1000 + i}',
      name: names[i],
      condition: conditions[i % conditions.length],
      lastActivity: activities[i % activities.length],
      status: statuses[i % statuses.length],
      priority: priorities[i % priorities.length],
      category: categories[i % categories.length],
      avatarInitials: names[i].split(' ').map((w) => w[0]).join(),
    );
  });
}

// ─── App shell with sidebar ───────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedNav = 1; // Patients is selected
  Patient? _selectedPatient; // null = show patients list

  final _navItems = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Patients'),
    _NavItem(icon: Icons.medication_outlined, label: 'Prescriptions'),
    _NavItem(icon: Icons.calendar_month_outlined, label: 'Appointments'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Billing & Payments'),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings'),
    _NavItem(icon: Icons.info_outline_rounded, label: 'Help & Support'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            items: _navItems,
            selected: _selectedNav,
            onSelect: (i) => setState(() {
              _selectedNav = i;
              _selectedPatient = null; // go back to list on nav change
            }),
          ),
          Expanded(
            child: _selectedPatient != null
                ? PatientProfileScreen(
                    patient: _selectedPatient!,
                    onBack: () => setState(() => _selectedPatient = null),
                  )
                : PatientsScreen(
                    onPatientTap: (p) => setState(() => _selectedPatient = p),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  const _Sidebar({required this.items, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.teal, width: 2),
                  ),
                  child: const Icon(Icons.favorite_border_rounded,
                      color: AppColors.teal, size: 22),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final active = i == selected;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: active ? AppColors.tealLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(items[i].icon,
                            size: 20,
                            color: active ? AppColors.teal : AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? AppColors.teal : AppColors.textPrimary,
                          ),
                        ),
                        if (active)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Membership card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Activate Membership',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Check your benefits',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.teal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Check now',
                        style: TextStyle(color: AppColors.teal, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

          // Doctor profile
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.tealLight,
                    child: const Icon(Icons.person, color: AppColors.teal, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Dr. Sam Smith',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const Icon(Icons.logout_rounded, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Patients screen ─────────────────────────────────────────────────────────
class PatientsScreen extends StatefulWidget {
  final ValueChanged<Patient> onPatientTap;
  const PatientsScreen({super.key, required this.onPatientTap});
  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final List<Patient> _allPatients = _generateMockPatients();
  int _tabIndex = 0; // 0=All, 1=Outpatients, 2=Remote care, 3=Follow-up
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<Patient> get _filtered {
    var list = _allPatients;
    if (_tabIndex == 1) list = list.where((p) => p.category == PatientCategory.outpatient).toList();
    if (_tabIndex == 2) list = list.where((p) => p.category == PatientCategory.remoteCare).toList();
    if (_tabIndex == 3) list = list.where((p) => p.category == PatientCategory.followUp).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          p.condition.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _addPatient() async {
    final result = await showDialog<Patient>(
      context: context,
      builder: (_) => const _PatientFormDialog(),
    );
    if (result != null) setState(() => _allPatients.add(result));
  }

  void _editPatient(Patient patient) async {
    final result = await showDialog<Patient>(
      context: context,
      builder: (_) => _PatientFormDialog(existing: patient),
    );
    if (result != null) {
      setState(() {
        final i = _allPatients.indexWhere((p) => p.id == patient.id);
        if (i != -1) _allPatients[i] = result;
      });
    }
  }

  void _deletePatient(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Patient'),
        content: Text('Remove ${patient.name} from your list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _allPatients.removeWhere((p) => p.id == patient.id));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(searchController: _searchController, onSearch: (q) => setState(() => _searchQuery = q)),
        Expanded(
          child: Container(
            color: AppColors.bg,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(total: _allPatients.length, onAdd: _addPatient),
                  const SizedBox(height: 4),
                  const Text('Stay organised and on track with calendar',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  _AlertBanner(),
                  const SizedBox(height: 16),
                  _TabBar(
                    selected: _tabIndex,
                    onSelect: (i) => setState(() => _tabIndex = i),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _PatientTable(
                      patients: _filtered,
                      onEdit: _editPatient,
                      onDelete: _deletePatient,
                      onRowTap: widget.onPatientTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  const _TopBar({required this.searchController, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Text('Pholders ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          const Text('Patients', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAFA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search for patient name, ID, or prescription...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                onPressed: () {},
              ),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Header row ──────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onAdd;
  const _Header({required this.total, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Patients',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const Spacer(),
        Text('Total: $total',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 12),
        // Filter icon button
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 10),
        // Add button
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.addButton,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

// ─── Alert banner ─────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.alertBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.alertBorder.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 18),
          const SizedBox(width: 8),
          const Text('Prince Mashumu  ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const Text('Acne Treatment  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const Text('2 hours ago  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.amberLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Symptom reported',
                style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Tab bar ─────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _TabBar({required this.selected, required this.onSelect});

  static const _labels = ['All', 'Outpatients', 'Remote care', 'Follow-up'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final active = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.teal : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: active ? AppColors.teal : AppColors.border),
            ),
            child: Text(
              _labels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Patient table ────────────────────────────────────────────────────────────
class _PatientTable extends StatelessWidget {
  final List<Patient> patients;
  final ValueChanged<Patient> onEdit;
  final ValueChanged<Patient> onDelete;
  final ValueChanged<Patient> onRowTap;

  const _PatientTable({
    required this.patients,
    required this.onEdit,
    required this.onDelete,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _HeaderCell('Name')),
                Expanded(flex: 3, child: _HeaderCell('Condition')),
                Expanded(flex: 2, child: _HeaderCell('Last activity')),
                Expanded(flex: 2, child: _HeaderCell('Status')),
                Expanded(flex: 2, child: _HeaderCell('Priority')),
                Expanded(flex: 2, child: _HeaderCell('Action')),
              ],
            ),
          ),

          // Rows
          Expanded(
            child: patients.isEmpty
                ? const Center(
                    child: Text('No patients found',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    itemCount: patients.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (ctx, i) => _PatientRow(
                      patient: patients[i],
                      onEdit: () => onEdit(patients[i]),
                      onDelete: () => onDelete(patients[i]),
                      onTap: () => onRowTap(patients[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
}

// ─── Patient row ──────────────────────────────────────────────────────────────
class _PatientRow extends StatefulWidget {
  final Patient patient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _PatientRow({
    required this.patient,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_PatientRow> createState() => _PatientRowState();
}

class _PatientRowState extends State<_PatientRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered ? AppColors.tealLight.withOpacity(0.4) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
            // Name + avatar
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.tealLight,
                    child: Text(p.avatarInitials ?? '?',
                        style: const TextStyle(
                            color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(p.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),

            // Condition
            Expanded(
              flex: 3,
              child: Text(p.condition,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),

            // Last activity
            Expanded(
              flex: 2,
              child: Text(p.lastActivity,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),

            // Status badge
            Expanded(flex: 2, child: _StatusBadge(status: p.status)),

            // Priority
            Expanded(
              flex: 2,
              child: Text(p.priority,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: p.priority == 'High'
                          ? Colors.red.shade400
                          : p.priority == 'Medium'
                              ? AppColors.amber
                              : AppColors.teal)),
            ),

            // Actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _ActionBtn(icon: Icons.edit_outlined, onTap: widget.onEdit),
                  const SizedBox(width: 6),
                  _ActionBtn(icon: Icons.delete_outline, onTap: widget.onDelete),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.more_vert,
                    onTap: () => _showPatientActionsMenu(context, widget.patient),
                  ),
                ],
              ),
            ),
          ],        // closes Row children
          ),        // closes Row
        ),          // closes AnimatedContainer
      ),            // closes GestureDetector
    );              // closes MouseRegion
  }
}

// ─── Patient actions menu modal ───────────────────────────────────────────────
void _showPatientActionsMenu(BuildContext context, Patient patient) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.18),
    builder: (_) => _PatientActionsMenu(patient: patient),
  );
}

class _PatientActionsMenu extends StatelessWidget {
  final Patient patient;
  const _PatientActionsMenu({required this.patient});

  static const _actions = [
    _PatientAction(label: 'View Patient Profile', icon: Icons.person_outline_rounded),
    _PatientAction(label: 'Create Prescription', icon: Icons.medication_outlined),
    _PatientAction(label: 'Send Medication Reminder', icon: Icons.notifications_outlined),
    _PatientAction(label: 'Send Safety Alert', icon: Icons.warning_amber_outlined),
    _PatientAction(label: 'Notify Prescription Ready', icon: Icons.check_circle_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 280,
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
              // Close button row
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
                        border: Border.all(color: AppColors.textPrimary, width: 1.5),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),

              // Action items
              ...List.generate(_actions.length, (i) {
                final action = _actions[i];
                final isLast = i == _actions.length - 1;
                return Column(
                  children: [
                    _ActionMenuItem(
                      label: action.label,
                      icon: action.icon,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: wire up to your backend actions
                      },
                    ),
                    if (!isLast)
                      const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
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

class _PatientAction {
  final String label;
  final IconData icon;
  const _PatientAction({required this.label, required this.icon});
}

class _ActionMenuItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionMenuItem({required this.label, required this.icon, required this.onTap});

  @override
  State<_ActionMenuItem> createState() => _ActionMenuItemState();
}

class _ActionMenuItemState extends State<_ActionMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          color: _hovered ? AppColors.tealLight : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(widget.icon, size: 17, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: _hovered ? AppColors.teal : AppColors.textPrimary,
                  fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final PatientStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, dot, text;
    String label;
    switch (status) {
      case PatientStatus.stable:
        bg = AppColors.stableBg; dot = AppColors.stableGreen; text = AppColors.stableGreen;
        label = 'Stable';
      case PatientStatus.monitored:
        bg = AppColors.monitoredBg; dot = AppColors.monitoredOrange; text = AppColors.monitoredOrange;
        label = 'Monitored';
      case PatientStatus.critical:
        bg = Colors.red.shade50; dot = Colors.red.shade400; text = Colors.red.shade400;
        label = 'Critical';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAFA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Add / Edit patient dialog ────────────────────────────────────────────────
class _PatientFormDialog extends StatefulWidget {
  final Patient? existing;
  const _PatientFormDialog({this.existing});

  @override
  State<_PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends State<_PatientFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _conditionCtrl;
  late PatientStatus _status;
  late String _priority;
  late PatientCategory _category;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _conditionCtrl = TextEditingController(text: p?.condition ?? '');
    _status = p?.status ?? PatientStatus.stable;
    _priority = p?.priority ?? 'Low';
    _category = p?.category ?? PatientCategory.outpatient;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.isEmpty || _conditionCtrl.text.isEmpty) return;
    final result = Patient(
      id: widget.existing?.id ?? 'P${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      condition: _conditionCtrl.text.trim(),
      lastActivity: 'Just now',
      status: _status,
      priority: _priority,
      category: _category,
      avatarInitials: _nameCtrl.text.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').join(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEdit ? 'Edit Patient' : 'Add New Patient',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              _FormField(label: 'Full Name', controller: _nameCtrl, hint: 'e.g. Maria Wilson'),
              const SizedBox(height: 14),
              _FormField(label: 'Condition', controller: _conditionCtrl, hint: 'e.g. Acne Treatment'),
              const SizedBox(height: 14),

              // Status
              const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PatientStatus>(
                value: _status,
                decoration: _dropDecoration(),
                items: PatientStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.name[0].toUpperCase() + s.name.substring(1)));
                }).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 14),

              // Priority
              const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: _dropDecoration(),
                items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 14),

              // Category
              const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<PatientCategory>(
                value: _category,
                decoration: _dropDecoration(),
                items: const [
                  DropdownMenuItem(value: PatientCategory.outpatient, child: Text('Outpatient')),
                  DropdownMenuItem(value: PatientCategory.remoteCare, child: Text('Remote Care')),
                  DropdownMenuItem(value: PatientCategory.followUp, child: Text('Follow-up')),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_isEdit ? 'Save Changes' : 'Add Patient',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

  InputDecoration _dropDecoration() => InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      );
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _FormField({required this.label, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
          ),
        ),
      ],
    );
  }
}