import 'package:flutter/material.dart';
import 'homepage.dart' show SalesData, SalesTransaction;

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedReportType = "Sales Report";
  String selectedTimeFilter = "Today";

  List<SalesTransaction> get _filteredTransactions {
    switch (selectedTimeFilter) {
      case 'Today':
        return SalesData.getTransactionsForToday();
      case 'This Week':
        return SalesData.getTransactionsForWeek();
      case 'This Month':
        return SalesData.getTransactionsForMonth();
      case 'All Time':
        return SalesData.transactions;
      default:
        return SalesData.getTransactionsForToday();
    }
  }

  int get _totalSales => _filteredTransactions.fold(0, (sum, t) => sum + t.total);
  int get _transactionCount => _filteredTransactions.length;
  double get _avgSale => _transactionCount > 0 ? _totalSales / _transactionCount : 0;
  int get _itemsSold => _filteredTransactions.fold(0, (sum, t) => 
    sum + t.items.fold(0, (s, i) => s + (i['quantity'] as int)));

  Map<String, int> get _bestSellingItems {
    final Map<String, int> itemCounts = {};
    final Map<String, int> itemRevenue = {};
    for (var t in _filteredTransactions) {
      for (var item in t.items) {
        final name = item['name'] as String;
        final qty = item['quantity'] as int;
        final price = item['price'] as int;
        itemCounts[name] = (itemCounts[name] ?? 0) + qty;
        itemRevenue[name] = (itemRevenue[name] ?? 0) + (price * qty);
      }
    }
    return itemRevenue;
  }

  Map<String, double> get _paymentMethodBreakdown {
    final Map<String, double> methods = {};
    for (var t in _filteredTransactions) {
      methods[t.paymentMethod] = (methods[t.paymentMethod] ?? 0) + t.total;
    }
    return methods;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Reports",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _toggleButton(Icons.bar_chart, "Sales Report", selectedReportType == "Sales Report", () {
                setState(() => selectedReportType = "Sales Report");
              }),
              const SizedBox(width: 10),
              _toggleButton(Icons.inventory_2_outlined, "Inventory Report", selectedReportType == "Inventory Report", () {
                setState(() => selectedReportType = "Inventory Report");
              }),
            ],
          ),
        ),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _filterChip("Today"),
              _filterChip("This Week"),
              _filterChip("This Month"),
              _filterChip("All Time"),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _statCard("Total Sales", "₱${_totalSales.toStringAsFixed(2)}", Icons.attach_money, const Color(0xFF00B67A)),
                  _statCard("Transactions", "$_transactionCount", Icons.check_box_outlined, const Color(0xFF2D7CFF)),
                  _statCard("Avg. Sale", "₱${_avgSale.toStringAsFixed(2)}", Icons.trending_up, const Color(0xFF9D2DFF)),
                  _statCard("Items Sold", "$_itemsSold", Icons.inventory_2, const Color(0xFFFF7A00)),
                ],
              ),
              const SizedBox(height: 20),

              _buildBestSellingSection(),
              const SizedBox(height: 16),

              _buildPaymentMethodsSection(),
              const SizedBox(height: 16),

              _buildRecentTransactionsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestSellingSection() {
    final items = _bestSellingItems.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topItems = items.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF009661).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFF009661), size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Best Selling Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 16),
          if (topItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No sales data available", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...topItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final itemCount = _filteredTransactions.fold<int>(0, (sum, t) =>
                sum + t.items.where((i) => i['name'] == item.key).fold(0, (s, i) => s + (i['quantity'] as int)));
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009661).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF009661))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('$itemCount sold • ₱${item.value}.00 revenue', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009661),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    final methods = _paymentMethodBreakdown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Payment Methods", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 16),
          if (methods.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No payment data available", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...methods.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  Text('₱${entry.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009661))),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    final recentTransactions = _filteredTransactions.reversed.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Recent Transactions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 16),
          if (recentTransactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No transactions yet", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...recentTransactions.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receipt #${t.receiptNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(_formatDateTime(t.dateTime), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₱${t.total}.00', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009661))),
                      Text(t.paymentMethod, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _toggleButton(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF009661) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFF009661) : Colors.grey.shade300),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF009661).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = selectedTimeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedTimeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009661) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? const Color(0xFF009661) : const Color(0xFFE5E7EB)),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF009661).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
            )
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}