import 'package:flutter/foundation.dart';
import '../model/bill_model.dart';

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
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static void addBill(Bill bill) {
    bills.add(bill);
    notifier.value++;
  }

  static void markAsPaid(String id) {
    final bill = bills.firstWhere((b) => b.id == id);
    bill.isPaid = true;
    notifier.value++;
  }

  static List<Bill> get overdueBills =>
      bills.where((b) => b.isOverdue).toList();
  static List<Bill> get upcomingBills =>
      bills.where((b) => !b.isPaid && !b.isOverdue).toList();
  static double get totalOverdue =>
      overdueBills.fold(0, (sum, b) => sum + b.amount);
  static double get totalUpcoming =>
      upcomingBills.fold(0, (sum, b) => sum + b.amount);

  // Get bills for a specific month
  static List<Bill> getBillsForMonth(int year, int month) {
    return bills
        .where((b) =>
            b.dueDate.year == year && b.dueDate.month == month)
        .toList();
  }

  // Get bills for current month
  static List<Bill> getBillsForCurrentMonth() {
    final now = DateTime.now();
    return getBillsForMonth(now.year, now.month);
  }

  // Calculate total paid expenses for a specific month
  static double getTotalPaidExpensesForMonth(int year, int month) {
    final monthBills = getBillsForMonth(year, month);
    return monthBills
        .where((b) => b.isPaid)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  // Calculate total pending expenses for a specific month
  static double getTotalPendingExpensesForMonth(int year, int month) {
    final monthBills = getBillsForMonth(year, month);
    return monthBills
        .where((b) => !b.isPaid)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  // Calculate total expenses (both paid and pending) for a specific month
  static double getTotalExpensesForMonth(int year, int month) {
    final monthBills = getBillsForMonth(year, month);
    return monthBills.fold(0.0, (sum, b) => sum + b.amount);
  }

  // Calculate total expenses for current month
  static double getTotalExpensesForCurrentMonth() {
    final now = DateTime.now();
    return getTotalExpensesForMonth(now.year, now.month);
  }
}
