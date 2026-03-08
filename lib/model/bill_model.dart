class Bill {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime dueDate;
  bool isPaid;

  Bill({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  int get daysOverdue {
    if (isPaid) return 0;
    final now = DateTime.now();
    if (dueDate.isAfter(now)) return 0;
    return now.difference(dueDate).inDays;
  }

  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);
}
