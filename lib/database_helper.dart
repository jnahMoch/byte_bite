import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async =>
      _database ??= await _initDB('byte_and_bite.db');

  /// Close the database connection (used during backup/restore operations)
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDB(String file) async => await openDatabase(
    join(await getDatabasesPath(), file),
    version: 3,
    onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    onCreate: _createDB,
    onUpgrade: _upgradeDB,
  );

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE Users ADD COLUMN phone TEXT');
    }
    if (oldVersion < 3) {
      // Add transaction status, amount received and change amount to Sales
      try {
        await db.execute(
          "ALTER TABLE Sales ADD COLUMN transaction_status TEXT NOT NULL DEFAULT 'Completed'",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE Sales ADD COLUMN amount_received REAL NOT NULL DEFAULT 0",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE Sales ADD COLUMN change_amount REAL NOT NULL DEFAULT 0",
        );
      } catch (_) {}
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE Users (
      user_id  INTEGER PRIMARY KEY AUTOINCREMENT,
      name     TEXT NOT NULL,
      role     TEXT NOT NULL CHECK(role IN ('Owner','Helper')),
      username TEXT NOT NULL UNIQUE,
      email    TEXT UNIQUE,
      phone    TEXT,
      password TEXT NOT NULL)''');

    // Insert a default owner user (required for foreign key constraints)
    await db.insert('Users', {
      'name': 'Default Owner',
      'role': 'Owner',
      'username': 'owner',
      'email': 'owner@bytebite.com',
      'phone': null,
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
      sale_id        INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id        INTEGER NOT NULL REFERENCES Users(user_id),
      date_time      TEXT NOT NULL DEFAULT (datetime('now')),
      total_amount   REAL NOT NULL CHECK(total_amount >= 0),
      transaction_status TEXT NOT NULL DEFAULT 'Completed',
      amount_received REAL NOT NULL DEFAULT 0,
      change_amount   REAL NOT NULL DEFAULT 0)''');

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

  Future<int> updateUserProfileByUsername({
    required String username,
    required String name,
    required String email,
    required String phone,
  }) async {
    return (await database).update(
      'Users',
      {'name': name, 'email': email, 'phone': phone},
      where: 'username = ?',
      whereArgs: [username],
    );
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
    double amountReceived = 0,
    double changeAmount = 0,
    String transactionStatus = 'Completed',
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      // Resolve a valid user row for FK safety on existing/legacy databases.
      int effectiveUserId = userId;
      final userRows = await txn.query(
        'Users',
        columns: ['user_id'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (userRows.isEmpty) {
        final anyUser = await txn.query(
          'Users',
          columns: ['user_id'],
          orderBy: 'user_id ASC',
          limit: 1,
        );

        if (anyUser.isNotEmpty) {
          effectiveUserId = (anyUser.first['user_id'] as num).toInt();
        } else {
          effectiveUserId = await txn.insert('Users', {
            'name': 'Auto Owner',
            'role': 'Owner',
            'username': 'owner',
            'email': 'owner@bytebite.com',
            'password': 'password123',
          });
        }
      }

      final saleId = await txn.insert('Sales', {
        'user_id': effectiveUserId,
        'date_time': DateTime.now().toIso8601String(),
        'total_amount': totalAmount,
        'transaction_status': transactionStatus,
        'amount_received': amountReceived,
        'change_amount': changeAmount,
      });
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
      return saleId;
    });
  }

  /// Undo a completed sale by `saleId`.
  /// This will increment product stock quantities by the sold amounts,
  /// insert inventory log entries for the restock, and remove the
  /// corresponding Payments, SaleItems and Sales rows.
  /// Use cautiously — this permanently removes the sale record.
  Future<void> undoSale(int saleId) async {
    final db = await database;
    await db.transaction((txn) async {
      final items = await txn.query(
        'SaleItems',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      for (final item in items) {
        final productId = (item['product_id'] as num).toInt();
        final qty = (item['quantity'] as num).toInt();

        await txn.rawUpdate(
          'UPDATE Products SET stock_quantity = stock_quantity + ? WHERE product_id = ?',
          [qty, productId],
        );

        await txn.insert('InventoryLogs', {
          'product_id': productId,
          'change_type': 'restock',
          'quantity_changed': qty,
          'date_time': DateTime.now().toIso8601String(),
        });
      }

      // Delete dependent rows in the correct order to satisfy FK constraints
      await txn.delete('Payments', where: 'sale_id = ?', whereArgs: [saleId]);
      await txn.delete('SaleItems', where: 'sale_id = ?', whereArgs: [saleId]);
      await txn.delete('Sales', where: 'sale_id = ?', whereArgs: [saleId]);
    });
  }

  /// Undo the most recent sale. Returns the undone `sale_id` or null
  /// if there are no sales to undo.
  Future<int?> undoLastSale() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT sale_id FROM Sales ORDER BY sale_id DESC LIMIT 1');
    if (rows.isEmpty) return null;
    final saleId = (rows.first['sale_id'] as num).toInt();
    await undoSale(saleId);
    return saleId;
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
       s.transaction_status, s.amount_received, s.change_amount,
       u.name AS cashier, pay.method, pay.status
        FROM Sales s
        JOIN Users u      ON s.user_id  = u.user_id
        JOIN Payments pay ON s.sale_id  = pay.sale_id
        ORDER BY s.date_time DESC''');

  Future<Map<String, dynamic>> getHelperSalesSummary(String username) async {
    final rows = await (await database).rawQuery(
      '''
      SELECT
        COUNT(s.sale_id) AS sale_count,
        COALESCE(SUM(s.total_amount), 0) AS total_sales,
        MAX(s.date_time) AS last_sale_at
      FROM Sales s
      INNER JOIN Users u ON s.user_id = u.user_id
      WHERE u.username = ?
    ''',
      [username],
    );

    return rows.isNotEmpty ? rows.first : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getRecentHelperSales(
    String username, {
    int limit = 3,
  }) async {
    return (await database).rawQuery(
      '''
      SELECT
        s.sale_id,
        s.date_time,
        s.total_amount,
        pay.method AS payment_method,
        pay.status AS payment_status
      FROM Sales s
      INNER JOIN Users u ON s.user_id = u.user_id
      LEFT JOIN Payments pay ON pay.sale_id = s.sale_id
      WHERE u.username = ?
      ORDER BY s.date_time DESC
      LIMIT ?
    ''',
      [username, limit],
    );
  }

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
