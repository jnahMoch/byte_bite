import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../data/sales_data.dart';
import '../../../model/sales_transaction_model.dart';
import '../../../database_helper.dart';

class TransactionsController {
  const TransactionsController();

  Future<bool> deleteTransaction(int saleId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Delete related sale items first
      await db.delete('SaleItems', where: 'sale_id = ?', whereArgs: [saleId]);

      // Delete related payments
      await db.delete('Payments', where: 'sale_id = ?', whereArgs: [saleId]);

      // Delete the sale
      await db.delete('Sales', where: 'sale_id = ?', whereArgs: [saleId]);

      return true;
    } catch (e) {
      return false;
    }
  }

  DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _normalizeMethod(String method) {
    final trimmed = method.trim();
    if (trimmed == 'GCash') return 'GCash';
    if (trimmed == 'QR') return 'QR';
    return 'Cash';
  }

  bool _matchesPersistedSale({
    required DateTime txDate,
    required double txTotal,
    required String txMethod,
    required Map<String, dynamic> row,
  }) {
    final rowDateRaw = row['date_time']?.toString();
    final rowDate = DateTime.tryParse(rowDateRaw ?? '');
    final rowTotal = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
    final rowMethod = (row['payment_method'] ?? '').toString();
    if (rowDate == null) return false;

    final sameMethod = rowMethod == txMethod;
    final sameTotal = (rowTotal - txTotal).abs() < 0.001;
    final closeTime = rowDate.difference(txDate).inSeconds.abs() <= 120;
    return sameMethod && sameTotal && closeTime;
  }

  Future<void> ensureTodaysTransactionsPersisted() async {
    final db = await DatabaseHelper.instance.database;
    final todaysMemoryTransactions = SalesData.getTransactionsForToday();
    if (todaysMemoryTransactions.isEmpty) return;

    final start = _todayStart().toIso8601String();
    final existingRows = await db.rawQuery(
      '''
      SELECT
        s.sale_id,
        s.date_time,
        s.total_amount,
        pay.method AS payment_method
      FROM Sales s
      LEFT JOIN Payments pay ON pay.sale_id = s.sale_id
      WHERE s.date_time >= ?
    ''',
      [start],
    );

    for (final tx in todaysMemoryTransactions) {
      final txTotal = tx.total.toDouble();
      final txMethod = _normalizeMethod(tx.paymentMethod);
      final exists = existingRows.any(
        (row) => _matchesPersistedSale(
          txDate: tx.dateTime,
          txTotal: txTotal,
          txMethod: txMethod,
          row: row,
        ),
      );
      if (exists) continue;

      final saleId = await db.insert('Sales', {
        'user_id': 1,
        'date_time': tx.dateTime.toIso8601String(),
        'total_amount': txTotal,
      });

      await db.insert('Payments', {
        'sale_id': saleId,
        'method': txMethod,
        'status': 'Success',
      });

      existingRows.add({
        'sale_id': saleId,
        'date_time': tx.dateTime.toIso8601String(),
        'total_amount': txTotal,
        'payment_method': txMethod,
      });
    }
  }

  Future<List<SalesTransaction>> loadPersistedTransactions() async {
    await ensureTodaysTransactionsPersisted();

    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        s.sale_id,
        s.date_time,
        s.total_amount,
        pay.method AS payment_method,
        pay.status AS payment_status
      FROM Sales s
      LEFT JOIN Payments pay ON pay.sale_id = s.sale_id
      ORDER BY s.date_time DESC, s.sale_id DESC
    ''');

    final transactions = <SalesTransaction>[];
    for (final row in rows) {
      final saleId = (row['sale_id'] as num?)?.toInt();
      if (saleId == null) continue;

      final itemRows = await db.rawQuery(
        '''
        SELECT
          si.quantity,
          si.subtotal,
          p.name,
          p.price
        FROM SaleItems si
        LEFT JOIN Products p ON p.product_id = si.product_id
        WHERE si.sale_id = ?
        ORDER BY si.item_id ASC
      ''',
        [saleId],
      );

      final items = itemRows.map((itemRow) {
        final quantity = (itemRow['quantity'] as num?)?.toInt() ?? 0;
        final subtotal = (itemRow['subtotal'] as num?)?.toDouble() ?? 0.0;
        final productName = (itemRow['name'] ?? 'Item').toString();
        final unitPrice =
            (itemRow['price'] as num?)?.toDouble() ??
            (quantity > 0 ? subtotal / quantity : 0.0);

        return <String, dynamic>{
          'name': productName,
          'price': unitPrice,
          'quantity': quantity,
        };
      }).toList();

      final totalAmount = (row['total_amount'] as num?)?.toDouble() ?? 0.0;
      transactions.add(
        SalesTransaction(
          receiptNumber: saleId.toString(),
          dateTime:
              DateTime.tryParse((row['date_time'] ?? '').toString()) ??
              DateTime.now(),
          items: items,
          total: totalAmount.round(),
          amountPaid: totalAmount,
          change: 0.0,
          paymentMethod: (row['payment_method'] ?? 'Cash').toString(),
        ),
      );
    }

    return transactions;
  }

  Future<int> getTodaysTransactionCount() async {
    try {
      // Persist any unsaved transactions from SalesData to SQLite first
      await ensureTodaysTransactionsPersisted();

      final db = await DatabaseHelper.instance.database;
      final start = _todayStart().toIso8601String();

      // Query SQLite (now includes all transactions, persisted + synced)
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM Sales WHERE date_time >= ?',
        [start],
      );

      if (rows.isEmpty) return 0;
      final cnt = rows.first['cnt'];
      return (cnt as num?)?.toInt() ?? 0;
    } catch (e, st) {
      debugPrint('getTodaysTransactionCount failed: $e\n$st');
      rethrow;
    }
  }

  Future<double> getTodaysTotalSales() async {
    try {
      // Persist any unsaved transactions from SalesData to SQLite first
      await ensureTodaysTransactionsPersisted();

      final db = await DatabaseHelper.instance.database;
      final start = _todayStart().toIso8601String();

      // Query SQLite (now includes all transactions, persisted + synced)
      final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(total_amount), 0) AS total FROM Sales WHERE date_time >= ?',
        [start],
      );

      if (rows.isEmpty) return 0.0;
      final total = rows.first['total'];
      return (total as num?)?.toDouble() ?? 0.0;
    } catch (e, st) {
      debugPrint('getTodaysTotalSales failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> restoreTransactionsFromFirebase() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final saleId = (data['sale_id'] as num?)?.toInt();
        if (saleId == null) continue;

        final existing = await db.query(
          'Sales',
          where: 'sale_id = ?',
          whereArgs: [saleId],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;

        final totalAmount = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
        final dateTime =
            DateTime.tryParse((data['date_time'] ?? '').toString()) ??
            DateTime.now();
        final paymentMethod = (data['payment_method'] ?? 'Cash').toString();

        final insertedId = await db.insert('Sales', {
          'user_id': 1,
          'date_time': dateTime.toIso8601String(),
          'total_amount': totalAmount,
        });

        await db.insert('Payments', {
          'sale_id': insertedId,
          'method': paymentMethod,
          'status': (data['payment_status'] ?? 'Success').toString(),
        });
      }
    } catch (_) {}
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
          'transactions_controller firestore retry attempt $attempt failed: $e\n$st',
        );
        await Future.delayed(delay * attempt);
      }
    }
    throw StateError('Unexpected Firestore retry failure');
  }

  Future<void> syncTodaysTransactionsToFirebase() async {
    await ensureTodaysTransactionsPersisted();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = await DatabaseHelper.instance.database;
    final start = _todayStart().toIso8601String();
    final rows = await db.rawQuery(
      '''
      SELECT
        s.sale_id,
        s.user_id,
        s.date_time,
        s.total_amount,
        pay.method AS payment_method,
        pay.status AS payment_status
      FROM Sales s
      LEFT JOIN Payments pay ON pay.sale_id = s.sale_id
      WHERE s.date_time >= ?
      ORDER BY s.date_time DESC
    ''',
      [start],
    );

    for (final row in rows) {
      final saleId = (row['sale_id'] as num?)?.toInt();
      if (saleId == null) continue;

      try {
        await _withFirestoreRetry(
          () => FirebaseFirestore.instance
              .collection('transactions')
              .doc(saleId.toString())
              .set({
                'sale_id': saleId,
                'user_uid': user.uid,
                'local_user_id': row['user_id'],
                'date_time': row['date_time'],
                'total_amount': row['total_amount'],
                'payment_method': row['payment_method'],
                'payment_status': row['payment_status'],
                'updated_at': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true)),
        );
      } catch (e, st) {
        debugPrint(
          'syncTodaysTransactionsToFirebase failed for sale $saleId: $e\n$st',
        );
      }
    }
  }
}
