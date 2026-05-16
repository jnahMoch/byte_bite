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
    'Custom',
  ];

  String _selectedPeriod = 'This Month';
  String _selectedHelper = 'All Staff';
  bool _isLoading = true;
  List<String> _helperNames = [];
  HelperSalesReportData? _report;
  // Custom date range for "Custom" period
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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
        final helperFilter = _selectedHelper == 'All Staff'
            ? null
            : _selectedHelper;
      final report = await widget.analyticsController.loadHelperSalesReport(
        period: _selectedPeriod,
        helperUsername: helperFilter,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
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
          content: Text('Exporting staff sales report...'),
          backgroundColor: Color(0xFF009661),
        ),
      );

      final helperFilter = _selectedHelper == 'All Helpers'
          ? null
          : _selectedHelper;
      final exportedPath = await widget.analyticsController
          .exportHelperSalesReport(
            period: _selectedPeriod,
            helperUsername: helperFilter,
            customStartDate: _customStartDate,
            customEndDate: _customEndDate,
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
                'Sales by Staff',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
              PopupMenuButton<String>(
              tooltip: 'Export staff sales report',
              onSelected: _exportReport,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                PopupMenuItem(value: 'excel', child: Text('Export Excel')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
          'Track employee performance, commissions, and product-level sales by staff.',
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
                    onTap: () async {
                      if (period == 'Custom') {
                        await _showCustomDatePicker();
                      } else {
                        setState(() {
                          _selectedPeriod = period;
                          _customStartDate = null;
                          _customEndDate = null;
                        });
                        _reloadReport();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 136, maxWidth: 180),
                child: _helperDropdownChip(),
              ),
            ],
          ),
        ),
        if (_selectedPeriod == 'Custom' && _customStartDate != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF009661),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatRangeLabel(),
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showCustomDatePicker,
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF009661),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              'No staff sales data found for the selected filters.',
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
                'Staff',
                report.helperPerformance.length.toString(),
                Icons.people_outline,
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Staff Performance',
            child: report.helperPerformance.isEmpty
                ? const Text('No staff summary available.')
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
                                      color: const Color(
                                        0xFF009661,
                                      ).withValues(alpha: 0.12),
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
            title: 'Product Breakdown by Staff',
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

  Widget _helperDropdownChip() {
    final bool active = _selectedHelper != 'All Staff';
    final Color activeColor = const Color(0xFF009661);
    final Color neutralBorder = Colors.grey.shade300;
    final Color neutralText = Colors.grey.shade700;

    return PopupMenuButton<String>(
      tooltip: 'Select helper',
      onSelected: (value) {
        setState(() {
          _selectedHelper = value;
        });
        _reloadReport();
      },
      constraints: const BoxConstraints(minWidth: 136, maxWidth: 180),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'All Staff',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'All Staff',
                  style: TextStyle(
                    fontWeight: _selectedHelper == 'All Staff'
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (_selectedHelper == 'All Staff')
                const Icon(Icons.check, size: 16, color: Color(0xFF009661)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Helper',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'helper',
                  style: TextStyle(
                    fontWeight: _selectedHelper == 'Helper'
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (_selectedHelper == 'Helper')
                const Icon(Icons.check, size: 16, color: Color(0xFF009661)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Owner',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'owner',
                  style: TextStyle(
                    fontWeight: _selectedHelper == 'Owner'
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (_selectedHelper == 'Owner')
                const Icon(Icons.check, size: 16, color: Color(0xFF009661)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ..._helperNames.map(
          (helper) => PopupMenuItem(
            value: helper,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    helper,
                    style: TextStyle(
                      fontWeight: _selectedHelper == helper
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (_selectedHelper == helper)
                  const Icon(Icons.check, size: 16, color: Color(0xFF009661)),
              ],
            ),
          ),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? activeColor : neutralBorder),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _selectedHelper,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : neutralText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: active ? Colors.white : neutralText,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime clampDate(DateTime date, DateTime firstDate, DateTime lastDate) {
      if (date.isBefore(firstDate)) return firstDate;
      if (date.isAfter(lastDate)) return lastDate;
      return DateTime(date.year, date.month, date.day);
    }

    final startDate = await _showStyledDatePicker(
      context: context,
      initialDate: clampDate(_customStartDate ?? today, DateTime(2000), today),
      firstDate: DateTime(2000),
      lastDate: today,
      title: 'Select start date',
    );
    if (!mounted) return;
    if (startDate == null) return;

    var endDateSeed = _customEndDate ?? startDate;
    if (endDateSeed.isBefore(startDate)) {
      endDateSeed = startDate;
    }

    final endDate = await _showStyledDatePicker(
      context: context,
      initialDate: clampDate(endDateSeed, startDate, today),
      firstDate: startDate,
      lastDate: today,
      title: 'Select end date',
    );
    if (!mounted) return;
    if (endDate == null) return;

    if (startDate.isAfter(endDate)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Start date must be before or equal to end date'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    setState(() {
      _customStartDate = startDate;
      _customEndDate = endDate;
      _selectedPeriod = 'Custom';
    });

    await _reloadReport();
  }

  Future<DateTime?> _showStyledDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String title,
  }) async {
    final clampedInitialDate = initialDate.isBefore(firstDate)
        ? firstDate
        : (initialDate.isAfter(lastDate)
              ? lastDate
              : DateTime(initialDate.year, initialDate.month, initialDate.day));

    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime selectedDate = clampedInitialDate;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFA7F3D0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF009661),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      onDateChanged: (d) => setState(() => selectedDate = d),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF8C42),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF009661),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pop(context, selectedDate),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatRangeLabel() {
    if (_customStartDate == null) return '';
    final months = [
      '',
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
    String fmt(DateTime d) => '${months[d.month]} ${d.day}, ${d.year}';
    if (_customEndDate != null &&
        !(_customStartDate!.year == _customEndDate!.year &&
            _customStartDate!.month == _customEndDate!.month &&
            _customStartDate!.day == _customEndDate!.day)) {
      return '${fmt(_customStartDate!)} – ${fmt(_customEndDate!)}';
    }
    return fmt(_customStartDate!);
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
