import 'package:flutter/material.dart';

import 'logic/reports_logic.dart';
import 'widgets/exports.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedTimeFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    final filteredTransactions =
        ReportsLogic.getFilteredTransactions(selectedTimeFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TimeFilterButtons(
              selectedFilter: selectedTimeFilter,
              onFilterChanged: (filter) {
                setState(() {
                  selectedTimeFilter = filter;
                });
              },
            ),
            const SizedBox(height: 24),
            OverviewSection(transactions: filteredTransactions),
            const SizedBox(height: 24),
            BestSellingSection(transactions: filteredTransactions),
            const SizedBox(height: 24),
            PaymentMethodsSection(transactions: filteredTransactions),
            const SizedBox(height: 24),
            RecentTransactionsSection(transactions: filteredTransactions),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
