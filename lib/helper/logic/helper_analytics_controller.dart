import '../../database_helper.dart';

class HelperAnalyticsSummary {
  final int transactionCount;
  final double totalSales;
  final double avgSale;
  final int itemsSold;

  const HelperAnalyticsSummary({
    required this.transactionCount,
    required this.totalSales,
    required this.avgSale,
    required this.itemsSold,
  });
}

class HelperAnalyticsController {
  const HelperAnalyticsController();

  static bool _paidAtColumnEnsured = false;

  Future<HelperAnalyticsSummary> loadSummary(
    String period, {
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    await _ensurePaidAtColumn();

    final db = await DatabaseHelper.instance.database;
    final salesFilter = _periodFilter(period, customStartDate, customEndDate);

    final transactionRows = await db.rawQuery('''
      SELECT
        COUNT(*) AS tx_count,
        COALESCE(SUM(total_amount), 0) AS total_sales
      FROM Sales
      ${salesFilter.whereClause}
      ''', salesFilter.whereArgs);
    final transactionRow = transactionRows.isNotEmpty
        ? transactionRows.first
        : <String, Object?>{};
    final transactionCount = (transactionRow['tx_count'] as num?)?.toInt() ?? 0;
    final totalSales =
        (transactionRow['total_sales'] as num?)?.toDouble() ?? 0.0;

    final itemsRows = await db.rawQuery('''
      SELECT COALESCE(SUM(si.quantity), 0) AS items_sold
      FROM SaleItems si
      INNER JOIN Sales s ON s.sale_id = si.sale_id
      ${salesFilter.whereClause.replaceAll('date_time', 's.date_time')}
      ''', salesFilter.whereArgs);
    final itemsRow = itemsRows.isNotEmpty
        ? itemsRows.first
        : <String, Object?>{};
    final itemsSold = (itemsRow['items_sold'] as num?)?.toInt() ?? 0;
    final avgSale = transactionCount > 0 ? totalSales / transactionCount : 0.0;

    return HelperAnalyticsSummary(
      transactionCount: transactionCount,
      totalSales: totalSales,
      avgSale: avgSale,
      itemsSold: itemsSold,
    );
  }

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

  _DateFilter _periodFilter(
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
        return const _DateFilter(whereClause: '', whereArgs: []);
      }
    }

    if (startDate == null) {
      return const _DateFilter(whereClause: '', whereArgs: []);
    }

    endDateExclusive ??= nextDayStart(now);

    return _DateFilter(
      whereClause: 'WHERE date_time >= ? AND date_time < ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDateExclusive.toIso8601String(),
      ],
    );
  }
}

class _DateFilter {
  final String whereClause;
  final List<Object?> whereArgs;

  const _DateFilter({required this.whereClause, required this.whereArgs});
}
