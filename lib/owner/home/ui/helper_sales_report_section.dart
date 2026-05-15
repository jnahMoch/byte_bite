import 'package:flutter/material.dart';

import '../logic/analytics_controller.dart';

class HelperSalesReportSection extends StatefulWidget {
  final AnalyticsController analyticsController;

  const HelperSalesReportSection({
    super.key,
    required this.analyticsController,
  });

  @override
  State<HelperSalesReportSection> createState() =>
      _HelperSalesReportSectionState();
}

class _HelperSalesReportSectionState extends State<HelperSalesReportSection> {
  static const List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'All Time',
  ];

  String _selectedPeriod = 'This Month';
  String _selectedHelper = 'All Helpers';
  bool _isLoading = true;
  List<String> _helperNames = [];
  HelperSalesReportData? _report;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final helpers = await widget.analyticsController.getHelperUsernames();
      if (!mounted) return;
      setState(() {
        _helperNames = helpers;
      });
      await _reloadReport();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _helperNames = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final helperFilter = _selectedHelper == 'All Helpers'
          ? null
          : _selectedHelper;
      final report = await widget.analyticsController.loadHelperSalesReport(
        period: _selectedPeriod,
        helperUsername: helperFilter,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _report = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport(String format) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exporting helper sales report...'),
          backgroundColor: Color(0xFF009661),
        ),
      );

      final helperFilter = _selectedHelper == 'All Helpers'
          ? null
          : _selectedHelper;
      final exportedPath = await widget.analyticsController.exportHelperSalesReport(
        period: _selectedPeriod,
        helperUsername: helperFilter,
        format: format,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File exported: $exportedPath'),
          backgroundColor: const Color(0xFF009661),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
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
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} • ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final groupedTransactions = <String, List<HelperTransactionRow>>{};
    final groupedProducts = <String, List<HelperProductBreakdownRow>>{};

    if (report != null) {
      for (final transaction in report.transactions) {
        groupedTransactions
            .putIfAbsent(transaction.helperName, () => [])
            .add(transaction);
      }
      for (final row in report.productBreakdown) {
        groupedProducts.putIfAbsent(row.helperName, () => []).add(row);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Sales by Helper',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Export helper sales report',
              onSelected: _exportReport,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'csv',
                  child: Text('Export CSV'),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Text('Export PDF'),
                ),
                PopupMenuItem(
                  value: 'excel',
                  child: Text('Export Excel'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF009661).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF009661).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 18, color: Color(0xFF009661)),
                    SizedBox(width: 8),
                    Text(
                      'Export',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF009661),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Track employee performance, commissions, and product-level sales by helper.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._periods.map(
                (period) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _filterChip(
                    label: period,
                    selected: _selectedPeriod == period,
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                      _reloadReport();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedHelper,
                    items: [
                      const DropdownMenuItem(
                        value: 'All Helpers',
                        child: Text('All Helpers'),
                      ),
                      ..._helperNames.map(
                        (helper) => DropdownMenuItem(
                          value: helper,
                          child: Text(helper),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedHelper = value;
                      });
                      _reloadReport();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: Color(0xFF009661)),
            ),
          )
        else if (report == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'No helper sales data found for the selected filters.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else ...[
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _statCard(
                'Transactions',
                report.transactionCount.toString(),
                Icons.receipt_long,
                const Color(0xFF0EA5E9),
              ),
              _statCard(
                'Total Sales',
                'Rs. ${report.totalSales.toStringAsFixed(0)}',
                Icons.trending_up,
                const Color(0xFF22C55E),
              ),
              _statCard(
                'Items Sold',
                report.itemsSold.toString(),
                Icons.shopping_bag_outlined,
                const Color(0xFFF97316),
              ),
              _statCard(
                'Helpers',
                report.helperPerformance.length.toString(),
                Icons.people_outline,
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Helper Performance',
            child: report.helperPerformance.isEmpty
                ? const Text('No helper summary available.')
                : Column(
                    children: report.helperPerformance
                        .map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF009661).withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF009661),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          row.helperName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${row.transactionCount} transactions • ${row.itemsSold} items',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${row.totalSales.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Product Breakdown by Helper',
            child: groupedProducts.isEmpty
                ? const Text('No product breakdown available.')
                : Column(
                    children: groupedProducts.entries.map((entry) {
                      final helperName = entry.key;
                      final products = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                helperName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...products.map(
                                (product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.productName,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        '${product.quantitySold} pcs',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Rs. ${product.totalSales.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Transaction Details',
            child: groupedTransactions.isEmpty
                ? const Text('No transactions found.')
                : Column(
                    children: groupedTransactions.entries.expand((entry) {
                      final helperName = entry.key;
                      final transactions = entry.value;
                      return [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            helperName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ...transactions.map(
                          (transaction) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sale #${transaction.saleId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${transaction.totalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDateTime(transaction.dateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Period: ${transaction.timePeriod}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${transaction.paymentMethod} • ${transaction.paymentStatus}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  transaction.productSummary,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ];
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1F2937) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
