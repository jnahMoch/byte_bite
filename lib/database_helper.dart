import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async =>
      _database ??= await _initDB('byte_and_bite.db');

  Future<Database> _initDB(String file) async => await openDatabase(
    join(await getDatabasesPath(), file),
    version: 1,
    onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    onCreate: _createDB,
  );

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE Users (
      user_id  INTEGER PRIMARY KEY AUTOINCREMENT,
      name     TEXT NOT NULL,
      role     TEXT NOT NULL CHECK(role IN ('Owner','Helper')),
      username TEXT NOT NULL UNIQUE,
      email    TEXT UNIQUE,
      password TEXT NOT NULL)''');

    // Insert a default owner user (required for foreign key constraints)
    await db.insert('Users', {
      'name': 'Default Owner',
      'role': 'Owner',
      'username': 'owner',
      'email': 'owner@bytebite.com',
      'password': 'password123',
    });

    await db.execute('''CREATE TABLE Products (
      product_id     INTEGER PRIMARY KEY AUTOINCREMENT,
      name           TEXT NOT NULL,
      category       TEXT,
      price          REAL NOT NULL CHECK(price >= 0),
      stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
      min_threshold  INTEGER NOT NULL DEFAULT 0,
      description    TEXT)''');

    // ensure at least one product exists so FK in SaleItems succeeds
    // give it nonzero stock to avoid CHECK constraint when decrementing
    await db.insert('Products', {
      'name': 'Seed Product',
      'category': 'Misc',
      'price': 0.0,
      'stock_quantity': 1000,
      'min_threshold': 0,
      'description': 'Auto-generated placeholder',
    });

    await db.execute('''CREATE TABLE Sales (
      sale_id      INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id      INTEGER NOT NULL REFERENCES Users(user_id),
      date_time    TEXT NOT NULL DEFAULT (datetime('now')),
      total_amount REAL NOT NULL CHECK(total_amount >= 0))''');

    await db.execute('''CREATE TABLE SaleItems (
      item_id    INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id    INTEGER NOT NULL REFERENCES Sales(sale_id),
      product_id INTEGER NOT NULL REFERENCES Products(product_id),
      quantity   INTEGER NOT NULL CHECK(quantity > 0),
      subtotal   REAL NOT NULL CHECK(subtotal >= 0))''');

    await db.execute('''CREATE TABLE Payments (
      payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id    INTEGER NOT NULL UNIQUE REFERENCES Sales(sale_id),
      method     TEXT NOT NULL CHECK(method IN ('Cash','GCash','QR')),
      status     TEXT NOT NULL CHECK(status IN ('Success','Failed')))''');

    await db.execute('''CREATE TABLE InventoryLogs (
      log_id           INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id       INTEGER NOT NULL REFERENCES Products(product_id),
      change_type      TEXT NOT NULL CHECK(change_type IN ('sale','restock','spoilage')),
      quantity_changed INTEGER NOT NULL,
      date_time        TEXT NOT NULL DEFAULT (datetime('now')))''');

    await db.execute(
      '''CREATE TABLE Expenses (
      expense_id      INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id         INTEGER NOT NULL REFERENCES Users(user_id),
      description     TEXT NOT NULL,
      amount          REAL NOT NULL CHECK(amount >= 0),
      due_date        TEXT,
      reminder_status TEXT NOT NULL DEFAULT 'Pending'
                      CHECK(reminder_status IN ('Pending','Sent','Dismissed')))''',
    );
  }

  Future<int> insertUser(Map<String, dynamic> data) async =>
      (await database).insert('Users', data);

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final res = await (await database).query(
      'Users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> insertProduct(Map<String, dynamic> data) async =>
      (await database).insert('Products', data);

  Future<List<Map<String, dynamic>>> getAllProducts() async =>
      (await database).query('Products');

  Future<List<Map<String, dynamic>>> getLowStockProducts() async =>
      (await database).query(
        'Products',
        where: 'stock_quantity <= min_threshold',
      );

  Future<int> updateProduct(int id, Map<String, dynamic> data) async =>
      (await database).update(
        'Products',
        data,
        where: 'product_id = ?',
        whereArgs: [id],
      );

  Future<int> deleteProduct(int id) async => (await database).delete(
    'Products',
    where: 'product_id = ?',
    whereArgs: [id],
  );

  Future<int> recordSale({
    required int userId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String paymentStatus,
  }) async {
    print(
      '[DB] recordSale called with totalAmount=$totalAmount, paymentMethod=$paymentMethod, items=$items',
    );
    final db = await database;
    return db.transaction((txn) async {
      final saleId = await txn.insert('Sales', {
        'user_id': userId,
        'date_time': DateTime.now().toIso8601String(),
        'total_amount': totalAmount,
      });
      print('[DB] recordSale inserted row with saleId=$saleId');
      for (final item in items) {
        await txn.insert('SaleItems', {
          'sale_id': saleId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'subtotal': item['subtotal'],
        });
        await txn.rawUpdate(
          'UPDATE Products SET stock_quantity = stock_quantity - ? WHERE product_id = ?',
          [item['quantity'], item['product_id']],
        );
        await txn.insert('InventoryLogs', {
          'product_id': item['product_id'],
          'change_type': 'sale',
          'quantity_changed': -(item['quantity'] as int),
          'date_time': DateTime.now().toIso8601String(),
        });
      }
      await txn.insert('Payments', {
        'sale_id': saleId,
        'method': paymentMethod,
        'status': paymentStatus,
      });
      print('[DB] recordSale transaction completed for saleId=$saleId');
      return saleId;
    });
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async =>
      (await database).rawQuery(
        '''
        SELECT si.quantity, si.subtotal, p.name AS product_name, p.price
        FROM SaleItems si JOIN Products p ON si.product_id = p.product_id
        WHERE si.sale_id = ?''',
        [saleId],
      );

  Future<List<Map<String, dynamic>>> getAllSales() async =>
      (await database).rawQuery('''
        SELECT s.sale_id, s.date_time, s.total_amount,
               u.name AS cashier, pay.method, pay.status
        FROM Sales s
        JOIN Users u      ON s.user_id  = u.user_id
        JOIN Payments pay ON s.sale_id  = pay.sale_id
        ORDER BY s.date_time DESC''');

  Future<int> logInventoryChange(
    int productId,
    String changeType,
    int qty,
  ) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('InventoryLogs', {
        'product_id': productId,
        'change_type': changeType,
        'quantity_changed': qty,
        'date_time': DateTime.now().toIso8601String(),
      });
      await txn.rawUpdate(
        'UPDATE Products SET stock_quantity = stock_quantity + ? WHERE product_id = ?',
        [qty, productId],
      );
      return id;
    });
  }

  Future<int> insertExpense(Map<String, dynamic> data) async =>
      (await database).insert('Expenses', data);

  Future<List<Map<String, dynamic>>> getPendingExpenses() async =>
      (await database).query(
        'Expenses',
        where: "reminder_status = 'Pending'",
        orderBy: 'due_date ASC',
      );

  Future<int> updateExpenseStatus(int id, String status) async =>
      (await database).update(
        'Expenses',
        {'reminder_status': status},
        where: 'expense_id = ?',
        whereArgs: [id],
      );

  Future<void> close() async => (await database).close();
}

// For Today's Summary
// helper that counts all sales (not restricted to today)
Future<int> getTransactionCount() async {
  final db = await DatabaseHelper.instance.database;
  final res = await db.rawQuery('SELECT COUNT(*) as count FROM Sales');
  return Sqflite.firstIntValue(res) ?? 0;
}

// helper that sums all sales
Future<double> getTotalSales() async {
  final db = await DatabaseHelper.instance.database;
  final res = await db.rawQuery('SELECT SUM(total_amount) as total FROM Sales');
  final total = res.first['total'];
  if (total == null) return 0.0;
  // SQLite may return int for whole numbers, handle both
  return (total as num).toDouble();
}

// only expenses marked 'Dismissed' count as paid in current schema
Future<int> getBillsPaid() async {
  final db = await DatabaseHelper.instance.database;
  final res = await db.rawQuery(
    "SELECT COUNT(*) as count FROM Expenses WHERE reminder_status = 'Dismissed'",
  );
  return Sqflite.firstIntValue(res) ?? 0;
}

// versions scoped to today --------------------------------------------------
DateTime _todayStart() {
  final now = DateTime.now();
  final result = DateTime(now.year, now.month, now.day);
  print('[DB] _todayStart() => $result, iso8601=${result.toIso8601String()}');
  return result;
}

Future<int> getTodaysTransactionCount() async {
  final db = await DatabaseHelper.instance.database;
  final start = _todayStart().toIso8601String();
  print('[DB] getTodaysTransactionCount querying with start=$start');

  // DEBUG: Show all rows in Sales table
  final allRows = await db.query('Sales');
  print('[DB] All rows in Sales table: ${allRows.length} rows');
  for (var row in allRows) {
    print('[DB]   Row=$row');
  }

  final res = await db.rawQuery(
    'SELECT COUNT(*) as count FROM Sales WHERE date_time >= ?',
    [start],
  );
  final count = Sqflite.firstIntValue(res) ?? 0;
  print('[DB] getTodaysTransactionCount result: $count');
  return count;
}

Future<double> getTodaysTotalSales() async {
  final db = await DatabaseHelper.instance.database;
  final start = _todayStart().toIso8601String();
  final res = await db.rawQuery(
    'SELECT SUM(total_amount) as total FROM Sales WHERE date_time >= ?',
    [start],
  );
  final total = res.first['total'];
  if (total == null) return 0.0;
  return (total as num).toDouble();
}

Future<int> getTodaysBillsPaid() async {
  // the Expenses schema does not track when a bill was marked paid;
  // at the moment, we only know which bills have been dismissed.
  // return the total paid count as a compromise, or add a paid_date
  // column if you need true day-of filtering.
  return getBillsPaid();
}

// Get total quantity of items sold (all time)
Future<int> getTotalItemsSold() async {
  final db = await DatabaseHelper.instance.database;
  final res = await db.rawQuery('SELECT SUM(quantity) as total FROM SaleItems');
  final total = res.first['total'];
  final result = total == null ? 0 : (total as num).toInt();
  print('[DB] getTotalItemsSold result: $result');
  return result;
}

// Get today's items sold
Future<int> getTodaysItemsSold() async {
  final db = await DatabaseHelper.instance.database;
  final start = _todayStart().toIso8601String();
  print('[DB] getTodaysItemsSold querying with start=$start');
  final res = await db.rawQuery(
    'SELECT SUM(si.quantity) as total FROM SaleItems si JOIN Sales s ON si.sale_id = s.sale_id WHERE s.date_time >= ?',
    [start],
  );
  final total = res.first['total'];
  final result = total == null ? 0 : (total as num).toInt();
  print('[DB] getTodaysItemsSold result: $result');
  return result;
}
