import 'package:flutter/material.dart';

import '../../homepage.dart' show SalesTransaction;
import '../logic/reports_logic.dart';
import 'stat_card.dart';

class OverviewSection extends StatelessWidget {
  final List<SalesTransaction> transactions;
  final String timeFilter;

  const OverviewSection({
    super.key,
    required this.transactions,
    required this.timeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final totalSales = ReportsLogic.getTotalSales(transactions);
    final transactionCount = ReportsLogic.getTransactionCount(transactions);
    final averageSale = ReportsLogic.getAverageSale(transactions);
    final itemsSold = ReportsLogic.getItemsSold(transactions);
    final totalExpenses = ReportsLogic.getTotalExpenses(timeFilter);
    final netIncome = ReportsLogic.getNetIncome(transactions, timeFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              label: 'Total Sales',
              value: 'Rs. $totalSales',
              subtext: '$transactionCount orders',
              icon: Icons.trending_up,
              iconColor: Colors.green,
            ),
            StatCard(
              label: 'Total Expenses',
              value: 'Rs. ${totalExpenses.toStringAsFixed(0)}',
              subtext: 'Bills & costs',
              icon: Icons.receipt_long,
              iconColor: Colors.red,
            ),
            StatCard(
              label: 'Net Income',
              value: 'Rs. ${netIncome.toStringAsFixed(0)}',
              subtext: 'Sales - Expenses',
              icon: Icons.trending_up,
              iconColor: netIncome >= 0 ? Colors.green : Colors.red,
            ),
            StatCard(
              label: 'Average Sale',
              value: 'Rs. ${averageSale.toStringAsFixed(0)}',
              subtext: 'Per transaction',
              icon: Icons.calculate,
              iconColor: Colors.orange,
            ),
            StatCard(
              label: 'Items Sold',
              value: itemsSold.toString(),
              subtext: 'Total units',
              icon: Icons.shopping_bag,
              iconColor: Colors.purple,
            ),
            StatCard(
              label: 'Total Orders',
              value: transactionCount.toString(),
              subtext: 'Transactions',
              icon: Icons.receipt,
              iconColor: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }
}
