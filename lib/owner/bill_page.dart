import 'package:flutter/material.dart';
import 'homepage.dart' show BillsData;

// UI Components
import 'bills/ui/add_bill_dialog.dart';
import 'bills/ui/bill_card.dart';
import 'bills/ui/bill_components.dart';

/// Bills management page
/// Shows overdue and upcoming bills with management options
class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  void _showAddBillDialog() {
    showDialog(
      context: context,
      builder: (context) => AddBillDialog(
        onBillAdded: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overdueBills = BillsData.overdueBills;
    final upcomingBills = BillsData.upcomingBills;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and add button
          BillsPageHeader(onAddBillPressed: _showAddBillDialog),

          // Summary cards
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: BillsSummaryCards(
              overdueCount: overdueBills.length,
              totalOverdue: BillsData.totalOverdue,
              upcomingCount: upcomingBills.length,
              totalUpcoming: BillsData.totalUpcoming,
            ),
          ),

          // Bills list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overdue bills section
                if (overdueBills.isNotEmpty) ...[
                  BillsSectionHeader(
                    title: "Overdue Bills",
                    icon: Icons.error_outline_rounded,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  ...overdueBills.map(
                    (bill) => BillCard(
                      bill: bill,
                      isOverdue: true,
                      onMarkedAsPaid: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Upcoming bills section
                if (upcomingBills.isNotEmpty) ...[
                  BillsSectionHeader(
                    title: "Upcoming Bills",
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  ...upcomingBills.map(
                    (bill) => BillCard(
                      bill: bill,
                      isOverdue: false,
                      onMarkedAsPaid: () => setState(() {}),
                    ),
                  ),
                ],

                // Empty state
                if (overdueBills.isEmpty && upcomingBills.isEmpty)
                  const EmptyBillsState(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
