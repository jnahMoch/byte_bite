import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../database_helper.dart';
import '../../../model/bill_model.dart';

class BillsController {
  const BillsController();

  static bool _paidAtColumnEnsured = false;

  Future<void> _ensurePaidAtColumn() async {
    if (_paidAtColumnEnsured) return;

    final db = await DatabaseHelper.instance.database;
    final columns = await db.rawQuery('PRAGMA table_info(Expenses)');
    final hasPaidAt = columns.any((c) => c['name'] == 'paid_at');
    if (!hasPaidAt) {
      await db.execute('ALTER TABLE Expenses ADD COLUMN paid_at TEXT');
    }

    _paidAtColumnEnsured = true;
  }

  DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<List<Bill>> loadBills() async {
    await _ensurePaidAtColumn();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('Expenses', orderBy: 'due_date ASC');

    return rows.map((row) {
      final id = (row['expense_id'] as num?)?.toInt().toString() ?? '';
      final rawDescription = (row['description'] ?? '').toString();
      final title = extractTitle(rawDescription);
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
      final dueRaw = (row['due_date'] ?? '').toString();
      final dueDate = DateTime.tryParse(dueRaw) ?? DateTime.now();
      final status = (row['reminder_status'] ?? 'Pending').toString();
      final isPaid = status == 'Dismissed';

      return Bill(
        id: id,
        title: title,
        category: _extractCategory(rawDescription),
        amount: amount,
        dueDate: dueDate,
        isPaid: isPaid,
      );
    }).toList();
  }

  Future<int> addBill({
    required String title,
    required String category,
    required double amount,
    required DateTime dueDate,
  }) async {
    await _ensurePaidAtColumn();
    final insertedId = await DatabaseHelper.instance.insertExpense({
      'user_id': 1,
      'description': '$category|$title',
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'reminder_status': 'Pending',
      'paid_at': null,
    });

    try {
      await _syncBillToFirebase(
        expenseId: insertedId,
        title: title,
        category: category,
        amount: amount,
        dueDate: dueDate,
        reminderStatus: 'Pending',
      );
    } catch (_) {}

    return insertedId;
  }

  Future<void> markBillAsPaid(String billId) async {
    await _ensurePaidAtColumn();
    final expenseId = int.tryParse(billId);
    if (expenseId == null) return;

    final db = await DatabaseHelper.instance.database;
    final paidAt = DateTime.now().toIso8601String();
    await db.update(
      'Expenses',
      {'reminder_status': 'Dismissed', 'paid_at': paidAt},
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );

    try {
      await _syncBillStatusToFirebase(
        expenseId: expenseId,
        reminderStatus: 'Dismissed',
        paidAt: paidAt,
      );
    } catch (_) {}
  }

