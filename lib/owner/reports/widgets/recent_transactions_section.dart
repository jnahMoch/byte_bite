import 'package:flutter/material.dart';

import '../../homepage.dart' show SalesTransaction, SalesData;
import '../../home/logic/transactions_controller.dart';
import '../../home/logic/analytics_controller.dart';
import '../logic/reports_logic.dart';

class RecentTransactionsSection extends StatefulWidget {
  final List<SalesTransaction> transactions;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
  });

  @override
  State<RecentTransactionsSection> createState() =>
      _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState extends State<RecentTransactionsSection> {
  late List<SalesTransaction> _displayedTransactions;
  final TransactionsController _transactionsController =
      const TransactionsController();
  final AnalyticsController _analyticsController =
      const AnalyticsController();

  @override
  void initState() {
    super.initState();
    _displayedTransactions = List.from(widget.transactions);
  }

  Future<bool> _showDeleteConfirmation(SalesTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete Order #${transaction.receiptNumber}?\n\n'
          'Amount: ₱${transaction.total}\n'
          'Items: ${transaction.items.length}\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ) ?? false;
    return confirmed;
  }

  Future<void> _handleTransactionDeletion(
    int index,
    SalesTransaction transaction,
  ) async {
    // Show confirmation dialog
    final confirmed = await _showDeleteConfirmation(transaction);

    if (!confirmed) {
      // Rebuild to reset the dismissible
      if (mounted) setState(() {});
      return;
    }

    // Extract sale ID from receipt number
    final saleId = int.tryParse(
          transaction.receiptNumber.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ?? 0;

    // Proceed with deletion
    try {
      final success = await _transactionsController.deleteTransaction(saleId);

      if (success) {
        // Log the deletion event for analytics
        await _analyticsController.logTransactionDeletion(
          saleId: saleId,
          amount: transaction.total.toDouble(),
          paymentMethod: transaction.paymentMethod,
          itemCount: transaction.items.length,
        );

        // Remove from SalesData to update in-memory state
        SalesData.removeTransactionByReceiptNumber(
          transaction.receiptNumber,
        );

        // Remove from displayed list
        if (mounted) {
          setState(() {
            if (index < _displayedTransactions.length) {
              _displayedTransactions.removeAt(index);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${transaction.receiptNumber} deleted'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete transaction'),
              backgroundColor: Colors.red,
            ),
          );
          // Rebuild to reset the dismissible
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recentTransactions = _displayedTransactions.length > 10
        ? _displayedTransactions.sublist(0, 10)
        : _displayedTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final transaction = recentTransactions[index];
              return Dismissible(
                key: ValueKey(transaction.receiptNumber),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.shade400,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onDismissed: (_) {
                  _handleTransactionDeletion(index, transaction);
                },
                confirmDismiss: (_) async {
                  return await _showDeleteConfirmation(transaction);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.receipt,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${transaction.receiptNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transaction.items.length} items • ${transaction.paymentMethod}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ReportsLogic.formatDateTime(
                                transaction.dateTime,
                              ),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${transaction.total}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF009661),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
