import 'package:flutter/material.dart';

import '../../../model/pos_item_model.dart';
import '../../../data/inventory_data.dart';
import '../../../data/sales_data.dart';
import '../../../data/bills_data.dart';

class DashboardView extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardView({super.key, this.onNavigate});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

// expose the state type so callers can refresh the summary
class DashboardViewState extends _DashboardViewState {}

class _DashboardViewState extends State<DashboardView> {
  int transactionCount = 0;
  double totalSales = 0.0;
  int billsPaid = 0;

  /// refresh the summary from outside
  Future<void> refresh() async {
    await _loadSummary();
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
    // listen for in-memory data changes as well
    SalesData.notifier.addListener(_loadSummary);
    BillsData.notifier.addListener(_loadSummary);
  }

  Future<void> _loadSummary() async {
    // fall back to in-memory data (was the previous working state)
    final todayTx = SalesData.getTransactionsForToday();
    final txCount = todayTx.length;
    final totSales = todayTx.fold<double>(0.0, (sum, t) => sum + t.total);
    final bills = BillsData.bills.where((b) => b.isPaid).length;

    setState(() {
      transactionCount = txCount;
      totalSales = totSales;
      billsPaid = bills;
    });
  }

  @override
  void dispose() {
    SalesData.notifier.removeListener(_loadSummary);
    BillsData.notifier.removeListener(_loadSummary);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalProducts = InventoryData.items.length;
    int totalStock = InventoryData.items.fold(
      0,
      (sum, item) => sum + item.stock,
    );
    int lowStockItems = InventoryData.items
        .where((item) => item.stock <= item.lowStockAlert)
        .length;
    double inventoryValue = InventoryData.items
        .fold(0, (sum, item) => sum + (item.price * item.stock))
        .toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF009661), Color(0xFF00B377)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.waving_hand, color: Colors.amber, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Byte & Bite POS - Tagum City',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  _getGreeting(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Quick Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Products',
                  '$totalProducts',
                  Icons.inventory_2_outlined,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Total Stock',
                  '$totalStock',
                  Icons.widgets_outlined,
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
                  'Low Stock',
                  '$lowStockItems',
                  Icons.warning_amber_outlined,
                  lowStockItems > 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Inventory Value',
                  '₱${inventoryValue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            "Today's Summary",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _summaryRow(
                  Icons.shopping_cart_outlined,
                  'Transactions',
                  '$transactionCount',
                  const Color(0xFF009661),
                ),
                const Divider(height: 24),
                _summaryRow(
                  Icons.attach_money,
                  'Total Sales',
                  '₱${totalSales.toStringAsFixed(2)}',
                  const Color(0xFF3B82F6),
                ),
                const Divider(height: 24),
                _summaryRow(
                  Icons.receipt_outlined,
                  'Bills Paid',
                  '$billsPaid',
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  context,
                  Icons.point_of_sale,
                  'New Sale',
                  const Color(0xFF009661),
                  2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  context,
                  Icons.add_box_outlined,
                  'Add Stock',
                  const Color(0xFF3B82F6),
                  3,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  context,
                  Icons.bar_chart,
                  'Reports',
                  const Color(0xFF8B5CF6),
                  1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (lowStockItems > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Low Stock Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$lowStockItems items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...InventoryData.items
                .where((item) => item.stock <= item.lowStockAlert)
                .take(3)
                .map((item) => _lowStockItem(item)),
          ],
        ],
      ),
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! Ready to serve?';
    if (hour < 17) return 'Good Afternoon! Keep up the great work!';
    return 'Good Evening! Finishing strong!';
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    int pageIndex,
  ) {
    return GestureDetector(
      onTap: () {
        widget.onNavigate?.call(pageIndex);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lowStockItem(POSItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber, size: 18, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${item.stock} ${item.unit} left',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Low',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
