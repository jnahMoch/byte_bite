import 'package:flutter/material.dart';

/// Bills business logic and date utilities
class BillsHelper {
  /// Format date to readable format (e.g., "Jan 08, 2026")
  static String formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  /// Calculate days overdue (negative if due in future)
  static int calculateDaysOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final difference = now.difference(dueDate).inDays;
    return difference;
  }

  /// Check if a bill is overdue
  static bool isOverdue(DateTime dueDate) {
    return calculateDaysOverdue(dueDate) > 0;
  }

  /// Get days until due (returns negative if overdue)
  static int daysUntilDue(DateTime dueDate) {
    return dueDate.difference(DateTime.now()).inDays;
  }

  /// Format overdue text display
  static String formatOverdueText(int daysOverdue) {
    return '${daysOverdue}d overdue';
  }

  /// Format upcoming text display
  static String formatUpcomingText(int daysUntilDue) {
    if (daysUntilDue <= 0) return 'Due today';
    if (daysUntilDue == 1) return 'Due tomorrow';
    return 'Due in $daysUntilDue days';
  }

  /// Generate unique bill ID
  static String generateBillId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Validate bill inputs
  static bool isValidBill(String name, double amount) {
    return name.trim().isNotEmpty && amount > 0;
  }

  /// Get bill categories
  static List<String> getBillCategories() {
    return ['Utilities', 'Rent', 'Supplies', 'Other'];
  }

  /// Get icon for a category
  static IconData getCategoryIcon(String category) {
    const icons = {
      'Utilities': Icons.flash_on_rounded,
      'Rent': Icons.home_rounded,
      'Supplies': Icons.inventory_2_rounded,
      'Other': Icons.more_horiz_rounded,
    };
    return icons[category] ?? Icons.receipt_long_rounded;
  }

  /// Get color for a category
  static Color getCategoryColor(String category) {
    const colors = {
      'Utilities': Color(0xFFF59E0B), // Amber
      'Rent': Color(0xFF3B82F6), // Blue
      'Supplies': Color(0xFF8B5CF6), // Purple
      'Other': Color(0xFF6B7280), // Gray
    };
    return colors[category] ?? const Color(0xFF6B7280);
  }

  /// Get light background color for a category
  static Color getCategoryLightColor(String category) {
    const lighterColors = {
      'Utilities': Color(0xFFFEF3C7), // Light Amber
      'Rent': Color(0xFFDBEAFE), // Light Blue
      'Supplies': Color(0xFFEDE9FE), // Light Purple
      'Other': Color(0xFFF3F4F6), // Light Gray
    };
    return lighterColors[category] ?? const Color(0xFFF3F4F6);
  }
}
