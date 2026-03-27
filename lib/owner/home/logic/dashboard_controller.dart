import 'bills_controller.dart';
import 'transactions_controller.dart';

class DashboardSummary {
  final int transactions;
  final double totalSales;
  final int billsPaid;

  const DashboardSummary({
    required this.transactions,
    required this.totalSales,
    required this.billsPaid,
  });
}

class DashboardController {
  const DashboardController();

  Future<DashboardSummary> loadTodaysSummary() async {
    const transactionsController = TransactionsController();
    const billsController = BillsController();
    // Always compute dashboard from local persistence first.
    final transactions = await transactionsController
        .getTodaysTransactionCount();
    final totalSales = await transactionsController.getTodaysTotalSales();
    final billsPaid = await billsController.getTodaysBillsPaidCount();

    // Cloud sync is best-effort and must never block local dashboard metrics.
    try {
      await transactionsController.syncTodaysTransactionsToFirebase();
    } catch (_) {}

    try {
      await billsController.syncTodaysPaidBillsToFirebase();
    } catch (_) {}

    return DashboardSummary(
      transactions: transactions,
      totalSales: totalSales,
      billsPaid: billsPaid,
    );
  }
}
