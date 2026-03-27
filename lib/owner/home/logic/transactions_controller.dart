import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/sales_data.dart';
import '../../../database_helper.dart';

class TransactionsController {
  const TransactionsController();

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

  Future<int> getTodaysTransactionCount() async {
    await ensureTodaysTransactionsPersisted();
    final db = await DatabaseHelper.instance.database;
    final start = _todayStart().toIso8601String();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM Sales WHERE date_time >= ?',
      [start],
    );
    return (rows.first['cnt'] as num?)?.toInt() ?? 0;
  }

  Future<double> getTodaysTotalSales() async {
    await ensureTodaysTransactionsPersisted();
    final db = await DatabaseHelper.instance.database;
    final start = _todayStart().toIso8601String();
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) AS total FROM Sales WHERE date_time >= ?',
      [start],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
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

      await FirebaseFirestore.instance
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
          }, SetOptions(merge: true));
    }
  }
}
