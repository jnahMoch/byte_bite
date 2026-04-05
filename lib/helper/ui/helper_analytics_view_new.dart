import 'package:flutter/material.dart';

import '../../data/inventory_data.dart';
import '../logic/helper_analytics_controller.dart';

class HelperAnalyticsView extends StatefulWidget {
  const HelperAnalyticsView({super.key});

  @override
  State<HelperAnalyticsView> createState() => _HelperAnalyticsViewState();
}

class _HelperAnalyticsViewState extends State<HelperAnalyticsView> {
  final HelperAnalyticsController _analyticsController =
      const HelperAnalyticsController();
  String _selectedPeriod = 'Today';

  // Analytics data
  int _transactionCount = 0;
  double _totalSales = 0.0;
  double _avgSale = 0.0;
  int _itemsSold = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final summary = await _analyticsController.loadSummary(_selectedPeriod);
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
      onTap: () {
        setState(() => _selectedPeriod = period);
        _loadAnalyticsData();
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
