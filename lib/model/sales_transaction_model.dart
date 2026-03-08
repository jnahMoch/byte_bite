class SalesTransaction {
  final String receiptNumber;
  final DateTime dateTime;
  final List<Map<String, dynamic>> items;
  final int total;
  final double amountPaid;
  final double change;
  final String paymentMethod;

  SalesTransaction({
    required this.receiptNumber,
    required this.dateTime,
    required this.items,
    required this.total,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
  });
}
