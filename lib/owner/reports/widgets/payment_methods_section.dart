import 'package:flutter/material.dart';

import '../../homepage.dart' show SalesTransaction;
import '../logic/reports_logic.dart';

class PaymentMethodsSection extends StatelessWidget {
  final List<SalesTransaction> transactions;

  const PaymentMethodsSection({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final paymentMethods = ReportsLogic.getPaymentMethodBreakdown(transactions);

    if (paymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSales = paymentMethods.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: paymentMethods.entries.map((entry) {
              final percentage = (entry.value / totalSales * 100)
                  .toStringAsFixed(1);
              final colors = {
                'Cash': Colors.green,
                'Card': Colors.blue,
                'Digital Wallet': Colors.purple,
                'Bank Transfer': Colors.orange,
              };
              final color = colors[entry.key] ?? Colors.grey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Rs. ${entry.value.toStringAsFixed(0)} ($percentage%)',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / totalSales,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
