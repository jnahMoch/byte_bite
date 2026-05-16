import 'dart:io';

import 'package:excel/excel.dart' as excel;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../database_helper.dart';

class HelperSalesReportData {
  final String period;
  final String helperFilterLabel;
  final int transactionCount;
  final double totalSales;
  final int itemsSold;
  final List<HelperSalesPerformanceRow> helperPerformance;
  final List<HelperProductBreakdownRow> productBreakdown;
  final List<HelperTransactionRow> transactions;

  const HelperSalesReportData({
    required this.period,
    required this.helperFilterLabel,
    required this.transactionCount,
    required this.totalSales,
    required this.itemsSold,
    required this.helperPerformance,
    required this.productBreakdown,
    required this.transactions,
  });
}

class HelperSalesPerformanceRow {
  final String helperName;
  final int transactionCount;
  final double totalSales;
  final int itemsSold;

  const HelperSalesPerformanceRow({
    required this.helperName,
    required this.transactionCount,
    required this.totalSales,
    required this.itemsSold,
  });
}

class HelperProductBreakdownRow {
  final String helperName;
  final String productName;
  final int quantitySold;
  final double totalSales;

  const HelperProductBreakdownRow({
    required this.helperName,
    required this.productName,
    required this.quantitySold,
    required this.totalSales,
  });
}

class HelperTransactionRow {
  final int saleId;
  final String helperName;
  final DateTime dateTime;
  final String timePeriod;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String productSummary;

  const HelperTransactionRow({
    required this.saleId,
    required this.helperName,
    required this.dateTime,
    required this.timePeriod,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.productSummary,
  });
}

class AnalyticsController {
  const AnalyticsController();

