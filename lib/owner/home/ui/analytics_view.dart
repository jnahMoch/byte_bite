import 'package:flutter/material.dart';

import '../../../database_helper.dart';
import '../../../data/inventory_data.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});
  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
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
      int txCount;
      double totalSales;
      int itemsSold;
      // note: txCount/totalSales/itemsSold are fetched directly from
      // database helper methods defined in database_helper.dart.  The
      // analytics cards simply display these computed values.
      // If itemsSold remains 0, inspect recordSale() to ensure SaleItems
      // rows are being inserted correctly.
      if (_selectedPeriod == 'Today') {
        txCount = await getTodaysTransactionCount();
        totalSales = await getTodaysTotalSales();
        itemsSold = await getTodaysItemsSold();
      } else if (_selectedPeriod == 'This Week') {
        txCount = await getTransactionCount();
        totalSales = await getTotalSales();
        itemsSold = await getTotalItemsSold();
      } else if (_selectedPeriod == 'This Month') {
        txCount = await getTransactionCount();
        totalSales = await getTotalSales();
        itemsSold = await getTotalItemsSold();
      } else {
        // All Time
        txCount = await getTransactionCount();
        totalSales = await getTotalSales();
        itemsSold = await getTotalItemsSold();
      }

      setState(() {
        _transactionCount = txCount;
        _totalSales = totalSales;
        _itemsSold = itemsSold;
        _avgSale = txCount > 0 ? totalSales / txCount : 0.0;
      });
    } catch (e) {
      // Error loading data silently
    }
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exporting report...'),
                      backgroundColor: Color(0xFF009661),
                    ),
                  );
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

          _sectionCard('Best Selling Items', 'No sales data yet'),
          const SizedBox(height: 12),
          _sectionCard('Payment Methods', 'No payment data yet'),
        ],
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

  Widget _sectionCard(String title, String emptyText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              emptyText,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
