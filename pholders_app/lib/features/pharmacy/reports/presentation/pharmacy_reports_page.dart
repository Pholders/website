import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';

/// PharmacyReportsPage â€” displays pharmacy analytics and insights.
class PharmacyReportsPage extends StatefulWidget {
  const PharmacyReportsPage({super.key});

  @override
  State<PharmacyReportsPage> createState() => _PharmacyReportsPageState();
}

class _PharmacyReportsPageState extends State<PharmacyReportsPage> {
  static const Color _accent = AppTheme.sidebarActiveItem;
  static const Color _headerBackground = Color(0xFFE8F8F8);
  static const Color _headerTextDark = Color(0xFF1F2937);
  static const Color _headerTextMuted = Color(0xFF6B7280);
  static const List<_InventoryMedication> _inventoryMedications = [
    _InventoryMedication(
      medicationId: 'MED-001',
      medicationName: 'Paracetamol 500mg',
      sku: 'SKU-PAR-500',
      quantity: 450,
      reorderLevel: 100,
      unitPrice: 'R2.50',
      status: 'In Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-002',
      medicationName: 'Amoxicillin 250mg',
      sku: 'SKU-AMX-250',
      quantity: 85,
      reorderLevel: 100,
      unitPrice: 'R4.20',
      status: 'Low Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-003',
      medicationName: 'Ibuprofen 200mg',
      sku: 'SKU-IBU-200',
      quantity: 0,
      reorderLevel: 80,
      unitPrice: 'R1.80',
      status: 'Out of Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-004',
      medicationName: 'Aspirin 100mg',
      sku: 'SKU-ASP-100',
      quantity: 320,
      reorderLevel: 100,
      unitPrice: 'R3.15',
      status: 'In Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-005',
      medicationName: 'Lisinopril 10mg',
      sku: 'SKU-LIS-10',
      quantity: 45,
      reorderLevel: 100,
      unitPrice: 'R5.90',
      status: 'Low Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-006',
      medicationName: 'Atorvastatin 20mg',
      sku: 'SKU-ATO-20',
      quantity: 215,
      reorderLevel: 100,
      unitPrice: 'R6.40',
      status: 'In Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-007',
      medicationName: 'Metformin 500mg',
      sku: 'SKU-MET-500',
      quantity: 0,
      reorderLevel: 150,
      unitPrice: 'R2.75',
      status: 'Out of Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-008',
      medicationName: 'Omeprazole 20mg',
      sku: 'SKU-OMP-20',
      quantity: 60,
      reorderLevel: 100,
      unitPrice: 'R4.60',
      status: 'Low Stock',
    ),
    _InventoryMedication(
      medicationId: 'MED-009',
      medicationName: 'Cetirizine 10mg',
      sku: 'SKU-CET-10',
      quantity: 580,
      reorderLevel: 200,
      unitPrice: 'R3.20',
      status: 'In Stock',
    ),
  ];

  String selectedPeriod = 'month'; // week, month, year
  Map<String, dynamic>? selectedTransaction; // Track selected order details
  bool viewingAllTransactions = false; // Track if viewing all transactions
  bool showingInventoryDetails = false;
  String? selectedInventoryStatus;

  @override
  Widget build(BuildContext context) {
    // Show all transactions if requested
    if (viewingAllTransactions) {
      return _buildAllTransactionsPage();
    }

    // Show order details if a transaction is selected
    if (selectedTransaction != null) {
      return _buildOrderDetailsPage();
    }

    // Otherwise, show reports page
    return _buildReportsPage();
  }