  Future<int> getTodaysBillsPaidCount() async {
    await _ensurePaidAtColumn();
    final db = await DatabaseHelper.instance.database;
    final start = _todayStart().toIso8601String();
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM Expenses WHERE reminder_status = 'Dismissed' AND paid_at IS NOT NULL AND paid_at >= ?",
      [start],
    );
    return (rows.first['cnt'] as num?)?.toInt() ?? 0;
  }

  Future<double> getMonthlyPaidExpenses() async {
    await _ensurePaidAtColumn();
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final rows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) AS total FROM Expenses WHERE reminder_status = 'Dismissed' AND paid_at IS NOT NULL AND paid_at >= ?",
      [monthStart],
    );

    if (rows.isEmpty) return 0.0;
    final total = rows.first['total'];
    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<T> _withFirestoreRetry<T>(
    Future<T> Function() operation, {
    int attempts = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await operation();
      } catch (e, st) {
        if (attempt >= attempts) {
          rethrow;
        }
        debugPrint(
          'bills_controller firestore retry attempt $attempt failed: $e\n$st',
        );
        await Future.delayed(delay * attempt);
      }
    }
    throw StateError('Unexpected Firestore retry failure');
  }

  Future<void> syncTodaysPaidBillsToFirebase() async {
    await _ensurePaidAtColumn();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = await DatabaseHelper.instance.database;
    final start = _todayStart().toIso8601String();
    final rows = await db.query(
      'Expenses',
      where:
          "reminder_status = 'Dismissed' AND paid_at IS NOT NULL AND paid_at >= ?",
      whereArgs: [start],
    );

    for (final row in rows) {
      final expenseId = (row['expense_id'] as num?)?.toInt();
      if (expenseId == null) continue;

      try {
        await _withFirestoreRetry(
          () => FirebaseFirestore.instance
              .collection('bills')
              .doc(expenseId.toString())
              .set({
                'expense_id': expenseId,
                'user_id': user.uid,
                'reminder_status': 'Dismissed',
                'paid_at': row['paid_at'],
                'updated_at': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true)),
        );
      } catch (e, st) {
        debugPrint(
          'syncTodaysPaidBillsToFirebase failed for expense $expenseId: $e\n$st',
        );
      }
    }
  }

  Future<void> _syncBillToFirebase({
    required int expenseId,
    required String title,
    required String category,
    required double amount,
    required DateTime dueDate,
    required String reminderStatus,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _withFirestoreRetry(
      () => FirebaseFirestore.instance
          .collection('bills')
          .doc(expenseId.toString())
          .set({
            'expense_id': expenseId,
            'user_id': user.uid,
            'title': title,
            'category': category,
            'amount': amount,
            'due_date': dueDate.toIso8601String(),
            'reminder_status': reminderStatus,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
    );
  }

  Future<void> _syncBillStatusToFirebase({
    required int expenseId,
    required String reminderStatus,
    String? paidAt,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _withFirestoreRetry(
      () => FirebaseFirestore.instance
          .collection('bills')
          .doc(expenseId.toString())
          .set({
            'user_id': user.uid,
            'reminder_status': reminderStatus,
            'paid_at': paidAt,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)),
    );
  }

  String _extractCategory(String rawDescription) {
    final idx = rawDescription.indexOf('|');
    if (idx <= 0) return 'Other';
    return rawDescription.substring(0, idx);
  }

  String extractTitle(String rawDescription) {
    final idx = rawDescription.indexOf('|');
    if (idx <= 0 || idx >= rawDescription.length - 1) return rawDescription;
    return rawDescription.substring(idx + 1);
  }

  Future<void> restoreBillsFromFirebase() async {
    await _ensurePaidAtColumn();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bills')
          .where('user_id', isEqualTo: user.uid)
          .get();

      final db = await DatabaseHelper.instance.database;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final expenseId = (data['expense_id'] as num?)?.toInt();
        final title = (data['title'] ?? '').toString();
        final category = (data['category'] ?? 'Other').toString();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final dueRaw = (data['due_date'] ?? '').toString();
        final dueDate = DateTime.tryParse(dueRaw) ?? DateTime.now();
        final reminderStatus = (data['reminder_status'] ?? 'Pending')
            .toString();
        final paidAt = (data['paid_at'] ?? '').toString();

        if (expenseId == null) continue;

        final existing = await db.query(
          'Expenses',
          where: 'expense_id = ?',
          whereArgs: [expenseId],
          limit: 1,
        );

        if (existing.isEmpty) {
          await db.insert('Expenses', {
            'expense_id': expenseId,
            'user_id': 1,
            'description': '$category|$title',
            'amount': amount,
            'due_date': dueDate.toIso8601String(),
            'reminder_status': reminderStatus,
            'paid_at': paidAt.isEmpty ? null : paidAt,
          });
        } else {
          await db.update(
            'Expenses',
            {
              'description': '$category|$title',
              'amount': amount,
              'due_date': dueDate.toIso8601String(),
              'reminder_status': reminderStatus,
              'paid_at': paidAt.isEmpty ? null : paidAt,
            },
            where: 'expense_id = ?',
            whereArgs: [expenseId],
          );
        }
      }
    } catch (_) {
      // Best-effort restore; continue even if Firebase is unreachable
    }
  }

  Future<void> deleteBill(String billId) async {
    final expenseId = int.tryParse(billId);
    if (expenseId == null) return;

    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'Expenses',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );

    try {
      await FirebaseFirestore.instance.collection('bills').doc(billId).delete();
    } catch (_) {}
  }
}
