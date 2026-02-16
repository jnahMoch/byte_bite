import '../model/sales_transaction_model.dart';

/// Sales data tracking - stores all completed transactions
class SalesData {
  static final List<SalesTransaction> transactions = [];

  static void addTransaction(SalesTransaction transaction) {
    transactions.add(transaction);
  }

  static List<SalesTransaction> getTransactionsForToday() {
    final now = DateTime.now();
    return transactions.where((t) =>
      t.dateTime.year == now.year &&
      t.dateTime.month == now.month &&
      t.dateTime.day == now.day
    ).toList();
  }

  static List<SalesTransaction> getTransactionsForWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return transactions.where((t) => t.dateTime.isAfter(weekAgo)).toList();
  }

  static List<SalesTransaction> getTransactionsForMonth() {
    final now = DateTime.now();
    return transactions.where((t) =>
      t.dateTime.year == now.year &&
      t.dateTime.month == now.month
    ).toList();
  }
}
