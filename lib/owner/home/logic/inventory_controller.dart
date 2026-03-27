import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../database_helper.dart';
import '../../../model/pos_item_model.dart';

class InventoryController {
  const InventoryController();

  static const String _productsCollection = 'products';

  POSItem _mapSqlRowToItem(Map<String, dynamic> row) {
    return POSItem(
      productId: (row['product_id'] as num?)?.toInt(),
      name: (row['name'] ?? '').toString(),
      category: (row['category'] ?? '').toString(),
      price: ((row['price'] as num?) ?? 0).toInt(),
      stock: (row['stock_quantity'] as num?)?.toInt() ?? 0,
      unit: 'pcs',
      lowStockAlert: (row['min_threshold'] as num?)?.toInt() ?? 0,
      image: (row['description'] as String?)?.trim().isEmpty == true
          ? null
          : row['description'] as String?,
    );
  }

  Future<void> _upsertProductToSqlFromItem(POSItem item) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'Products',
      columns: ['product_id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [item.name],
      limit: 1,
    );

    final payload = <String, dynamic>{
      'name': item.name,
      'category': item.category,
      'price': item.price.toDouble(),
      'stock_quantity': item.stock,
      'min_threshold': item.lowStockAlert,
      'description': item.image,
    };

    if (existing.isNotEmpty) {
      final id = (existing.first['product_id'] as num).toInt();
      await DatabaseHelper.instance.updateProduct(id, payload);
      return;
    }

    await DatabaseHelper.instance.insertProduct(payload);
  }

  POSItem _mapFirebaseDocToItem(Map<String, dynamic> data) {
    return POSItem(
      productId: (data['product_id'] as num?)?.toInt(),
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      price: ((data['price'] as num?) ?? 0).toInt(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      unit: (data['unit'] ?? 'pcs').toString(),
      lowStockAlert: (data['lowStockAlert'] as num?)?.toInt() ?? 0,
      image: data['image'] as String?,
    );
  }

  Future<List<POSItem>> loadProducts({bool includeSeed = false}) async {
    final db = await DatabaseHelper.instance.database;

    // Start from local SQLite for offline reliability after restart.
    final sqlRows = await db.query(
      'Products',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    final localItems = sqlRows
        .map(_mapSqlRowToItem)
        .where(
          (item) => includeSeed || item.name.toLowerCase() != 'seed product',
        )
        .toList();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return localItems;
    }

    // Merge cloud state when available, then mirror it back to SQLite.
    final cloudSnapshot = await FirebaseFirestore.instance
        .collection(_productsCollection)
        .orderBy('name')
        .get();

    if (cloudSnapshot.docs.isEmpty) {
      return localItems;
    }

    final cloudItems = cloudSnapshot.docs
        .map((doc) => _mapFirebaseDocToItem(doc.data()))
        .where((item) => item.name.isNotEmpty)
        .where(
          (item) => includeSeed || item.name.toLowerCase() != 'seed product',
        )
        .toList();

    for (final item in cloudItems) {
      await _upsertProductToSqlFromItem(item);
    }

    return cloudItems;
  }

  void _ensureAuthenticatedForSync() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'not-authenticated',
        message: 'No authenticated Firebase user is available for sync.',
      );
    }
  }

  Future<void> _syncProductToFirebase({
    required int productId,
    required POSItem item,
  }) async {
    _ensureAuthenticatedForSync();

    // Firestore caches writes offline and syncs automatically when online.
    await FirebaseFirestore.instance
        .collection(_productsCollection)
        .doc(productId.toString())
        .set({
          'product_id': productId,
          'name': item.name,
          'category': item.category,
          'price': item.price,
          'stock': item.stock,
          'unit': item.unit,
          'lowStockAlert': item.lowStockAlert,
          'image': item.image,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<int?> _resolveProductId(POSItem original) async {
    if (original.productId != null) return original.productId;

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'Products',
      columns: ['product_id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [original.name],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return (rows.first['product_id'] as num).toInt();
  }

  Future<void> updateProduct({
    required POSItem original,
    required POSItem updated,
  }) async {
    final resolvedId = await _resolveProductId(original);

    final payload = <String, dynamic>{
      'name': updated.name,
      'category': updated.category,
      'price': updated.price.toDouble(),
      'stock_quantity': updated.stock,
      'min_threshold': updated.lowStockAlert,
      // Persist image reference in SQLite using description field.
      'description': updated.image,
    };

    int effectiveId;
    if (resolvedId != null) {
      await DatabaseHelper.instance.updateProduct(resolvedId, payload);
      effectiveId = resolvedId;
    } else {
      effectiveId = await DatabaseHelper.instance.insertProduct(payload);
    }

    await _syncProductToFirebase(productId: effectiveId, item: updated);
  }

  Future<POSItem> createProduct({required POSItem item}) async {
    final productId = await DatabaseHelper.instance.insertProduct({
      'name': item.name,
      'category': item.category,
      'price': item.price.toDouble(),
      'stock_quantity': item.stock,
      'min_threshold': item.lowStockAlert,
      // Persist image reference in SQLite using description field.
      'description': item.image,
    });

    final created = POSItem(
      productId: productId,
      name: item.name,
      price: item.price,
      stock: item.stock,
      unit: item.unit,
      category: item.category,
      lowStockAlert: item.lowStockAlert,
      image: item.image,
    );

    await _syncProductToFirebase(productId: productId, item: created);
    return created;
  }
}
