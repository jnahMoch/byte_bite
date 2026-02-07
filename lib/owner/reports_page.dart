import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedReportType = "Sales Report";
  String selectedTimeFilter = "Today";

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

        // 1. Report Type Toggle (Sales / Inventory)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _toggleButton(Icons.bar_chart, "Sales Report", true),
              const SizedBox(width: 10),
              _toggleButton(Icons.inventory_2_outlined, "Inventory Report", false),
            ],
          ),
        ),

        // 2. Time Filters (Today, This Week, etc.)
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

        // 3. Stats Grid
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
                  _statCard("Total Sales", "₱0.00", Icons.attach_money, const Color(0xFF00B67A)),
                  _statCard("Transactions", "0", Icons.shopping_bag_outlined, const Color(0xFF2D7CFF)),
                  _statCard("Avg. Sale", "₱0.00", Icons.trending_up, const Color(0xFF9D2DFF)),
                  _statCard("Items Sold", "0", Icons.inventory_2, const Color(0xFFFF7A00)),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Best Selling Items Section
              _infoSection("Best Selling Items", "No sales data available"),
              const SizedBox(height: 16),

              // 5. Payment Methods Section
              _infoSection("Payment Methods", "No payment data available"),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for Top Toggles
  Widget _toggleButton(IconData icon, String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF050718) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Helper for Filter Chips
  Widget _filterChip(String label) {
    bool isSelected = selectedTimeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedTimeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF050718) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Helper for Stat Cards
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(right: 0, top: 0, child: Icon(icon, color: const Color.fromRGBO(255, 255, 255, 0.3), size: 30)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for White Info Sections
  Widget _infoSection(String title, String placeholder) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 40),
          Center(child: Text(placeholder, style: TextStyle(color: Colors.grey[400], fontSize: 13))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}