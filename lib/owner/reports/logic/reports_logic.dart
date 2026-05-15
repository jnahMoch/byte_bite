import '../../homepage.dart' show SalesData, SalesTransaction;
import '../../../data/bills_data.dart';

class ReportsLogic {
  static List<SalesTransaction> getFilteredTransactions(String timeFilter) {
    switch (timeFilter) {
      case 'Today':
        return SalesData.getTransactionsForToday();
      case 'This Week':
        return SalesData.getTransactionsForWeek();
      case 'This Month':
        return SalesData.getTransactionsForMonth();
      case 'All Time':
        return SalesData.transactions;
      default:
        return SalesData.getTransactionsForToday();
    }
  }

  static int getTotalSales(List<SalesTransaction> transactions) {
    return transactions.fold(0, (sum, t) => sum + t.total);
  }

  static int getTransactionCount(List<SalesTransaction> transactions) {
    return transactions.length;
  }

  static double getAverageSale(List<SalesTransaction> transactions) {
    final count = transactions.length;
    if (count == 0) return 0;
    return getTotalSales(transactions) / count;
  }

  static int getItemsSold(List<SalesTransaction> transactions) {
    return transactions.fold(0, (sum, t) =>
        sum +
        t.items.fold(
            0, (s, i) => s + (i['quantity'] as int)));
  }

  static Map<String, int> getBestSellingItems(
      List<SalesTransaction> transactions) {
    final Map<String, int> itemRevenue = {};
    for (var t in transactions) {
      for (var item in t.items) {
        final name = item['name'] as String;
        final price = item['price'] as int;
        final qty = item['quantity'] as int;
        itemRevenue[name] = (itemRevenue[name] ?? 0) + (price * qty);
      }
    }
    return itemRevenue;
  }

  static Map<String, double> getPaymentMethodBreakdown(
      List<SalesTransaction> transactions) {
    final Map<String, double> methods = {};
    for (var t in transactions) {
      methods[t.paymentMethod] = (methods[t.paymentMethod] ?? 0) + t.total;
    }
    return methods;
  }

  static String formatDateTime(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  static int getItemQuantityForBestSelling(
      String itemName, List<SalesTransaction> transactions) {
    return transactions.fold<int>(
        0,
        (sum, t) =>
            sum +
            t.items
                .where((i) => i['name'] == itemName)
                .fold(0, (s, i) => s + (i['quantity'] as int)));
  }

  // Get total expenses for a given time filter
  static double getTotalExpenses(String timeFilter) {
    switch (timeFilter) {
      case 'Today':
        // For today, include all bills (expenses are not daily-based typically)
        return BillsData.getTotalExpensesForCurrentMonth();
      case 'This Week':
        return BillsData.getTotalExpensesForCurrentMonth();
      case 'This Month':
        return BillsData.getTotalExpensesForCurrentMonth();
      case 'All Time':
        // Sum all bill amounts for all time
        return BillsData.bills.fold(0.0, (sum, b) => sum + b.amount);
      default:
        return BillsData.getTotalExpensesForCurrentMonth();
    }
  }

  // Calculate net income (sales - expenses)
  static double getNetIncome(List<SalesTransaction> transactions, String timeFilter) {
    final totalSales = getTotalSales(transactions).toDouble();
    final totalExpenses = getTotalExpenses(timeFilter);
    return totalSales - totalExpenses;
  }

  // Get net income for current month specifically
  static double getMonthlyNetIncome() {
    final monthlyTransactions = SalesData.getTransactionsForMonth();
    final totalSales = getTotalSales(monthlyTransactions).toDouble();
    final totalExpenses = BillsData.getTotalExpensesForCurrentMonth();
    return totalSales - totalExpenses;
  }
}
