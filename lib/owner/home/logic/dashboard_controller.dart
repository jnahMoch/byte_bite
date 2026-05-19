import 'dart:async';

import '../../../database_helper.dart';
import 'bills_controller.dart';
import 'transactions_controller.dart';

class DashboardSummary {
  final int transactions;
  final double totalSales;
  final int billsPaid;
  final double monthlySales;
  final double monthlyExpenses;
  final double monthlyNetIncome;

  const DashboardSummary({
    required this.transactions,
    required this.totalSales,
    required this.billsPaid,
    required this.monthlySales,
    required this.monthlyExpenses,
    required this.monthlyNetIncome,
  });
}

class DashboardController {
  const DashboardController();

  Future<DashboardSummary> loadTodaysSummary() async {
    const transactionsController = TransactionsController();
    const billsController = BillsController();
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    // Always compute dashboard from local persistence first.
    final transactions = await transactionsController
        .getTodaysTransactionCount();
    final totalSales = await transactionsController.getTodaysTotalSales();
    final billsPaid = await billsController.getTodaysBillsPaidCount();
    final monthlySalesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) AS total FROM Sales WHERE date_time >= ?',
      [monthStart],
    );
    final monthlySalesValue =
        (monthlySalesRows.isNotEmpty ? monthlySalesRows.first['total'] : null)
            as num?;
    final monthlySales = monthlySalesValue?.toDouble() ?? 0.0;
    final monthlyExpenses = await billsController.getMonthlyPaidExpenses();
    final monthlyNetIncome = monthlySales - monthlyExpenses;

    // Cloud sync is best-effort and must never block local dashboard metrics.
    unawaited(
      Future<void>(() async {
        try {
          await transactionsController.syncTodaysTransactionsToFirebase();
        } catch (_) {}

        try {
          await billsController.syncTodaysPaidBillsToFirebase();
        } catch (_) {}
      }),
    );

    return DashboardSummary(
      transactions: transactions,
      totalSales: totalSales,
      billsPaid: billsPaid,
      monthlySales: monthlySales,
      monthlyExpenses: monthlyExpenses,
      monthlyNetIncome: monthlyNetIncome,
    );
  }
}
