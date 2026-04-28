import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../database_helper.dart';
import '../../../data/inventory_data.dart';
import '../logic/analytics_controller.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});
  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  final AnalyticsController _analyticsController = const AnalyticsController();
  String _selectedPeriod = 'Today';

  // Analytics data
  int _transactionCount = 0;
  double _totalSales = 0.0;
  double _avgSale = 0.0;
  int _itemsSold = 0;
  List<_BestSellingProduct> _bestSellingItems = [];
  List<_PaymentMethodStat> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final summary = await _getSalesSummaryForPeriod();

      final bestSellingItems = await _getBestSellingItems();
      final paymentMethods = await _getPaymentMethodStats();

      setState(() {
        _transactionCount = summary.transactionCount;
        _totalSales = summary.totalSales;
        _itemsSold = summary.itemsSold;
        _avgSale = summary.transactionCount > 0
            ? summary.totalSales / summary.transactionCount
            : 0.0;
        _bestSellingItems = bestSellingItems;
        _paymentMethods = paymentMethods;
      });
    } catch (e) {
      // Error loading data silently
    }
  }

  Future<_SalesSummary> _getSalesSummaryForPeriod() async {
    final db = await DatabaseHelper.instance.database;
    final filter = _periodFilter();

    final rows = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT s.sale_id) AS tx_count,
        COALESCE(SUM(s.total_amount), 0) AS total_sales,
        COALESCE(SUM(si.quantity), 0) AS items_sold
      FROM Sales s
      LEFT JOIN SaleItems si ON si.sale_id = s.sale_id
      ${filter.whereClause}
      ''', filter.whereArgs);

    final row = rows.isNotEmpty ? rows.first : <String, Object?>{};
    return _SalesSummary(
      transactionCount: (row['tx_count'] as num?)?.toInt() ?? 0,
      totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0.0,
      itemsSold: (row['items_sold'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<_BestSellingProduct>> _getBestSellingItems({
    int limit = 5,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final filter = _periodFilter();

    final rows = await db.rawQuery(
      '''
      SELECT
        p.name AS product_name,
        SUM(si.quantity) AS units_sold,
        SUM(si.subtotal) AS sales_value
      FROM SaleItems si
      INNER JOIN Sales s ON si.sale_id = s.sale_id
      INNER JOIN Products p ON si.product_id = p.product_id
      ${filter.whereClause}
      GROUP BY si.product_id, p.name
      ORDER BY units_sold DESC, sales_value DESC
      LIMIT ?
      ''',
      [...filter.whereArgs, limit],
    );

    return rows
        .map(
          (row) => _BestSellingProduct(
            name: (row['product_name'] ?? 'Unknown Product').toString(),
            unitsSold: (row['units_sold'] as num?)?.toInt() ?? 0,
            salesValue: (row['sales_value'] as num?)?.toDouble() ?? 0.0,
          ),
        )
        .toList();
  }

  Future<List<_PaymentMethodStat>> _getPaymentMethodStats() async {
    final db = await DatabaseHelper.instance.database;
    final filter = _periodFilter();

    final rows = await db.rawQuery('''
      SELECT
        pay.method AS method,
        COUNT(pay.payment_id) AS tx_count,
        COALESCE(SUM(s.total_amount), 0) AS sales_value
      FROM Payments pay
      INNER JOIN Sales s ON pay.sale_id = s.sale_id
      ${filter.whereClause}
      GROUP BY pay.method
      ORDER BY tx_count DESC, sales_value DESC
      ''', filter.whereArgs);

    return rows
        .map(
          (row) => _PaymentMethodStat(
            method: (row['method'] ?? 'Unknown').toString(),
            transactionCount: (row['tx_count'] as num?)?.toInt() ?? 0,
            salesValue: (row['sales_value'] as num?)?.toDouble() ?? 0.0,
          ),
        )
        .toList();
  }

  _PeriodFilter _periodFilter() {
    final now = DateTime.now();
    DateTime? startDate;

    if (_selectedPeriod == 'Today') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (_selectedPeriod == 'This Week') {
      startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
    } else if (_selectedPeriod == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      return const _PeriodFilter(whereClause: '', whereArgs: []);
    }

    return _PeriodFilter(
      whereClause: 'WHERE s.date_time >= ?',
      whereArgs: [startDate.toIso8601String()],
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalProducts = InventoryData.items.length;
    int totalStock = InventoryData.items.fold(
      0,
      (sum, item) => sum + item.stock,
    );
    double inventoryValue = InventoryData.items
        .fold(0, (sum, item) => sum + (item.price * item.stock))
        .toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exporting report...'),
                      backgroundColor: Color(0xFF009661),
                    ),
                  );

                  try {
                    final exportedPath = await _analyticsController
                        .exportAnalyticsReport(period: _selectedPeriod);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'File exported to public storage: $exportedPath',
                        ),
                        backgroundColor: const Color(0xFF009661),
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.download,
                  size: 18,
                  color: Color(0xFF009661),
                ),
                label: const Text(
                  'Export',
                  style: TextStyle(color: Color(0xFF009661)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF009661)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Today', 'This Week', 'This Month', 'All Time']
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
                    _summaryItem(
                      'Value',
                      '₱${inventoryValue.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _bestSellingSection(),
          const SizedBox(height: 12),
          _paymentMethodsSection(),
        ],
      ),
    );
  }

  Widget _bestSellingSection() {
    final highlight = _bestSellingItems.isNotEmpty
        ? _bestSellingItems.first
        : null;
    final seedFallbackOnly = _isSeedFallbackOnly();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Best Selling Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _selectedPeriod,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF009661),
                  ),
                ),
              ),
            ],
          ),
          if (highlight != null) ...[
            const SizedBox(height: 8),
            Text(
              'Top performer: ${highlight.name} (${highlight.unitsSold} units)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
          if (seedFallbackOnly) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Sales are currently linked to Seed Product only. Check POS sale mapping for product_id.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_bestSellingItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No sales data yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ),
            )
          else ...[
            _bestSellingRankedList(),
            const SizedBox(height: 18),
            _bestSellingBarChart(),
          ],
        ],
      ),
    );
  }

  Widget _bestSellingRankedList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _tableHeader('Product Name')),
                SizedBox(
                  width: 72,
                  child: _tableHeader('Units Sold', alignRight: true),
                ),
                SizedBox(
                  width: 96,
                  child: _tableHeader('Sales Value', alignRight: true),
                ),
              ],
            ),
          ),
          ..._bestSellingItems.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final isLast = rank == _bestSellingItems.length;
            
            final itemRow = Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: rank.isEven ? const Color(0xFFFDFDFD) : Colors.white,
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _rankBadge(rank),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tableCell(
                            item.name,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: _tableCell('${item.unitsSold}', alignRight: true),
                  ),
                  SizedBox(
                    width: 96,
                    child: _tableCell(
                      '₱${item.salesValue.toStringAsFixed(2)}',
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            );

            return Dismissible(
              key: Key('best_selling_${rank}_${item.name}'),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                // Remove from UI immediately (required by Dismissible)
                setState(() {
                  _bestSellingItems.removeWhere((i) => i.name == item.name);
                });
                
                // Delete from database in background (non-blocking)
                _analyticsController.deleteSaleByProduct(item.name);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${item.name} transaction deleted'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              child: itemRow,
            );
          }),
        ],
      ),
    );
  }

  Widget _bestSellingBarChart() {
    final maxUnits = _bestSellingItems.fold<int>(
      0,
      (prev, item) => math.max(prev, item.unitsSold),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Products (Units Sold)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 10),
        ..._bestSellingItems.map((item) {
          final ratio = maxUnits == 0 ? 0.0 : item.unitsSold / maxUnits;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 550),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * ratio,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${item.unitsSold} (${(ratio * 100).toStringAsFixed(0)}%)',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _rankBadge(int rank) {
    Color bgColor;
    Color fgColor;

    if (rank == 1) {
      bgColor = const Color(0xFFFFF7CC);
      fgColor = const Color(0xFF92400E);
    } else if (rank == 2) {
      bgColor = const Color(0xFFF1F5F9);
      fgColor = const Color(0xFF334155);
    } else if (rank == 3) {
      bgColor = const Color(0xFFFFE7D6);
      fgColor = const Color(0xFF9A3412);
    } else {
      bgColor = const Color(0xFFE5E7EB);
      fgColor = const Color(0xFF374151);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fgColor,
        ),
      ),
    );
  }

  Widget _tableHeader(String text, {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
    );
  }

  bool _isSeedFallbackOnly() {
    if (_bestSellingItems.length != 1) return false;
    return _bestSellingItems.first.name.toLowerCase().trim() == 'seed product';
  }

  Widget _tableCell(
    String text, {
    bool alignRight = false,
    FontWeight fontWeight = FontWeight.w500,
    int maxLines = 2,
  }) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: fontWeight,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  Widget _periodChip(String label) {
    bool active = _selectedPeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = label);
        _loadAnalyticsData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF1F2937) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodsSection() {
    final totalTx = _paymentMethods.fold<int>(
      0,
      (sum, item) => sum + item.transactionCount,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalTx tx',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_paymentMethods.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No payment data yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ),
            )
          else ...[
            _paymentMethodRankedList(),
            const SizedBox(height: 16),
            _paymentMethodBarChart(),
          ],
        ],
      ),
    );
  }

  Widget _paymentMethodRankedList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _tableHeader('Method')),
                SizedBox(
                  width: 72,
                  child: _tableHeader('Tx', alignRight: true),
                ),
                SizedBox(
                  width: 96,
                  child: _tableHeader('Sales', alignRight: true),
                ),
              ],
            ),
          ),
          ..._paymentMethods.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final isLast = rank == _paymentMethods.length;
            
            final methodRow = Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: rank.isEven ? const Color(0xFFFDFDFD) : Colors.white,
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _rankBadge(rank),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tableCell(
                            item.method,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: _tableCell(
                      '${item.transactionCount}',
                      alignRight: true,
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: _tableCell(
                      '₱${item.salesValue.toStringAsFixed(2)}',
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            );

            return Dismissible(
              key: Key('payment_method_${rank}_${item.method}'),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                // Remove from UI immediately (required by Dismissible)
                setState(() {
                  _paymentMethods.removeWhere((i) => i.method == item.method);
                });
                
                // Delete from database in background (non-blocking)
                _analyticsController.deleteSaleByPaymentMethod(item.method);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${item.method} transaction deleted'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              child: methodRow,
            );
          }),
        ],
      ),
    );
  }

  Widget _paymentMethodBarChart() {
    final maxTx = _paymentMethods.fold<int>(
      0,
      (prev, item) => math.max(prev, item.transactionCount),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method Distribution',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 10),
        ..._paymentMethods.map((item) {
          final ratio = maxTx == 0 ? 0.0 : item.transactionCount / maxTx;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    item.method,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 550),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * ratio,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${item.transactionCount} (${(ratio * 100).toStringAsFixed(0)}%)',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BestSellingProduct {
  final String name;
  final int unitsSold;
  final double salesValue;

  const _BestSellingProduct({
    required this.name,
    required this.unitsSold,
    required this.salesValue,
  });
}

class _PaymentMethodStat {
  final String method;
  final int transactionCount;
  final double salesValue;

  const _PaymentMethodStat({
    required this.method,
    required this.transactionCount,
    required this.salesValue,
  });
}

class _SalesSummary {
  final int transactionCount;
  final double totalSales;
  final int itemsSold;

  const _SalesSummary({
    required this.transactionCount,
    required this.totalSales,
    required this.itemsSold,
  });
}

class _PeriodFilter {
  final String whereClause;
  final List<Object?> whereArgs;

  const _PeriodFilter({required this.whereClause, required this.whereArgs});
}