  Widget _buildReportsPage() {
    final context = this.context;
    final isMobile = MediaQuery.of(context).size.width < AppTheme.mobileBreakpoint;
    final isTablet = MediaQuery.of(context).size.width < AppTheme.desktopBreakpoint;

    return _buildFixedHeaderPage(
      header: _buildReportsHeader(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPICards(isMobile, isTablet),
          SizedBox(height: AppTheme.spacingLg),
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildSalesTrendCard(),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: _buildTopMedicationsCard(),
                ),
              ],
            )
          else ...[
            _buildSalesTrendCard(),
            SizedBox(height: AppTheme.spacingMd),
            _buildTopMedicationsCard(),
          ],
          SizedBox(height: AppTheme.spacingLg),
          _buildInventoryStatusCard(),
          SizedBox(height: AppTheme.spacingLg),
          _buildRecentTransactionsCard(),
        ],
      ),
    );
  }

  Widget _buildReportsHeader(BuildContext context) {
    return _buildInventoryStyledHeader(context);
  }

  Widget _buildOrderDetailsPage() {
    final tx = selectedTransaction!;
    final status = tx['status'] as String;
    final statusColor = tx['statusColor'] as Color;

    return _buildPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'Order Details',
            subtitle: tx['orderId'] as String,
            leading: _buildBackButton(() {
              setState(() {
                selectedTransaction = null;
              });
            }),
          ),
          SizedBox(height: AppTheme.spacingLg),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['orderId'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Wrap(
                  spacing: AppTheme.spacingMd,
                  runSpacing: AppTheme.spacingMd,
                  children: [
                    _buildMetricPill('Status', status, statusColor),
                    _buildMetricPill('Amount', tx['amount'] as String, AppTheme.textPrimary),
                    _buildMetricPill('Updated', tx['timestamp'] as String, _accent),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingLg),
          _buildSectionLabel('Order Summary'),
          SizedBox(height: AppTheme.spacingMd),
          _buildSectionCard(
            child: Column(
              children: [
                _buildDetailRow('Order ID', tx['orderId'] as String),
                Divider(color: AppTheme.divider, height: AppTheme.spacingLg),
                _buildDetailRow('Date', tx['timestamp'] as String),
                Divider(color: AppTheme.divider, height: AppTheme.spacingLg),
                _buildDetailRow('Amount', tx['amount'] as String),
                Divider(color: AppTheme.divider, height: AppTheme.spacingLg),
                _buildDetailRow('Status', status),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingLg),
          _buildSectionLabel('Items (3)'),
          SizedBox(height: AppTheme.spacingMd),
          ...List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? AppTheme.spacingSm : 0),
              child: _buildSectionCard(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medication ${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXs),
                          Text(
                            '${150 - index * 10} units @ R${50 + index * 5}.00',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'R ${(150 - index * 10) * (50 + index * 5)}.00',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return _buildPageHeader(
      title: 'Reports & Analytics',
      subtitle: 'Pharmacy performance and insights',
      trailing: _buildPeriodSelector(context),
    );
  }

  Widget _buildKPICards(bool isMobile, bool isTablet) {
    final kpis = [
      (
        'Total Revenue',
        'R 45,320.50',
        'Revenue from fulfilled pharmacy orders',
        AppTheme.primary,
        Icons.payments_rounded,
        '+12.5%',
      ),
      (
        'Total Orders',
        '1,240',
        'Orders processed in the selected period',
        AppTheme.secondary,
        Icons.receipt_long_rounded,
        '+8.2%',
      ),
      (
        'Avg Order Value',
        'R 36.55',
        'Average basket size per completed order',
        const Color(0xFF309CA3),
        Icons.calculate_rounded,
        '+4.1%',
      ),
      (
        'Top Medication',
        'Paracetamol',
        'Most dispensed item across the current window',
        AppTheme.warning,
        Icons.local_hospital_rounded,
        '-2.3%',
      ),
    ];

    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spacingMd,
      crossAxisSpacing: AppTheme.spacingMd,
      childAspectRatio: isMobile ? 1.65 : (isTablet ? 1.32 : 1.12),
      children: kpis.map((kpi) {
        return _buildModernKPICard(
          title: kpi.$1,
          value: kpi.$2,
          subtitle: kpi.$3,
          color: kpi.$4,
          icon: kpi.$5,
          change: kpi.$6,
        );
      }).toList(),
    );
  }

  Widget _buildModernKPICard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String change,
  }) {
    final isPositive = !change.startsWith('-');
    final trendColor = isPositive ? AppTheme.secondary : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 14,
                  color: trendColor,
                ),
                SizedBox(width: AppTheme.spacingXs),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: trendColor,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    'vs previous period',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendCard() {
    return _buildSectionCard(
      height: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales Trend',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 12, color: _accent),
                    SizedBox(width: 4),
                    Text(
                      '+12.5%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedTrendBar(0.6, 'Mon', 1),
                _buildAnimatedTrendBar(0.8, 'Tue', 2),
                _buildAnimatedTrendBar(0.7, 'Wed', 3),
                _buildAnimatedTrendBar(0.9, 'Thu', 4),
                _buildAnimatedTrendBar(0.85, 'Fri', 5),
                _buildAnimatedTrendBar(0.95, 'Sat', 6),
                _buildAnimatedTrendBar(0.75, 'Sun', 7),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTrendBar(double height, String label, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              height: height * 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.55)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopMedicationsCard() {
    final topMeds = [
      ('Paracetamol 500mg', 324, AppTheme.primary),
      ('Amoxicillin 250mg', 287, AppTheme.secondary),
      ('Ibuprofen 400mg', 256, AppTheme.warning),
      ('Metformin 500mg', 198, Color(0xFF309CA3)),
      ('Omeprazole 20mg', 165, AppTheme.error),
    ];

    return _buildSectionCard(
      height: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Medications',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: topMeds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final med = entry.value;
                  final maxValue = topMeds.first.$2;
                  final percentage = med.$2 / maxValue;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < topMeds.length - 1 ? AppTheme.spacingSm : 0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: med.$3.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: med.$3,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.$1,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.divider,
                                  valueColor: AlwaysStoppedAnimation(med.$3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Text(
                          '${med.$2}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatusCard() {
    final statuses = [
      ('In Stock', 156, AppTheme.secondary),
      ('Low Stock', 24, AppTheme.warning),
      ('Out of Stock', 8, AppTheme.error),
    ];
    final total = statuses.fold<int>(0, (sum, s) => sum + s.$2);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      showingInventoryDetails
                          ? 'Operational detail for stock health and replenishment.'
                          : 'Snapshot of catalogue health and reorder pressure.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    showingInventoryDetails = !showingInventoryDetails;
                  });
                },
                icon: Icon(
                  showingInventoryDetails
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
                label: Text(showingInventoryDetails ? 'Hide details' : 'View more details'),
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x14309CA3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _accent,
                      ),
                    ),
                    Text(
                      'tracked items',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingLg),
          if (showingInventoryDetails)
            _buildInventoryDetailsView(context, statuses, total)
          else
            _buildInventorySummaryView(context, statuses, total),
          SizedBox(height: AppTheme.spacingLg),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '32 items need attention across low-stock and out-of-stock categories.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryView(
    BuildContext context,
    List<(String, int, Color)> statuses,
    int total,
  ) {
    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final percentage = status.$2 / total;
        final percentageLabel = (percentage * 100).toStringAsFixed(1);

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == statuses.length - 1 ? 0 : AppTheme.spacingMd,
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedInventoryStatus = status.$1;
                showingInventoryDetails = true;
              });
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: status.$3.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: status.$3.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: status.$3.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${status.$2}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: status.$3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                status.$1,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '$percentageLabel%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: status.$3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingSm),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: status.$3,
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        Text(
                          _inventoryStatusDescription(status.$1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(status.$3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInventoryDetailsView(
    BuildContext context,
    List<(String, int, Color)> statuses,
    int total,
  ) {
    final activeStatus = selectedInventoryStatus ?? statuses.first.$1;
    final matchingMedications = _inventoryMedications
        .where((medication) => medication.status == activeStatus)
        .toList();

    return Column(
      children: [
        Row(
          children: List.generate(statuses.length, (index) {
            final status = statuses[index];
            final percentage = (status.$2 / total * 100).toStringAsFixed(0);
            final isSelected = status.$1 == activeStatus;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == statuses.length - 1 ? 0 : AppTheme.spacingMd,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedInventoryStatus = status.$1;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? status.$3.withOpacity(0.14)
                          : status.$3.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: isSelected
                            ? status.$3.withOpacity(0.45)
                            : status.$3.withOpacity(0.12),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.$1,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        Text(
                          '${status.$2}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: status.$3,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        Text(
                          '$percentage% of tracked items',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: AppTheme.spacingLg),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: [
              _buildInventoryDetailRow(
                context,
                label: _selectedInventorySecondaryLabel(activeStatus),
                value: _selectedInventorySecondaryValue(activeStatus),
                valueColor: _selectedInventorySecondaryColor(activeStatus),
              ),
              Divider(color: AppTheme.divider, height: AppTheme.spacingLg),
              _buildInventoryDetailRow(
                context,
                label: _selectedInventoryTertiaryLabel(activeStatus),
                value: _selectedInventoryTertiaryValue(activeStatus),
                valueColor: _selectedInventoryTertiaryColor(activeStatus),
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacingLg),
        _buildInventoryMedicationList(context, activeStatus, matchingMedications),
      ],
    );
  }

  Widget _buildInventoryMedicationList(
    BuildContext context,
    String activeStatus,
    List<_InventoryMedication> medications,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$activeStatus Medications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      '${medications.length} matching medication${medications.length == 1 ? '' : 's'} in this status.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          ...List.generate(medications.length, (index) {
            final medication = medications[index];
            return Column(
              children: [
                if (index > 0) Divider(color: AppTheme.divider, height: AppTheme.spacingLg),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication.medicationName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingXs),
                            Text(
                              '${medication.medicationId} Â· ${medication.sku}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildInventoryListValue(
                          context,
                          label: 'Qty',
                          value: '${medication.quantity}',
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildInventoryListValue(
                          context,
                          label: 'Reorder',
                          value: '${medication.reorderLevel}',
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildInventoryListValue(
                          context,
                          label: 'Unit Price',
                          value: medication.unitPrice,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInventoryListValue(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _inventoryStatusDescription(String status) {
    switch (status) {
      case 'In Stock':
        return 'Healthy availability across the active medication catalogue.';
      case 'Low Stock':
        return 'These items are approaching reorder thresholds soon.';
      case 'Out of Stock':
        return 'Immediate replenishment is required before dispensing.';
      default:
        return '';
    }
  }

  Color _selectedInventoryPrimaryColor(String status) {
    switch (status) {
      case 'Out of Stock':
        return AppTheme.error;
      case 'Low Stock':
        return AppTheme.warning;
      case 'In Stock':
      default:
        return AppTheme.secondary;
    }
  }

  String _selectedInventorySecondaryLabel(String status) {
    switch (status) {
      case 'Out of Stock':
        return 'Orders blocked by current shortage';
      case 'Low Stock':
        return 'Projected reorder actions this week';
      case 'In Stock':
      default:
        return 'Coverage above reorder threshold';
    }
  }

  String _selectedInventorySecondaryValue(String status) {
    switch (status) {
      case 'Out of Stock':
        return '5 urgent orders';
      case 'Low Stock':
        return '11 scheduled';
      case 'In Stock':
      default:
        return '92% healthy';
    }
  }

  Color _selectedInventorySecondaryColor(String status) {
    switch (status) {
      case 'Out of Stock':
        return AppTheme.warning;
      case 'Low Stock':
        return _accent;
      case 'In Stock':
      default:
        return AppTheme.secondary;
    }
  }

  String _selectedInventoryTertiaryLabel(String status) {
    switch (status) {
      case 'Out of Stock':
        return 'Next inbound replenishment';
      case 'Low Stock':
        return 'Average days until depletion';
      case 'In Stock':
      default:
        return 'Average stock depth across active items';
    }
  }

  String _selectedInventoryTertiaryValue(String status) {
    switch (status) {
      case 'Out of Stock':
        return 'Tomorrow, 09:00';
      case 'Low Stock':
        return '4.5 days';
      case 'In Stock':
      default:
        return '18.2 days';
    }
  }

  Color _selectedInventoryTertiaryColor(String status) {
    switch (status) {
      case 'Out of Stock':
        return _accent;
      case 'Low Stock':
        return AppTheme.warning;
      case 'In Stock':
      default:
        return _accent;
    }
  }

  Widget _buildRecentTransactionsCard() {
    final transactions = [
      ('ORD-2024-5432', 'R 1,240.50', 'Completed', AppTheme.secondary, '2 hours ago'),
      ('ORD-2024-5431', 'R 890.25', 'Completed', AppTheme.secondary, '5 hours ago'),
      ('ORD-2024-5430', 'R 2,150.00', 'Processing', AppTheme.warning, '1 day ago'),
      ('ORD-2024-5429', 'R 567.80', 'Completed', AppTheme.secondary, '2 days ago'),
      ('ORD-2024-5428', 'R 3,200.00', 'Pending', AppTheme.warning, '3 days ago'),
      ('ORD-2024-5427', 'R 1,890.30', 'Completed', AppTheme.secondary, '4 days ago'),
      ('ORD-2024-5426', 'R 2,345.65', 'Completed', AppTheme.secondary, '5 days ago'),
      ('ORD-2024-5425', 'R 567.20', 'Pending', AppTheme.warning, '6 days ago'),
    ];

    return _buildSectionCard(
      height: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    viewingAllTransactions = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: _accent.withOpacity(0.24),
                    ),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: transactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;

                  return Column(
                    children: [
                      if (index > 0)
                        Divider(color: AppTheme.divider, height: AppTheme.spacingMd),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTransaction = {
                              'orderId': tx.$1,
                              'amount': tx.$2,
                              'status': tx.$3,
                              'statusColor': tx.$4,
                              'timestamp': tx.$5,
                            };
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.$1,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      tx.$5,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tx.$2,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tx.$4.withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      tx.$3,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: tx.$4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTransactionsPage() {
    final transactions = [
      ('ORD-2024-5432', 'R 1,240.50', 'Completed', AppTheme.secondary, '2 hours ago'),
      ('ORD-2024-5431', 'R 890.25', 'Completed', AppTheme.secondary, '5 hours ago'),
      ('ORD-2024-5430', 'R 2,150.00', 'Processing', AppTheme.warning, '1 day ago'),
      ('ORD-2024-5429', 'R 567.80', 'Completed', AppTheme.secondary, '2 days ago'),
      ('ORD-2024-5428', 'R 3,200.00', 'Pending', AppTheme.warning, '3 days ago'),
      ('ORD-2024-5427', 'R 1,890.30', 'Completed', AppTheme.secondary, '4 days ago'),
      ('ORD-2024-5426', 'R 2,345.65', 'Completed', AppTheme.secondary, '5 days ago'),
      ('ORD-2024-5425', 'R 567.20', 'Pending', AppTheme.warning, '6 days ago'),
      ('ORD-2024-5424', 'R 1,450.00', 'Completed', AppTheme.secondary, '1 week ago'),
      ('ORD-2024-5423', 'R 2,890.50', 'Processing', AppTheme.warning, '1 week ago'),
      ('ORD-2024-5422', 'R 567.99', 'Completed', AppTheme.secondary, '2 weeks ago'),
      ('ORD-2024-5421', 'R 3,120.00', 'Completed', AppTheme.secondary, '2 weeks ago'),
    ];

    return _buildPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            title: 'All Transactions',
            subtitle: '${transactions.length} records in the current reporting period',
            leading: _buildBackButton(() {
              setState(() {
                viewingAllTransactions = false;
              });
            }),
          ),
          SizedBox(height: AppTheme.spacingLg),
          ...List.generate(transactions.length, (index) {
            final tx = transactions[index];
            final statusColor = tx.$4 as Color;
            final status = tx.$3 as String;

            return Padding(
              padding: EdgeInsets.only(bottom: index < transactions.length - 1 ? AppTheme.spacingSm : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    viewingAllTransactions = false;
                    selectedTransaction = {
                      'orderId': tx.$1,
                      'amount': tx.$2,
                      'status': tx.$3,
                      'statusColor': tx.$4,
                      'timestamp': tx.$5,
                    };
                  });
                },
                child: _buildSectionCard(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.$1 as String,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingXs),
                            Text(
                              tx.$5 as String,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingMd),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            tx.$2 as String,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
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
          }),
        ],
      ),
    );
  }

  Widget _buildPageScaffold({required Widget child}) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedHeaderPage({
    required Widget header,
    required Widget child,
  }) {
    final headerHeight = _reportsHeaderHeight(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  headerHeight + AppTheme.spacingLg,
                  AppTheme.spacingLg,
                  AppTheme.spacingLg,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                  child: child,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: double.infinity,
                height: headerHeight,
                child: header,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _reportsHeaderHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 860) {
      return 204;
    }

    if (width >= AppTheme.mobileBreakpoint) {
      return 228;
    }

    return 276;
  }

  Widget _buildPageHeader({
    required String title,
    required String subtitle,
    Widget? leading,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppTheme.spacingMd,
        spacing: AppTheme.spacingMd,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                SizedBox(width: AppTheme.spacingMd),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    double? height,
    EdgeInsets padding = const EdgeInsets.all(AppTheme.spacingMd),
  }) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final periods = [
      ('week', '7D'),
      ('month', '30D'),
      ('year', '12M'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: const Color(0xFFD1F5F5)),
      ),
      child: Wrap(
        spacing: 4,
        children: periods.map((period) {
          final isSelected = selectedPeriod == period.$1;
          return InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            onTap: () {
              setState(() {
                selectedPeriod = period.$1;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Text(
                period.$2,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInventoryStyledHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidePanel = constraints.maxWidth >= 860;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            color: _headerBackground,
            border: Border(
              bottom: BorderSide(color: Color(0xFFD1F5F5)),
            ),
          ),
          child: showSidePanel
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildHeaderSummaryBlock(context)),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 320,
                      child: _buildHeaderControlPanel(context),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSummaryBlock(context),
                    const SizedBox(height: 16),
                    _buildHeaderControlPanel(context),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeaderSummaryBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD1F5F5)),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: _accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insights, color: _accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Updated today',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _headerTextDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Reports',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _headerTextDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track revenue, stock movement, and transaction performance',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _headerTextMuted,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD1F5F5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF34A853),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Revenue remains ahead of fulfilment volume this period.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _headerTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderControlPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD1F5F5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0x14309CA3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: _accent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report window',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _headerTextMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedPeriodLabel(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _headerTextDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderActionIcon(
                    context,
                    icon: Icons.download_rounded,
                    tooltip: 'Download report',
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderActionIcon(
                    context,
                    icon: Icons.ios_share_rounded,
                    tooltip: 'Export report',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: _buildPeriodSelector(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionIcon(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1F5F5)),
        ),
        child: Icon(icon, color: _accent, size: 16),
      ),
    );
  }

  String _selectedPeriodLabel() {
    switch (selectedPeriod) {
      case 'week':
        return 'Last 7 days';
      case 'year':
        return 'Last 12 months';
      case 'month':
      default:
        return 'Last 30 days';
    }
  }

  Widget _buildInsightsBanner(
    BuildContext context, {
    bool includeFilters = false,
    bool fullWidth = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSideFilters = includeFilters && constraints.maxWidth >= 860;

        return Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _accent.withOpacity(0.78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: fullWidth
                ? BorderRadius.zero
                : BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: showSideFilters
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildHeaderSummary(context)),
                    SizedBox(width: AppTheme.spacingLg),
                    SizedBox(
                      width: 280,
                      child: _buildHeaderFilters(context, compact: true),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSummary(context),
                    if (includeFilters) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      _buildHeaderFilters(context),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeaderSummary(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.insights, color: Colors.white, size: 18),
                SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Updated today',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
          Text(
            'Revenue is trending ahead of fulfilment volume.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
          Text(
            'Average order value is up 4.1% while low-stock items remain concentrated in a small group of medications.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderFilters(BuildContext context, {bool compact = false}) {
    final filterLabel = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month, color: Colors.white, size: 16),
          SizedBox(width: AppTheme.spacingSm),
          Text(
            'Report window',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final selector = Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: _buildPeriodSelector(context),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterLabel,
          SizedBox(height: AppTheme.spacingMd),
          selector,
        ],
      );
    }

    return Wrap(
      spacing: AppTheme.spacingMd,
      runSpacing: AppTheme.spacingMd,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [filterLabel, selector],
    );
  }

  Widget _buildBackButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: const Icon(Icons.arrow_back, color: _accent, size: 18),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryMedication {
  const _InventoryMedication({
    required this.medicationId,
    required this.medicationName,
    required this.sku,
    required this.quantity,
    required this.reorderLevel,
    required this.unitPrice,
    required this.status,
  });

  final String medicationId;
  final String medicationName;
  final String sku;
  final int quantity;
  final int reorderLevel;
  final String unitPrice;
  final String status;
}
