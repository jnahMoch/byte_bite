import '../model/bill_model.dart';

/// Bills data tracking - stores all bill reminders
class BillsData {
  static final List<Bill> bills = [
    Bill(
      id: '1',
      title: 'Electricity Bill',
      category: 'Utilities',
      amount: 1500.00,
      dueDate: DateTime(2026, 2, 5),
    ),
    Bill(
      id: '2',
      title: 'Water Bill',
      category: 'Utilities',
      amount: 500.00,
      dueDate: DateTime(2026, 2, 10),
    ),
    Bill(
      id: '3',
      title: 'Rent',
      category: 'Rent',
      amount: 5000.00,
      dueDate: DateTime(2026, 2, 1),
    ),
  ];

  static void addBill(Bill bill) {
    bills.add(bill);
  }

  static void markAsPaid(String id) {
    final bill = bills.firstWhere((b) => b.id == id);
    bill.isPaid = true;
  }

  static List<Bill> get overdueBills => bills.where((b) => b.isOverdue).toList();
  static List<Bill> get upcomingBills => bills.where((b) => !b.isPaid && !b.isOverdue).toList();
  static double get totalOverdue => overdueBills.fold(0, (sum, b) => sum + b.amount);
  static double get totalUpcoming => upcomingBills.fold(0, (sum, b) => sum + b.amount);
}
