import 'package:flutter/material.dart';

/// Checkout panel with cart summary and payment
class CheckoutPanel extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final int cartTotal;
  final double change;
  final String selectedPayment;
  final TextEditingController amountPaidController;
  final Function(int, int) onUpdateQuantity;
  final Function(int) onRemoveFromCart;
  final Function(String) onPaymentMethodChanged;
  final VoidCallback onCompleteTransaction;

  const CheckoutPanel({
    super.key,
    required this.cart,
    required this.cartTotal,
    required this.change,
    required this.selectedPayment,
    required this.amountPaidController,
    required this.onUpdateQuantity,
    required this.onRemoveFromCart,
    required this.onPaymentMethodChanged,
    required this.onCompleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCartItemsList(),
          const Divider(height: 1),
          _buildPaymentSection(),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    if (cart.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: cart.length,
        itemBuilder: (context, index) {
          final c = cart[index];
          final item = c['item'] as Map<String, String>;
          final qty = c['quantity'] as int;
          final price =
              int.tryParse(item['price']?.replaceAll('₱', '') ?? '0') ?? 0;
          final total = price * qty;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₱$price each',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onUpdateQuantity(index, -1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009661),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '-',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        '$qty',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onUpdateQuantity(index, 1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009661),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '+',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '₱$total.00',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009661),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onRemoveFromCart(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Method Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          color: Colors.grey.shade50,
          child: const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Options
              Row(
                children: [
                  Expanded(
                    child: _paymentOption('Cash', Icons.payments_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _paymentOption('QR', Icons.qr_code)),
                ],
              ),
              const SizedBox(height: 20),
              // Total Amount Due
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount Due',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₱$cartTotal.00',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009661),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_offer,
                        color: Color(0xFF009661),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Amount Paid',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              _buildAmountPaidInput(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Change:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₱${change.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF009661),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCompleteTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009661),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Complete Transaction',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentOption(String label, IconData icon) {
    bool active = selectedPayment == label;
    return GestureDetector(
      onTap: () => onPaymentMethodChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF009661) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF009661) : Colors.grey.shade300,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF009661).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? Colors.white : Colors.grey.shade400,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountPaidInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: amountPaidController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF009661),
              ),
              decoration: const InputDecoration(
                hintText: '0',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  int current = int.tryParse(amountPaidController.text) ?? 0;
                  amountPaidController.text = (current + 1).toString();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: const Icon(Icons.arrow_drop_up, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () {
                  int current = int.tryParse(amountPaidController.text) ?? 0;
                  if (current > 0)
                    amountPaidController.text = (current - 1).toString();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: const Icon(Icons.arrow_drop_down, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
