import 'package:flutter/material.dart';

import '../../homepage.dart' show SalesTransaction;
import '../logic/reports_logic.dart';

class BestSellingSection extends StatelessWidget {
  final List<SalesTransaction> transactions;

  const BestSellingSection({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final bestSellingItems = ReportsLogic.getBestSellingItems(transactions);

    if (bestSellingItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedItems = bestSellingItems.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Best Selling Items',
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedItems.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              // ignore: deprecated_member_use
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final item = sortedItems[index];
              final quantity = ReportsLogic.getItemQuantityForBestSelling(
                item.key,
                transactions,
              );

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantity units sold',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${item.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
