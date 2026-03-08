import '../../homepage.dart' show SalesData, SalesTransaction;

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
}
