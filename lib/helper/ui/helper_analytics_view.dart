import 'package:flutter/material.dart';

import '../../data/inventory_data.dart';
import '../logic/helper_analytics_controller.dart';

extension DateTimeExtensions on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class HelperAnalyticsView extends StatefulWidget {
  const HelperAnalyticsView({super.key});

  @override
  State<HelperAnalyticsView> createState() => _HelperAnalyticsViewState();
}

class _HelperAnalyticsViewState extends State<HelperAnalyticsView> {
  final HelperAnalyticsController _analyticsController =
      const HelperAnalyticsController();
  String _selectedPeriod = 'Today';

  // Custom date range
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Analytics data
  int _transactionCount = 0;
  double _totalSales = 0.0;
  double _avgSale = 0.0;
  int _itemsSold = 0;

  // Month names for date formatting and parsing
  final List<String> _months = [
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

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final summary = await _analyticsController.loadSummary(
        _selectedPeriod,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
      );
      if (!mounted) return;

      setState(() {
        _transactionCount = summary.transactionCount;
        _totalSales = summary.totalSales;
        _avgSale = summary.avgSale;
        _itemsSold = summary.itemsSold;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _transactionCount = 0;
        _totalSales = 0.0;
        _avgSale = 0.0;
        _itemsSold = 0;
      });
    }
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

    // Validate dates
    if (startDate.isAfter(endDate)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Start date must be before or equal to end date'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _customStartDate = startDate;
      _customEndDate = endDate;
      _selectedPeriod = 'Custom';
    });

    await _loadAnalyticsData();
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
        final TextEditingController dateInputController = TextEditingController(
          text:
              '${_months[clampedInitialDate.month]} ${clampedInitialDate.day}, ${clampedInitialDate.year}',
        );
        bool useTextInput = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF009661),
                  surface: const Color(0xFFF0FDF4),
                  surfaceContainerHighest: const Color(0xFFECFDF3),
                  onSurfaceVariant: const Color(0xFF059669),
                ),
                textTheme: Theme.of(context).textTheme.copyWith(
                  headlineSmall: const TextStyle(
                    color: Color(0xFF009661),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF009661),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => useTextInput = !useTextInput);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                useTextInput
                                    ? Icons.calendar_today
                                    : Icons.edit_outlined,
                                size: 20,
                                color: const Color(0xFF009661),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (useTextInput)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enter date (Format: Jan 15, 2026)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: dateInputController,
                              decoration: InputDecoration(
                                hintText: 'Jan 15, 2026',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFA7F3D0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFA7F3D0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF009661),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (value) {
                                try {
                                  final parsedDate = _parseDateString(
                                    value,
                                    firstDate,
                                    lastDate,
                                  );
                                  if (parsedDate != null) {
                                    setState(() => selectedDate = parsedDate);
                                  }
                                } catch (e) {
                                  // Invalid date format, ignore
                                }
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: CalendarDatePicker(
                          initialDate: selectedDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          onDateChanged: (DateTime date) {
                            setState(() => selectedDate = date);
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFFF8C42),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatCustomDateRange() {
    if (_selectedPeriod != 'Custom' || _customStartDate == null) {
      return '';
    }

    String formatter(DateTime date) {
      return '${_months[date.month]} ${date.day}, ${date.year}';
    }

    if (_customEndDate != null &&
        !_customStartDate!.isSameDate(_customEndDate!)) {
      return '${formatter(_customStartDate!)} – ${formatter(_customEndDate!)}';
    } else if (_customEndDate != null) {
      return formatter(_customStartDate!);
    } else {
      return formatter(_customStartDate!);
    }
  }

  DateTime? _parseDateString(
    String dateString,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    try {
      final cleanedInput = dateString.trim();

      // Parse format: "Jan 15, 2026"
      final parts = cleanedInput.split(RegExp(r'[,\s]+'));
      if (parts.length < 3) return null;

      final monthStr = parts[0];
      final dayStr = parts[1];
      final yearStr = parts[2];

      final monthIndex = _months.indexWhere(
        (m) => m.toLowerCase() == monthStr.toLowerCase(),
      );
      if (monthIndex == -1) return null;

      final day = int.tryParse(dayStr);
      final year = int.tryParse(yearStr);

      if (day == null || year == null || day < 1 || day > 31) return null;

      final parsedDate = DateTime(year, monthIndex, day);

      // Validate within range
      if (parsedDate.isBefore(firstDate) || parsedDate.isAfter(lastDate)) {
        return null;
      }

      return parsedDate;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalProducts = InventoryData.items.length;
    int totalStock = InventoryData.items.fold(
      0,
      (sum, item) => sum + item.stock,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Header
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Period Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Today', 'This Week', 'This Month', 'All Time', 'Custom']
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _periodChip(p),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Display custom date range if selected
          if (_selectedPeriod == 'Custom' && _customStartDate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
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
                      'Selected range: ${_formatCustomDateRange()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showCustomDatePicker,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: const Color(0xFF009661),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Show message if no data found for custom range
          if (_selectedPeriod == 'Custom' && _transactionCount == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF92400E),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No data available for the selected date range.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Stat Cards 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Sales',
                  '₱${_totalSales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Transactions',
                  '$_transactionCount',
                  Icons.receipt_outlined,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Avg. Sale',
                  '₱${_avgSale.toStringAsFixed(2)}',
                  Icons.trending_up,
                  const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Items Sold',
                  '$_itemsSold',
                  Icons.shopping_bag_outlined,
                  const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Inventory Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Inventory Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Products', '$totalProducts'),
                    _summaryItem('Total Stock', '$totalStock'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _periodChip(String period) {
    return GestureDetector(
      onTap: () async {
        if (period == 'Custom') {
          await _showCustomDatePicker();
        } else {
          setState(() => _selectedPeriod = period);
          _customStartDate = null;
          _customEndDate = null;
          _loadAnalyticsData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedPeriod == period
              ? const Color(0xFF1F2937)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _selectedPeriod == period ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
