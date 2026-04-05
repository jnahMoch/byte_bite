import 'package:flutter/material.dart';

import '../../helper/logic/helper_business_logic.dart';
import '../../owner/home/logic/dashboard_controller.dart';
import '../../model/pos_item_model.dart';
import '../../data/inventory_data.dart';

/// Dashboard view for Helper showing overview and quick actions
class HelperDashboardView extends StatefulWidget {
  final Function(int)? onNavigate;

  const HelperDashboardView({super.key, this.onNavigate});

  @override
  State<HelperDashboardView> createState() => _HelperDashboardViewState();
}

class _HelperDashboardViewState extends State<HelperDashboardView> {
  final DashboardController _dashboardController = const DashboardController();
  late Future<DashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _dashboardController.loadTodaysSummary();
  }

  int get _lowStockCount =>
      HelperBusinessLogic.getLowStockCount(InventoryData.items);
  int get _totalProducts => InventoryData.items.length;
  int get _totalStock =>
      InventoryData.items.fold(0, (sum, item) => sum + item.stock);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildQuickOverviewSection(),
          const SizedBox(height: 24),
          _buildTodaysSummarySection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          if (_lowStockCount > 0) ...[
            _buildLowStockAlertsSection(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
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
            HelperBusinessLogic.getGreeting(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                '$_totalProducts',
                Icons.inventory_2_outlined,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Total Stock',
                '$_totalStock',
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
                '$_lowStockCount',
                Icons.warning_amber_outlined,
                _lowStockCount > 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysSummarySection() {
    return FutureBuilder<DashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final transactionCount = summary?.transactions ?? 0;
        final totalSales = summary?.totalSales ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Icons.point_of_sale,
                'New Sale',
                const Color(0xFF009661),
                2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                Icons.inventory_2_outlined,
                'Add Stock',
                const Color(0xFF3B82F6),
                3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLowStockAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_lowStockCount items',
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
        if (_lowStockCount > 3)
          TextButton(
            onPressed: () => widget.onNavigate?.call(3),
            child: const Text('View all low stock items →'),
          ),
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

  Widget _actionCard(IconData icon, String label, Color color, int pageIndex) {
    return GestureDetector(
      onTap: () {
        widget.onNavigate?.call(pageIndex);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.stock} ${item.unit} remaining (Alert: ${item.lowStockAlert})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