  Future<String> exportAnalyticsReport({
    required String period,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final filter = _periodFilter(period, customStartDate, customEndDate);

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

    String periodLabel = period;
    if (period == 'Custom' && customStartDate != null) {
      String formatter(DateTime date) {
        final months = [
          '',
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[date.month]} ${date.day}, ${date.year}';
      }

      if (customEndDate != null && customStartDate != customEndDate) {
        periodLabel =
            '${formatter(customStartDate)} - ${formatter(customEndDate)}';
      } else {
        periodLabel = formatter(customStartDate);
      }
    }

    csv.writeln('Summary,Period,${_csv(periodLabel)}');
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

    String periodSlug = period.toLowerCase().replaceAll(' ', '_');
    if (period == 'Custom' && customStartDate != null) {
      final startStr = customStartDate.toString().split(' ')[0];
      final endStr = customEndDate?.toString().split(' ')[0] ?? startStr;
      periodSlug = 'custom_${startStr}_to_$endStr';
    }

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

  Future<List<String>> getHelperUsernames() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'Users',
      columns: ['username'],
      where: 'role = ?',
      whereArgs: ['Helper'],
      orderBy: 'username COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => (row['username'] ?? '').toString())
        .where((username) => username.isNotEmpty)
        .toList();
  }

  Future<HelperSalesReportData> loadHelperSalesReport({
    required String period,
    String? helperUsername,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final filter = _helperSalesFilter(
      period,
      helperUsername,
      customStartDate,
      customEndDate,
    );

    final summaryRows = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT s.sale_id) AS tx_count,
        COALESCE(SUM(s.total_amount), 0) AS total_sales
      FROM Sales s
      INNER JOIN Users u ON u.user_id = s.user_id
      ${filter.whereClause}
    ''', filter.whereArgs);
    final summaryRow = summaryRows.isNotEmpty
        ? summaryRows.first
        : <String, Object?>{};
    final transactionCount = (summaryRow['tx_count'] as num?)?.toInt() ?? 0;
    final totalSales = (summaryRow['total_sales'] as num?)?.toDouble() ?? 0.0;

    final itemsRows = await db.rawQuery('''
      SELECT COALESCE(SUM(si.quantity), 0) AS items_sold
      FROM SaleItems si
      INNER JOIN Sales s ON s.sale_id = si.sale_id
      INNER JOIN Users u ON u.user_id = s.user_id
      ${filter.whereClause.replaceAll('s.', 's.').replaceAll('u.', 'u.')}
    ''', filter.whereArgs);
    final itemsRow = itemsRows.isNotEmpty
        ? itemsRows.first
        : <String, Object?>{};
    final itemsSold = (itemsRow['items_sold'] as num?)?.toInt() ?? 0;

    final performanceRows = await db.rawQuery('''
      SELECT
        u.username AS helper_name,
        COUNT(DISTINCT s.sale_id) AS tx_count,
        COALESCE(SUM(s.total_amount), 0) AS total_sales
      FROM Sales s
      INNER JOIN Users u ON u.user_id = s.user_id
      ${filter.whereClause}
      GROUP BY u.username
      ORDER BY total_sales DESC, tx_count DESC, helper_name ASC
    ''', filter.whereArgs);

    final performanceItemRows = await db.rawQuery('''
      SELECT
        u.username AS helper_name,
        COALESCE(SUM(si.quantity), 0) AS items_sold
      FROM SaleItems si
      INNER JOIN Sales s ON s.sale_id = si.sale_id
      INNER JOIN Users u ON u.user_id = s.user_id
      ${filter.whereClause}
      GROUP BY u.username
    ''', filter.whereArgs);

    final performanceItemsByHelper = {
      for (final row in performanceItemRows)
        (row['helper_name'] ?? 'Unknown').toString():
            (row['items_sold'] as num?)?.toInt() ?? 0,
    };

    final productRows = await db.rawQuery('''
      SELECT
        u.username AS helper_name,
        p.name AS product_name,
        COALESCE(SUM(si.quantity), 0) AS quantity_sold,
        COALESCE(SUM(si.subtotal), 0) AS total_sales
      FROM SaleItems si
      INNER JOIN Sales s ON s.sale_id = si.sale_id
      INNER JOIN Users u ON u.user_id = s.user_id
      INNER JOIN Products p ON p.product_id = si.product_id
      ${filter.whereClause.replaceAll('s.', 's.').replaceAll('u.', 'u.')}
      GROUP BY u.username, p.product_id, p.name
      ORDER BY u.username ASC, quantity_sold DESC, p.name ASC
    ''', filter.whereArgs);

    final transactionRows = await db.rawQuery('''
      SELECT
        s.sale_id,
        s.date_time,
        u.username AS helper_name,
        s.total_amount,
        COALESCE(pay.method, 'Unknown') AS payment_method,
        COALESCE(pay.status, 'Unknown') AS payment_status,
        GROUP_CONCAT(
          p.name || ' x' || si.quantity || ' = Rs. ' || printf('%.0f', si.subtotal),
          ' | '
        ) AS product_summary
      FROM Sales s
      INNER JOIN Users u ON u.user_id = s.user_id
      LEFT JOIN Payments pay ON pay.sale_id = s.sale_id
      LEFT JOIN SaleItems si ON si.sale_id = s.sale_id
      LEFT JOIN Products p ON p.product_id = si.product_id
      ${filter.whereClause}
      GROUP BY s.sale_id, s.date_time, u.username, s.total_amount, pay.method, pay.status
      ORDER BY s.date_time DESC, s.sale_id DESC
    ''', filter.whereArgs);

    return HelperSalesReportData(
      period: period,
      helperFilterLabel: helperUsername == null || helperUsername.isEmpty
          ? 'All Staff'
          : helperUsername,
      transactionCount: transactionCount,
      totalSales: totalSales,
      itemsSold: itemsSold,
      helperPerformance: performanceRows
          .map(
            (row) => HelperSalesPerformanceRow(
              helperName: (row['helper_name'] ?? 'Unknown').toString(),
              transactionCount: (row['tx_count'] as num?)?.toInt() ?? 0,
              totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0.0,
              itemsSold:
                  performanceItemsByHelper[(row['helper_name'] ?? 'Unknown')
                      .toString()] ??
                  0,
            ),
          )
          .toList(),
      productBreakdown: productRows
          .map(
            (row) => HelperProductBreakdownRow(
              helperName: (row['helper_name'] ?? 'Unknown').toString(),
              productName: (row['product_name'] ?? 'Unknown Product')
                  .toString(),
              quantitySold: (row['quantity_sold'] as num?)?.toInt() ?? 0,
              totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0.0,
            ),
          )
          .toList(),
      transactions: transactionRows
          .map(
            (row) => HelperTransactionRow(
              saleId: (row['sale_id'] as num?)?.toInt() ?? 0,
              helperName: (row['helper_name'] ?? 'Unknown').toString(),
              dateTime:
                  DateTime.tryParse((row['date_time'] ?? '').toString()) ??
                  DateTime.now(),
              timePeriod: _timePeriodLabel(
                DateTime.tryParse((row['date_time'] ?? '').toString()) ??
                    DateTime.now(),
              ),
              totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
              paymentMethod: (row['payment_method'] ?? 'Unknown').toString(),
              paymentStatus: (row['payment_status'] ?? 'Unknown').toString(),
              productSummary: (row['product_summary'] ?? 'No items').toString(),
            ),
          )
          .toList(),
    );
  }

  Future<String> exportHelperSalesReport({
    required String period,
    String? helperUsername,
    DateTime? customStartDate,
    DateTime? customEndDate,
    required String format,
  }) async {
    final report = await loadHelperSalesReport(
      period: period,
      helperUsername: helperUsername,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    final exportDir = await _ensurePublicExportDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final helperSlug = (helperUsername == null || helperUsername.isEmpty)
        ? 'all_helpers'
        : helperUsername.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final periodSlug = period.toLowerCase().replaceAll(' ', '_');
    final baseName = 'helper_sales_${periodSlug}_${helperSlug}_$timestamp';

    switch (format.toLowerCase()) {
      case 'pdf':
        final filePath = p.join(exportDir.path, '$baseName.pdf');
        final bytes = await _buildHelperReportPdf(report);
        await File(filePath).writeAsBytes(bytes);
        return filePath;
      case 'excel':
      case 'xlsx':
        final filePath = p.join(exportDir.path, '$baseName.xlsx');
        final bytes = await _buildHelperReportExcel(report);
        await File(filePath).writeAsBytes(bytes, flush: true);
        return filePath;
      case 'csv':
      default:
        final filePath = p.join(exportDir.path, '$baseName.csv');
        await File(filePath).writeAsString(_buildHelperReportCsv(report));
        return filePath;
    }
  }

  String _buildHelperReportCsv(HelperSalesReportData report) {
    final csv = StringBuffer();
    csv.writeln('Section,Metric,Value');
    csv.writeln('Summary,Period,${_csv(report.period)}');
    csv.writeln('Summary,Staff Filter,${_csv(report.helperFilterLabel)}');
    csv.writeln('Summary,Transactions,${report.transactionCount}');
    csv.writeln('Summary,Total Sales,${report.totalSales.toStringAsFixed(2)}');
    csv.writeln('Summary,Items Sold,${report.itemsSold}');
    csv.writeln('');
    csv.writeln('Staff Performance');
    csv.writeln('Staff,Transactions,Items Sold,Total Sales');
    for (final row in report.helperPerformance) {
      csv.writeln(
        '${_csv(row.helperName)},${row.transactionCount},${row.itemsSold},${row.totalSales.toStringAsFixed(2)}',
      );
    }
    csv.writeln('');

    csv.writeln('Product Breakdown');
    csv.writeln('Staff,Product,Quantity Sold,Total Sales');
    for (final row in report.productBreakdown) {
      csv.writeln(
        '${_csv(row.helperName)},${_csv(row.productName)},${row.quantitySold},${row.totalSales.toStringAsFixed(2)}',
      );
    }
    csv.writeln('');

    csv.writeln('Transaction Details');
    csv.writeln(
      'Sale ID,Staff,Date Time,Payment Method,Payment Status,Total Amount,Product Summary',
    );
    for (final row in report.transactions) {
      csv.writeln(
        '${row.saleId},${_csv(row.helperName)},${_csv(row.dateTime.toIso8601String())},${_csv(row.paymentMethod)},${_csv(row.paymentStatus)},${row.totalAmount.toStringAsFixed(2)},${_csv(row.productSummary)}',
      );
    }

    return csv.toString();
  }

  Future<List<int>> _buildHelperReportPdf(HelperSalesReportData report) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Staff Sales Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Period: ${report.period}'),
          pw.Text('Staff Filter: ${report.helperFilterLabel}'),
          pw.SizedBox(height: 12),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Transactions', 'Total Sales', 'Items Sold'],
            data: [
              [
                report.transactionCount.toString(),
                report.totalSales.toStringAsFixed(2),
                report.itemsSold.toString(),
              ],
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Staff Performance',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Staff',
              'Transactions',
              'Items Sold',
              'Total Sales',
            ],
            data: report.helperPerformance
                .map(
                  (row) => [
                    row.helperName,
                    row.transactionCount.toString(),
                    row.itemsSold.toString(),
                    row.totalSales.toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Product Breakdown',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Helper', 'Product', 'Qty', 'Total'],
            data: report.productBreakdown
                .map(
                  (row) => [
                    row.helperName,
                    row.productName,
                    row.quantitySold.toString(),
                    row.totalSales.toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Sale ID',
              'Helper',
              'Date/Time',
              'Payment',
              'Status',
              'Total',
              'Products',
            ],
            data: report.transactions
                .map(
                  (row) => [
                    row.saleId.toString(),
                    row.helperName,
                    row.dateTime.toIso8601String(),
                    row.paymentMethod,
                    row.paymentStatus,
                    row.totalAmount.toStringAsFixed(2),
                    row.productSummary,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<List<int>> _buildHelperReportExcel(
    HelperSalesReportData report,
  ) async {
    final workbook = excel.Excel.createExcel();
    workbook.delete('Sheet1');

    final summarySheet = workbook['Summary'];
    summarySheet.appendRow([
      excel.TextCellValue('Period'),
      excel.TextCellValue(report.period),
    ]);
    summarySheet.appendRow([
      excel.TextCellValue('Helper Filter'),
      excel.TextCellValue(report.helperFilterLabel),
    ]);
    summarySheet.appendRow([
      excel.TextCellValue('Transactions'),
      excel.IntCellValue(report.transactionCount),
    ]);
    summarySheet.appendRow([
      excel.TextCellValue('Total Sales'),
      excel.DoubleCellValue(report.totalSales),
    ]);
    summarySheet.appendRow([
      excel.TextCellValue('Items Sold'),
      excel.IntCellValue(report.itemsSold),
    ]);

    final helperSheet = workbook['Helper Performance'];
    helperSheet.appendRow([
      excel.TextCellValue('Helper'),
      excel.TextCellValue('Transactions'),
      excel.TextCellValue('Items Sold'),
      excel.TextCellValue('Total Sales'),
    ]);
    for (final row in report.helperPerformance) {
      helperSheet.appendRow([
        excel.TextCellValue(row.helperName),
        excel.IntCellValue(row.transactionCount),
        excel.IntCellValue(row.itemsSold),
        excel.DoubleCellValue(row.totalSales),
      ]);
    }

    final productSheet = workbook['Product Breakdown'];
    productSheet.appendRow([
      excel.TextCellValue('Helper'),
      excel.TextCellValue('Product'),
      excel.TextCellValue('Quantity Sold'),
      excel.TextCellValue('Total Sales'),
    ]);
    for (final row in report.productBreakdown) {
      productSheet.appendRow([
        excel.TextCellValue(row.helperName),
        excel.TextCellValue(row.productName),
        excel.IntCellValue(row.quantitySold),
        excel.DoubleCellValue(row.totalSales),
      ]);
    }

    final transactionSheet = workbook['Transaction Details'];
    transactionSheet.appendRow([
      excel.TextCellValue('Sale ID'),
      excel.TextCellValue('Helper'),
      excel.TextCellValue('Date Time'),
      excel.TextCellValue('Period'),
      excel.TextCellValue('Payment Method'),
      excel.TextCellValue('Payment Status'),
      excel.TextCellValue('Total Amount'),
      excel.TextCellValue('Products'),
    ]);
    for (final row in report.transactions) {
      transactionSheet.appendRow([
        excel.IntCellValue(row.saleId),
        excel.TextCellValue(row.helperName),
        excel.TextCellValue(row.dateTime.toIso8601String()),
        excel.TextCellValue(row.timePeriod),
        excel.TextCellValue(row.paymentMethod),
        excel.TextCellValue(row.paymentStatus),
        excel.DoubleCellValue(row.totalAmount),
        excel.TextCellValue(row.productSummary),
      ]);
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel report');
    }
    return bytes;
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

  _SqlFilter _periodFilter(
    String period,
    DateTime? customStartDate,
    DateTime? customEndDate,
  ) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDateExclusive;

    DateTime startOfDay(DateTime date) =>
        DateTime(date.year, date.month, date.day);
    DateTime nextDayStart(DateTime date) =>
        DateTime(date.year, date.month, date.day).add(const Duration(days: 1));

    if (period == 'Today') {
      startDate = startOfDay(now);
      endDateExclusive = nextDayStart(now);
    } else if (period == 'This Week') {
      startDate = startOfDay(now).subtract(Duration(days: now.weekday - 1));
      endDateExclusive = nextDayStart(now);
    } else if (period == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
      endDateExclusive = nextDayStart(now);
    } else if (period == 'Custom') {
      startDate = customStartDate == null ? null : startOfDay(customStartDate);
      final rawEndDate = customEndDate ?? customStartDate;
      endDateExclusive = rawEndDate == null ? null : nextDayStart(rawEndDate);

      if (startDate == null) {
        return const _SqlFilter(whereClause: '', whereArgs: []);
      }
    }

    if (startDate == null) {
      return const _SqlFilter(whereClause: '', whereArgs: []);
    }

    endDateExclusive ??= nextDayStart(now);

    return _SqlFilter(
      whereClause: 'WHERE s.date_time >= ? AND s.date_time < ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDateExclusive.toIso8601String(),
      ],
    );
  }

  _SqlFilter _helperSalesFilter(
    String period,
    String? helperUsername,
    DateTime? customStartDate,
    DateTime? customEndDate,
  ) {
    // Include both Helper and Owner roles so reports cover all staff
    final clauses = <String>['u.role IN (?, ?)'];
    final args = <Object?>['Helper', 'Owner'];

    final periodFilter = _periodFilter(period, customStartDate, customEndDate);
    if (periodFilter.whereClause.isNotEmpty) {
      clauses.add(periodFilter.whereClause.replaceFirst('WHERE ', ''));
      args.addAll(periodFilter.whereArgs);
    }

    if (helperUsername != null && helperUsername.isNotEmpty) {
      clauses.add('u.username = ?');
      args.add(helperUsername);
    }

    return _SqlFilter(
      whereClause: 'WHERE ${clauses.join(' AND ')}',
      whereArgs: args,
    );
  }

  String _timePeriodLabel(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 20) return 'Evening';
    return 'Night';
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
    await db.delete('SaleItems', where: 'sale_id = ?', whereArgs: [saleId]);

    await db.delete('Payments', where: 'sale_id = ?', whereArgs: [saleId]);

    await db.delete('Sales', where: 'sale_id = ?', whereArgs: [saleId]);
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
    await db.delete('SaleItems', where: 'sale_id = ?', whereArgs: [saleId]);

    await db.delete('Payments', where: 'sale_id = ?', whereArgs: [saleId]);

    await db.delete('Sales', where: 'sale_id = ?', whereArgs: [saleId]);
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
      await db
          .insert('TransactionDeletionLog', {
            'sale_id': saleId,
            'amount': amount,
            'payment_method': paymentMethod,
            'item_count': itemCount,
            'deleted_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace)
          .catchError((_) {
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
