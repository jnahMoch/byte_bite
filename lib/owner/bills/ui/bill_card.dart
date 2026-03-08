import 'package:flutter/material.dart';
import '../logic/bills_helper.dart';
import '../../../owner/homepage.dart' show Bill, BillsData;

/// Individual bill card/item display
class BillCard extends StatefulWidget {
  final Bill bill;
  final bool isOverdue;
  final VoidCallback onMarkedAsPaid;

  const BillCard({
    super.key,
    required this.bill,
    required this.isOverdue,
    required this.onMarkedAsPaid,
  });

  @override
  State<BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<BillCard> {
  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isOverdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: widget.isOverdue
            ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBillHeader(accentColor),
          const SizedBox(height: 14),
          _buildDueDateBadge(accentColor),
          const SizedBox(height: 14),
          _buildMarkAsPaidButton(),
        ],
      ),
    );
  }

  Widget _buildBillHeader(Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.isOverdue ? Icons.warning_rounded : Icons.receipt_long_rounded,
            color: accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bill.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.bill.category,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₱${widget.bill.amount.toStringAsFixed(2)}',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (widget.isOverdue)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  BillsHelper.formatOverdueText(widget.bill.daysOverdue),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDueDateBadge(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: accentColor),
          const SizedBox(width: 8),
          Text(
            "Due: ${BillsHelper.formatDate(widget.bill.dueDate)}",
            style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkAsPaidButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          BillsData.markAsPaid(widget.bill.id);
          widget.onMarkedAsPaid();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.bill.title} marked as paid'),
              backgroundColor: const Color(0xFF009661),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        icon: const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
        label: const Text("Mark as Paid", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009661),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
