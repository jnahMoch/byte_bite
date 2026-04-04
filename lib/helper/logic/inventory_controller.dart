import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../database_helper.dart';
import '../../model/pos_item_model.dart';

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

    // Merge cloud state when available.
    // Keep local SQLite as source of truth for stock counts, and only import
    // cloud products that do not exist locally to avoid losing items.
    QuerySnapshot<Map<String, dynamic>> cloudSnapshot;
    try {
      cloudSnapshot = await FirebaseFirestore.instance
          .collection(_productsCollection)
          .orderBy('name')
          .get();
    } catch (e) {
      // Keep local persisted data as source-of-truth if cloud merge is unavailable.
      debugPrint(
        'inventory_controller.loadProducts: cloud read failed, using local SQLite data: $e',
      );
      return localItems;
    }

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

    if (localItems.isEmpty) {
      for (final item in cloudItems) {
        await _upsertProductToSqlFromItem(item);
      }

      // Return SQL-backed items so productId values always match local DB IDs.
      final hydratedRows = await db.query(
        'Products',
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return hydratedRows
          .map(_mapSqlRowToItem)
          .where(
            (item) => includeSeed || item.name.toLowerCase() != 'seed product',
          )
          .toList();
    }

    final localNames = localItems
        .map((item) => item.name.toLowerCase())
        .toSet();
    var insertedFromCloud = false;
    for (final item in cloudItems) {
      if (localNames.contains(item.name.toLowerCase())) continue;
      await _upsertProductToSqlFromItem(item);
      insertedFromCloud = true;
    }

    if (!insertedFromCloud) {
      return localItems;
    }

    final mergedRows = await db.query(
      'Products',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return mergedRows
        .map(_mapSqlRowToItem)
        .where(
          (item) => includeSeed || item.name.toLowerCase() != 'seed product',
        )
        .toList();
  }

  Future<List<POSItem>> bootstrapLocalFromSeedIfEmpty(
    List<POSItem> seedItems,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final sqlRows = await db.query(
      'Products',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    final existing = sqlRows
        .map(_mapSqlRowToItem)
        .where((item) => item.name.toLowerCase() != 'seed product')
        .toList();
    if (existing.isNotEmpty) {
      return existing;
    }

    // First-run bootstrap: persist default catalog once so future app restarts
    // read from SQLite instead of in-memory seed values.
    for (final item in seedItems) {
      if (item.name.toLowerCase() == 'seed product') continue;
      await _upsertProductToSqlFromItem(item);
    }

    final hydratedRows = await db.query(
      'Products',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return hydratedRows
        .map(_mapSqlRowToItem)
        .where((item) => item.name.toLowerCase() != 'seed product')
        .toList();
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

  /// Sync a product's updated stock to Firestore after local SQLite changes.
  /// Called AFTER local stock is decremented in sales transaction.
  /// Uses merge:true to preserve other cloud fields (e.g., description, price).
  ///
  /// WHY: Ensures Firestore copy stays in sync with local SQLite source-of-truth.
  /// Firestore caches writes offline and syncs automatically when reconnected.
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
