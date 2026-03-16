import 'package:flutter/foundation.dart';
import '../model/sales_transaction_model.dart';

class SalesData {
  static final List<SalesTransaction> transactions = [];
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void addTransaction(SalesTransaction transaction) {
    transactions.add(transaction);
    notifier.value++; // signal change
  }

  static List<SalesTransaction> getTransactionsForToday() {
    final now = DateTime.now();
    return transactions
        .where(
          (t) =>
              t.dateTime.year == now.year &&
              t.dateTime.month == now.month &&
              t.dateTime.day == now.day,
        )
        .toList();
  }

  static List<SalesTransaction> getTransactionsForWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return transactions.where((t) => t.dateTime.isAfter(weekAgo)).toList();
  }

  static List<SalesTransaction> getTransactionsForMonth() {
    final now = DateTime.now();
    return transactions
        .where(
          (t) => t.dateTime.year == now.year && t.dateTime.month == now.month,
        )
        .toList();
  }
}
