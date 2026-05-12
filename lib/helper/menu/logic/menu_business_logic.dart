/// Menu business logic and cart management
class MenuBusinessLogic {
  /// Calculate total from cart items
  static int calculateCartTotal(List<Map<String, dynamic>> cart) {
    return cart.fold<int>(0, (sum, item) {
      final price = _parsePrice(item['item']['price'] ?? '₱0');
      return sum + price * (item['quantity'] as int);
    });
  }

  /// Parse price string to int (removes ₱ and converts)
  static int _parsePrice(String price) {
    return int.tryParse(price.replaceAll('₱', '')) ?? 0;
  }

  /// Calculate change from payment
  static double calculateChange(double amountPaid, int cartTotal) {
    if (amountPaid >= cartTotal) {
      return amountPaid - cartTotal;
    }
    return 0;
  }

  /// Validate if payment is sufficient
  static bool isPaymentSufficient(double amountPaid, int cartTotal) {
    return amountPaid >= cartTotal;
  }

  /// Generate unique receipt number from timestamp
  static String generateReceiptNumber() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Extract cart items for receipt in standardized format
  static List<Map<String, dynamic>> extractCartItems(
    List<Map<String, dynamic>> cart,
  ) {
    return cart
        .map(
          (c) => {
            'name': (c['item'] as Map<String, String>)['name'] ?? '',
            'price': _parsePrice(
              (c['item'] as Map<String, String>)['price'] ?? '₱0',
            ),
            'quantity': c['quantity'] as int,
          },
        )
        .toList();
  }

  /// Get payment method display text
  static String getPaymentMethodDisplay(String method) {
    if (method == 'QR') return 'CASH';
    return method.toUpperCase();
  }
}
