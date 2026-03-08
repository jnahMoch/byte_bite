import 'package:flutter/material.dart';

/// Summary cards showing overdue and upcoming bill counts
class BillsSummaryCards extends StatelessWidget {
  final int overdueCount;
  final double totalOverdue;
  final int upcomingCount;
  final double totalUpcoming;

  const BillsSummaryCards({
    super.key,
    required this.overdueCount,
    required this.totalOverdue,
    required this.upcomingCount,
    required this.totalUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _summaryCard(
          "Overdue",
          "$overdueCount",
          "₱${totalOverdue.toStringAsFixed(0)}",
          const Color(0xFFEF4444),
          const Color(0xFFDC2626),
          Icons.warning_rounded,
        ),
        const SizedBox(width: 12),
        _summaryCard(
          "Upcoming",
          "$upcomingCount",
          "₱${totalUpcoming.toStringAsFixed(0)}",
          const Color(0xFF3B82F6),
          const Color(0xFF2563EB),
          Icons.schedule_rounded,
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String count,
    String total,
    Color startColor,
    Color endColor,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [startColor, endColor],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: startColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
}

/// Section header with icon and title
class BillsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const BillsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}

/// Empty state when no bills exist
class EmptyBillsState extends StatelessWidget {
  const EmptyBillsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No bills to track",
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a bill to get started",
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

/// Bills page header with title and add button
class BillsPageHeader extends StatelessWidget {
  final VoidCallback onAddBillPressed;

  const BillsPageHeader({
    super.key,
    required this.onAddBillPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bill Reminders",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Track upcoming payments",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onAddBillPressed,
                icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                label: const Text("Add Bill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009661),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
