import 'package:flutter/material.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Section with Title and Add Bill Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Bill Reminders",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text("Add Bill", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009661),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // 2. Summary Cards (Overdue and Upcoming)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _summaryCard("Overdue", "2", "₱6500.00", Colors.red),
              const SizedBox(width: 12),
              _summaryCard("Upcoming", "1", "₱500.00", Colors.blue),
            ],
          ),
        ),

        // 3. Section Label
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                "Overdue Bills",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),

        // 4. List of Bills
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _billItem(
                title: "Electricity Bill",
                category: "Utilities",
                amount: "₱1500.00",
                dueDate: "Feb 05, 2026",
                daysOverdue: "2",
              ),
              _billItem(
                title: "Rent",
                category: "Rent",
                amount: "₱5000.00",
                dueDate: "Feb 01, 2026",
                daysOverdue: "6",
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for the Overdue/Upcoming top cards
  Widget _summaryCard(String title, String count, String total, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(total, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Helper for individual Bill cards
  Widget _billItem({
    required String title,
    required String category,
    required String amount,
    required String dueDate,
    required String daysOverdue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5), // Light red tint for overdue items
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(category, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              Text(amount, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                "Overdue by $daysOverdue day(s) - Due: $dueDate",
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text("Mark as Paid", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009661),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}