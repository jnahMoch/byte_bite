import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../database_helper.dart';

class AnalyticsController {
  const AnalyticsController();

  Future<String> exportAnalyticsReport({required String period}) async {
    final db = await DatabaseHelper.instance.database;
    final filter = _periodFilter(period);

    final summaryRows = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT s.sale_id) AS tx_count,
        COALESCE(SUM(s.total_amount), 0) AS total_sales,
        COALESCE(SUM(si.quantity), 0) AS items_sold
      FROM Sales s
      LEFT JOIN SaleItems si ON si.sale_id = s.sale_id
      ${filter.whereClause}
      ''', filter.whereArgs);

    final summary = summaryRows.isNotEmpty
        ? summaryRows.first
        : <String, Object?>{};
    final txCount = (summary['tx_count'] as num?)?.toInt() ?? 0;
    final totalSales = (summary['total_sales'] as num?)?.toDouble() ?? 0.0;
    final itemsSold = (summary['items_sold'] as num?)?.toInt() ?? 0;
    final avgSale = txCount > 0 ? totalSales / txCount : 0.0;

    final bestSellingRows = await db.rawQuery('''
      SELECT
        p.name AS product_name,
        COALESCE(SUM(si.quantity), 0) AS units_sold,
        COALESCE(SUM(si.subtotal), 0) AS sales_value
      FROM SaleItems si
      INNER JOIN Sales s ON si.sale_id = s.sale_id
      INNER JOIN Products p ON si.product_id = p.product_id
      ${filter.whereClause}
      GROUP BY si.product_id, p.name
      ORDER BY units_sold DESC, sales_value DESC
      ''', filter.whereArgs);

    final paymentMethodRows = await db.rawQuery('''
      SELECT
        pay.method AS method,
        COUNT(pay.payment_id) AS tx_count,
        COALESCE(SUM(s.total_amount), 0) AS sales_value
      FROM Payments pay
      INNER JOIN Sales s ON pay.sale_id = s.sale_id
      ${filter.whereClause}
      GROUP BY pay.method
      ORDER BY tx_count DESC, sales_value DESC
      ''', filter.whereArgs);

    final csv = StringBuffer();
    csv.writeln('Section,Metric,Value');
    csv.writeln('Summary,Period,${_csv(period)}');
    csv.writeln('Summary,Transactions,$txCount');
    csv.writeln('Summary,Total Sales,${totalSales.toStringAsFixed(2)}');
    csv.writeln('Summary,Items Sold,$itemsSold');
    csv.writeln('Summary,Average Sale,${avgSale.toStringAsFixed(2)}');
    csv.writeln('');

    csv.writeln('Best Selling Items');
    csv.writeln('Rank,Product Name,Units Sold,Sales Value');
    for (int i = 0; i < bestSellingRows.length; i++) {
      final row = bestSellingRows[i];
      final name = (row['product_name'] ?? 'Unknown Product').toString();
      final unitsSold = (row['units_sold'] as num?)?.toInt() ?? 0;
      final salesValue = (row['sales_value'] as num?)?.toDouble() ?? 0.0;
      csv.writeln(
        '${i + 1},${_csv(name)},$unitsSold,${salesValue.toStringAsFixed(2)}',
      );
    }
    csv.writeln('');

    csv.writeln('Payment Methods');
    csv.writeln('Method,Transactions,Sales Value');
    for (final row in paymentMethodRows) {
      final method = (row['method'] ?? 'Unknown').toString();
      final methodTx = (row['tx_count'] as num?)?.toInt() ?? 0;
      final methodSales = (row['sales_value'] as num?)?.toDouble() ?? 0.0;
      csv.writeln(
        '${_csv(method)},$methodTx,${methodSales.toStringAsFixed(2)}',
      );
    }

    final exportDir = await _ensurePublicExportDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final periodSlug = period.toLowerCase().replaceAll(' ', '_');
    final filePath = p.join(
      exportDir.path,
      'analytics_${periodSlug}_$timestamp.csv',
    );

    final file = File(filePath);
    try {
      await file.writeAsString(csv.toString());
    } on FileSystemException catch (e) {
      if (_isPermissionError(e)) {
        throw Exception(
          'Permission denied while exporting to public storage. '
          'Please allow storage access (WRITE_EXTERNAL_STORAGE on older Android versions) and try again.',
        );
      }
      rethrow;
    }

    return file.path;
  }

  Future<Directory> _ensurePublicExportDir() async {
    final candidates = _publicExportDirCandidates();

    for (final candidate in candidates) {
      try {
        if (!await candidate.exists()) {
          await candidate.create(recursive: true);
        }

        // Verify folder is writable.
        final probe = File(p.join(candidate.path, '.write_test.tmp'));
        await probe.writeAsString('ok');
        await probe.delete();
        return candidate;
      } on FileSystemException catch (e) {
        if (_isPermissionError(e)) {
          continue;
        }
      }
    }

    throw Exception(
      'Unable to access a public Downloads/Documents directory for export. '
      'Please grant storage permission and try again.',
    );
  }

  List<Directory> _publicExportDirCandidates() {
    if (Platform.isAndroid) {
      return [
        Directory('/storage/emulated/0/Download/ByteBiteReports'),
        Directory('/storage/emulated/0/Documents/ByteBiteReports'),
        Directory('/sdcard/Download/ByteBiteReports'),
      ];
    }

    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home == null || home.isEmpty) return [];
      return [
        Directory(p.join(home, 'Downloads', 'ByteBiteReports')),
        Directory(p.join(home, 'Documents', 'ByteBiteReports')),
      ];
    }

    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) return [];
      return [
        Directory(p.join(home, 'Downloads', 'ByteBiteReports')),
        Directory(p.join(home, 'Documents', 'ByteBiteReports')),
      ];
    }

    return [];
  }

  bool _isPermissionError(FileSystemException e) {
    final message = e.message.toLowerCase();
    final osMessage = e.osError?.message.toLowerCase() ?? '';
    final code = e.osError?.errorCode;
    return message.contains('permission') ||
        osMessage.contains('permission') ||
        code == 13 ||
        code == 5;
  }

  _SqlFilter _periodFilter(String period) {
    final now = DateTime.now();
    DateTime? startDate;

    if (period == 'Today') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (period == 'This Week') {
      startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
    } else if (period == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
    }

    if (startDate == null) {
      return const _SqlFilter(whereClause: '', whereArgs: []);
    }

    return _SqlFilter(
      whereClause: 'WHERE s.date_time >= ?',
      whereArgs: [startDate.toIso8601String()],
    );
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> deleteSaleByProduct(String productName) async {
    final db = await DatabaseHelper.instance.database;
    
    // Find the product ID
    final products = await db.query(
      'Products',
      where: 'name = ?',
      whereArgs: [productName],
    );
    
    if (products.isEmpty) return;
    
    final productId = (products.first['product_id'] as num?)?.toInt();
    if (productId == null) return;
    
    // Find all sales that contain this product
    final saleItems = await db.query(
      'SaleItems',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    
    if (saleItems.isEmpty) return;
    
    // Get the first sale ID to delete
    final saleId = (saleItems.first['sale_id'] as num?)?.toInt();
    if (saleId == null) return;
    
    // Delete in order: SaleItems, Payments, Sales
    await db.delete(
      'SaleItems',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    
    await db.delete(
      'Payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    
    await db.delete(
      'Sales',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
  }

  Future<void> deleteSaleByPaymentMethod(String paymentMethod) async {
    final db = await DatabaseHelper.instance.database;
    
    // Find the first payment using this method
    final payments = await db.query(
      'Payments',
      where: 'method = ?',
      whereArgs: [paymentMethod],
      limit: 1,
    );
    
    if (payments.isEmpty) return;
    
    final saleId = (payments.first['sale_id'] as num?)?.toInt();
    if (saleId == null) return;
    
    // Delete in order: SaleItems, Payments, Sales
    await db.delete(
      'SaleItems',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    
    await db.delete(
      'Payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    
    await db.delete(
      'Sales',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
  }

  /// Track transaction deletion event for analytics
  Future<void> logTransactionDeletion({
    required int saleId,
    required double amount,
    required String paymentMethod,
    required int itemCount,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Insert deletion event into analytics log if available
      // This can be used to track which transactions were deleted
      await db.insert(
        'TransactionDeletionLog',
        {
          'sale_id': saleId,
          'amount': amount,
          'payment_method': paymentMethod,
          'item_count': itemCount,
          'deleted_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      ).catchError((_) {
        // Table might not exist, that's okay
        return 0;
      });
    } catch (e) {
      // Silently fail logging if there's an error
    }
  }
}

class _SqlFilter {
  final String whereClause;
  final List<Object?> whereArgs;

  const _SqlFilter({required this.whereClause, required this.whereArgs});
}
