import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/inventory_data.dart';
import '../../../database_helper.dart';

class NotificationsController {
  const NotificationsController();

  static const String _table = 'Notifications';
  static const String _collection = 'notifications';
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static bool _initialized = false;

  String _notificationIdForItem(dynamic item) => 'lowstock:${item.name}';

  String _firebaseDocIdForNotification(String notificationId) =>
      Uri.encodeComponent(notificationId);

  DateTime _tryParseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _ensureNotificationsTable() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        notification_id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        product_name TEXT NOT NULL,
        message TEXT NOT NULL,
        current_stock INTEGER NOT NULL,
        low_stock_threshold INTEGER NOT NULL,
        unit TEXT NOT NULL,
        is_unread INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _syncNotificationToFirebase(Map<String, dynamic> payload) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final notificationId = (payload['notification_id'] ?? '').toString();
      if (notificationId.isEmpty) return;

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_firebaseDocIdForNotification(notificationId))
          .set({
            ...payload,
            'user_id': user.uid,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      // Keep local notifications resilient even if cloud sync rejects an ID.
      debugPrint('Notifications cloud sync skipped: $e');
    }
  }

  Future<void> initialize() async {
    await _ensureNotificationsTable();
    await syncLowStockAlertsWithInventory();
    await _reloadUnreadCountFromDb();

    // Trigger listeners that derive badge state from inventory-driven rebuilds.
    InventoryData.notifier.value = List.from(InventoryData.items);
    _initialized = true;
  }

  Future<void> _reloadUnreadCountFromDb() async {
    await _ensureNotificationsTable();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $_table WHERE is_active = 1 AND is_unread = 1',
    );
    final unread = (rows.first['cnt'] as num?)?.toInt() ?? 0;
    if (unreadCountNotifier.value != unread) {
      unreadCountNotifier.value = unread;
    }
  }

  Future<void> syncLowStockAlertsWithInventory() async {
    await _ensureNotificationsTable();
    final db = await DatabaseHelper.instance.database;

    final activeIds = <String>{};
    for (final item in InventoryData.items.where(
      (i) => i.stock <= i.lowStockAlert,
    )) {
      final notificationId = _notificationIdForItem(item);
      activeIds.add(notificationId);

      final existing = await db.query(
        _table,
        columns: ['notification_id', 'is_unread'],
        where: 'notification_id = ?',
        whereArgs: [notificationId],
        limit: 1,
      );

      final payload = <String, dynamic>{
        'notification_id': notificationId,
        'type': 'lowstock',
        'product_name': item.name,
        'message': 'Only ${item.stock} ${item.unit} left',
        'current_stock': item.stock,
        'low_stock_threshold': item.lowStockAlert,
        'unit': item.unit,
        'is_unread': existing.isEmpty
            ? 1
            : (existing.first['is_unread'] as num?)?.toInt() ?? 1,
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await db.insert(
        _table,
        payload,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _syncNotificationToFirebase(payload);
    }

    // Any previously active low-stock alert that is now resolved becomes inactive.
    final currentlyStored = await db.query(
      _table,
      columns: ['notification_id'],
      where: 'type = ? AND is_active = 1',
      whereArgs: ['lowstock'],
    );
    for (final row in currentlyStored) {
      final id = (row['notification_id'] ?? '').toString();
      if (id.isEmpty || activeIds.contains(id)) continue;

      final payload = <String, dynamic>{
        'is_active': 0,
        'is_unread': 0,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await db.update(
        _table,
        payload,
        where: 'notification_id = ?',
        whereArgs: [id],
      );
      await _syncNotificationToFirebase({'notification_id': id, ...payload});
    }

    await _reloadUnreadCountFromDb();
  }

  Future<void> markAllAsRead() async {
    await _ensureNotificationsTable();
    final db = await DatabaseHelper.instance.database;
    await db.update(_table, {
      'is_unread': 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'is_active = 1 AND is_unread = 1');
    await _reloadUnreadCountFromDb();
  }

  Future<void> markAsRead(String notificationId) async {
    await _ensureNotificationsTable();
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _table,
      {'is_unread': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'notification_id = ?',
      whereArgs: [notificationId],
    );
    await _syncNotificationToFirebase({
      'notification_id': notificationId,
      'is_unread': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await _reloadUnreadCountFromDb();
  }

  Future<void> clearNotifications() async {
    await markAllAsRead();
  }

  /// Get count of low stock alerts (unread notifications)
  int getUnreadNotificationsCount() {
    if (!_initialized) {
      // Lazy bootstrap so badge can recover persisted state without requiring
      // explicit setup calls from unrelated modules.
      initialize();
    }
    return unreadCountNotifier.value;
  }

  /// Check if there are any unread notifications
  bool hasUnreadNotifications() {
    return getUnreadNotificationsCount() > 0;
  }

  /// Get all low stock alerts
  Future<List<Map<String, dynamic>>> getLowStockAlerts() async {
    await _ensureNotificationsTable();

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      _table,
      where: 'type = ? AND is_active = 1',
      whereArgs: ['lowstock'],
      orderBy: 'updated_at DESC',
    );

    return rows.map((row) {
      final productName = (row['product_name'] ?? '').toString();
      final currentStock = (row['current_stock'] as num?)?.toInt() ?? 0;
      final lowStockThreshold =
          (row['low_stock_threshold'] as num?)?.toInt() ?? 0;
      final unit = (row['unit'] ?? 'pcs').toString();

      final item = InventoryData.items
          .where((i) => i.name == productName)
          .cast<dynamic>()
          .firstOrNull;
      final fallbackItem =
          item ??
          {
            'stock': currentStock,
            'unit': unit,
            'lowStockAlert': lowStockThreshold,
          };

      return {
        'id': (row['notification_id'] ?? '').toString(),
        'name': productName,
        'message': (row['message'] ?? '').toString(),
        'type': (row['type'] ?? 'lowstock').toString(),
        'isUnread': ((row['is_unread'] as num?)?.toInt() ?? 0) == 1,
        'timestamp': (row['updated_at'] ?? '').toString(),
        'item': fallbackItem,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getBillReminders() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'Expenses',
      where: "reminder_status != 'Dismissed'",
      orderBy: 'due_date DESC',
    );

    return rows.map((row) {
      final expenseId = (row['expense_id'] as num?)?.toInt() ?? 0;
      final description = (row['description'] ?? '').toString();
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
      final dueDate = (row['due_date'] ?? '').toString();
      final reminderStatus = (row['reminder_status'] ?? 'Pending').toString();

      String title = description;
      if (description.contains('|')) {
        final parts = description.split('|');
        title = parts.length > 1 ? parts[1] : description;
      }

      return {
        'id': 'bill:$expenseId',
        'name': title,
        'message':
            'Bill due on ${dueDate.split('T').first} • Php ${amount.toStringAsFixed(2)}',
        'type': 'bill',
        'isUnread': true,
        'timestamp': dueDate,
        'amountDue': amount,
        'dueDate': dueDate,
        'paymentStatus': reminderStatus,
        'item': {
          'amountDue': amount,
          'dueDate': dueDate,
          'paymentStatus': reminderStatus,
        },
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllNotificationsSorted() async {
    await initialize();
    final lowStock = await getLowStockAlerts();
    final bills = await _getBillReminders();
    final all = <Map<String, dynamic>>[...lowStock, ...bills];

    all.sort((a, b) {
      final aTs = _tryParseDate((a['timestamp'] ?? '').toString());
      final bTs = _tryParseDate((b['timestamp'] ?? '').toString());
      return bTs.compareTo(aTs);
    });

    return all;
  }

  Future<List<Map<String, dynamic>>> getNotificationsByCategory(
    String category,
  ) async {
    final all = await getAllNotificationsSorted();
    if (category == 'all') {
      return all;
    }
    if (category == 'lowstock') {
      return all.where((n) => (n['type'] ?? '') == 'lowstock').toList();
    }
    if (category == 'bills') {
      return all.where((n) => (n['type'] ?? '') == 'bill').toList();
    }
    return all;
  }
}
