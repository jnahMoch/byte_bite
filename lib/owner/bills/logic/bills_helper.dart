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
}
