import 'package:flutter/material.dart';
import '../logic/receipt_helper.dart';

/// Receipt display dialog after transaction
class ReceiptDialog extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final int total;
  final double paid;
  final double change;
  final String receiptNumber;
  final String paymentMethod;
  final DateTime date;

  const ReceiptDialog({
    super.key,
    required this.cartItems,
    required this.total,
    required this.paid,
    required this.change,
    required this.receiptNumber,
    required this.paymentMethod,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStoreInfo(),
            const SizedBox(height: 16),
            _buildReceiptDetails(),
            const SizedBox(height: 12),
            _buildDottedDivider(),
            const SizedBox(height: 12),
            _buildItemsList(),
            const SizedBox(height: 8),
            _buildDottedDivider(),
            const SizedBox(height: 12),
            _buildTotals(),
            const SizedBox(height: 12),
            _buildDottedDivider(),
            const SizedBox(height: 16),
            _buildThankYouMessage(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, size: 20, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStoreInfo() {
    return Column(
      children: const [
        Text('BYTE & BITE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Smart POS Solution', style: TextStyle(fontSize: 12, color: Colors.grey)),
        Text('Visayan Village, Tagum City', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReceiptDetails() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date: ${ReceiptHelper.formatDate(date)}', style: const TextStyle(fontSize: 12)),
          Text('Time: ${ReceiptHelper.formatTime(date)}', style: const TextStyle(fontSize: 12)),
          Text('Receipt #: $receiptNumber', style: const TextStyle(fontSize: 12)),
          Text('Payment: $paymentMethod', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: cartItems.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['name'], style: const TextStyle(fontSize: 13)),
                Text('₱${item['price']}.00', style: const TextStyle(fontSize: 13)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('x${item['quantity']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('₱${item['price'] * item['quantity']}.00', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTotals() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('₱$total.00', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Amount Paid:', style: TextStyle(fontSize: 13)),
            Text('₱${paid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Change:', style: TextStyle(fontSize: 13)),
            Text('₱${change.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.grey.shade300 : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildThankYouMessage() {
    return const Column(
      children: [
        Text('Thank you for your purchase!', style: TextStyle(fontSize: 12, color: Color(0xFF009661))),
        Text('Come again soon!', style: TextStyle(fontSize: 12, color: Color(0xFF009661))),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ReceiptHelper.generateAndPrintReceipt(
                cartItems: cartItems,
                total: total,
                paid: paid,
                change: change,
                receiptNumber: receiptNumber,
                paymentMethod: paymentMethod,
                date: date,
              );
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009661),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
