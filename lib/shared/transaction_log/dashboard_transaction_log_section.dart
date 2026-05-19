import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../database_helper.dart';
import '../../user_storage.dart';

enum _DateFilter { all, today, week, month }

enum _SortOption { newest, oldest, amountHigh, amountLow, cashier, status }

class DashboardTransactionLogSection extends StatefulWidget {
  final String role;

  const DashboardTransactionLogSection({super.key, required this.role});

  bool get isOwner => role == 'Owner';

  @override
  State<DashboardTransactionLogSection> createState() =>
      _DashboardTransactionLogSectionState();
}

class _DashboardTransactionLogSectionState
    extends State<DashboardTransactionLogSection> {
  static const Color _green = Color(0xFF009661);
  static const Color _pageBg = Colors.white;
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE3EBE6);
  static const Color _dark = Color(0xFF18212F);
  static const Color _coolBlue = Color(0xFF2563EB);
  static const Color _coolTeal = Color(0xFF0F766E);
  static const Color _slate = Color(0xFF475569);

  final _controller = const _DashboardTransactionController();
  final _searchController = TextEditingController();

  List<_DashboardTransactionEntry> _entries = [];
  _DashboardTransactionEntry? _selectedEntry;
  String _query = '';
  String _helperFilter = 'All';
  String _paymentFilter = 'All';
  _DateFilter _dateFilter = _DateFilter.all;
  _SortOption _sortOption = _SortOption.newest;
  int _page = 0;
  bool _loading = true;

  static const int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    debugPrint(
      '[TLog] _load() called, currentUser=${UserStorage.currentUser}, currentRole=${UserStorage.currentUserRole}',
    );

    // DEBUG: Check total transactions in database
    final db = await DatabaseHelper.instance.database;
    final totalCount = await db.rawQuery('SELECT COUNT(*) as count FROM Sales');
    debugPrint(
      '[TLog] Total transactions in database: ${totalCount.first['count']}',
    );

    final entries = await _controller.loadTransactions(
      isOwner: widget.isOwner,
      username: UserStorage.currentUser ?? '',
    );
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _selectedEntry = entries.isEmpty ? null : _selectedEntry ?? entries.first;
      _loading = false;
    });
  }

  List<_DashboardTransactionEntry> get _filteredEntries {
    final now = DateTime.now();
    final filtered = _entries.where((entry) {
      final matchesQuery =
          _query.isEmpty ||
          entry.transactionId.toLowerCase().contains(_query) ||
          entry.cashierName.toLowerCase().contains(_query) ||
          entry.productSummary.toLowerCase().contains(_query);
      final matchesHelper =
          !widget.isOwner ||
          _helperFilter == 'All' ||
          entry.cashierName == _helperFilter;
      final matchesPayment =
          _paymentFilter == 'All' || entry.paymentMethod == _paymentFilter;
      final matchesDate = switch (_dateFilter) {
        _DateFilter.all => true,
        _DateFilter.today => _isSameDay(entry.dateTime, now),
        _DateFilter.week => entry.dateTime.isAfter(
          now.subtract(const Duration(days: 7)),
        ),
        _DateFilter.month =>
          entry.dateTime.year == now.year && entry.dateTime.month == now.month,
      };
      return matchesQuery && matchesHelper && matchesPayment && matchesDate;
    }).toList();

    filtered.sort((a, b) {
      return switch (_sortOption) {
        _SortOption.newest => b.dateTime.compareTo(a.dateTime),
        _SortOption.oldest => a.dateTime.compareTo(b.dateTime),
        _SortOption.amountHigh => b.totalAmount.compareTo(a.totalAmount),
        _SortOption.amountLow => a.totalAmount.compareTo(b.totalAmount),
        _SortOption.cashier => a.cashierName.compareTo(b.cashierName),
        _SortOption.status => a.status.compareTo(b.status),
      };
    });

    return filtered;
  }

  List<_DashboardTransactionEntry> get _pageEntries {
    final filtered = _filteredEntries;
    final start = _page * _pageSize;
    if (start >= filtered.length) return const [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  _DashboardTransactionSummary get _summary =>
      _DashboardTransactionSummary.fromEntries(_filteredEntries);

  List<String> get _helpers {
    final values =
        _entries
            .map((e) => e.cashierName)
            .where((name) => name != 'Default Owner')
            .toSet()
            .toList()
          ..sort();
    return ['All', ...values];
  }

  int get _pageCount {
    final count = (_filteredEntries.length / _pageSize).ceil();
    return count == 0 ? 1 : count;
  }

  Stream<Object?> _refreshStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<Object?>.periodic(const Duration(seconds: 5));
    }
    return FirebaseFirestore.instance.collection('transactions').snapshots();
  }

  Future<void> _exportTransactions() async {
    if (!widget.isOwner || _filteredEntries.isEmpty) return;

    final rows = [
      [
        'Transaction ID',
        'Date & Time',
        'Cashier',
        'Products',
        'Quantity',
        'Total Amount',
        'Payment Method',
        'Status',
      ],
      ..._filteredEntries.map(
        (entry) => [
          entry.transactionId,
          _formatDateTime(entry.dateTime),
          entry.cashierName,
          entry.productSummary,
          entry.totalQuantity,
          entry.totalAmount.toStringAsFixed(2),
          entry.paymentMethod,
          entry.status,
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/byte_bite_dashboard_transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);
    // ignore: deprecated_member_use
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Byte & Bite Dashboard Transaction Log');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object?>(
      stream: _refreshStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_loading) {
          scheduleMicrotask(_load);
        }

        final filtered = _filteredEntries;
        final accessText = widget.isOwner
            ? 'Owner = Full Access'
            : 'Helper = Own Transactions Only';

        return Container(
          color: _pageBg,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.manage_search_outlined, color: _green),
                    const SizedBox(width: 8),
                    _accessPill(accessText),
                  ],
                ),
                const SizedBox(height: 12),
                _summaryCards(),
                const SizedBox(height: 12),
                _filters(),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;
                      final table = _transactionTable(filtered);
                      final preview = _receiptPreview();
                      if (!wide) {
                        return Column(
                          children: [
                            table,
                            const SizedBox(height: 12),
                            preview,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: table),
                          const SizedBox(width: 12),
                          Expanded(flex: 1, child: preview),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCards() {
    final summary = _summary;
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width < 720 ? 2 : 5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: MediaQuery.of(context).size.width < 720 ? 1.35 : 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(
          'Total Transactions',
          '${summary.totalTransactions}',
          Icons.receipt_long_outlined,
          _green,
        ),
        _summaryCard(
          'Total Sales',
          _currency(summary.totalSales),
          Icons.trending_up,
          _coolBlue,
        ),
        _summaryCard(
          'Cash Sales',
          _currency(summary.cashSales),
          Icons.payments_outlined,
          _coolTeal,
        ),
        _summaryCard(
          'QR/Online Sales',
          _currency(summary.qrSales),
          Icons.qr_code_2_outlined,
          _slate,
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search transactions',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {
                _query = value.trim().toLowerCase();
                _page = 0;
              }),
            ),
          ),
          _dropdown<_DateFilter>(
            value: _dateFilter,
            items: _DateFilter.values,
            label: _dateLabel,
            onChanged: (value) => setState(() {
              _dateFilter = value ?? _DateFilter.all;
              _page = 0;
            }),
          ),
          if (widget.isOwner)
            _dropdown<String>(
              value: _helpers.contains(_helperFilter) ? _helperFilter : 'All',
              items: _helpers,
              label: (value) => value,
              onChanged: (value) => setState(() {
                _helperFilter = value ?? 'All';
                _page = 0;
              }),
            ),
          _dropdown<String>(
            value: _paymentFilter,
            items: const ['All', 'Cash', 'QR'],
            label: (value) => value,
            onChanged: (value) => setState(() {
              _paymentFilter = value ?? 'All';
              _page = 0;
            }),
          ),
          _dropdown<_SortOption>(
            value: _sortOption,
            items: _SortOption.values,
            label: _sortLabel,
            onChanged: (value) => setState(() {
              _sortOption = value ?? _SortOption.newest;
              _page = 0;
            }),
          ),
          if (widget.isOwner)
            FilledButton.icon(
              onPressed: _filteredEntries.isEmpty ? null : _exportTransactions,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export'),
            ),
        ],
      ),
    );
  }

  Widget _transactionTable(List<_DashboardTransactionEntry> filtered) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DataTable(
                columnSpacing: 18,
                horizontalMargin: 12,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _green.withValues(alpha: 0.15);
                  }
                  return null;
                }),
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                dividerThickness: 0.5,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F1724),
                ),
                columns: const [
                  DataColumn(label: Text('Transaction ID')),
                  DataColumn(label: Text('Date & Time')),
                  DataColumn(label: Text('Helper/Cashier')),
                  DataColumn(label: Text('Products Purchased')),
                  DataColumn(label: Text('Qty')),
                  DataColumn(label: Text('Total Amount')),
                  DataColumn(label: Text('Amount Received')),
                  DataColumn(label: Text('Change')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Receipt')),
                ],
                rows: _pageEntries.map((entry) {
                  return DataRow(
                    selected: _selectedEntry?.saleId == entry.saleId,
                    onSelectChanged: (_) =>
                        setState(() => _selectedEntry = entry),
                    cells: [
                      DataCell(Text(entry.transactionId)),
                      DataCell(Text(_formatDateTime(entry.dateTime))),
                      DataCell(Text(entry.cashierName)),
                      DataCell(
                        SizedBox(
                          width: 260,
                          child: Text(
                            entry.productSummary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${entry.totalQuantity}')),
                      DataCell(Text(_currency(entry.totalAmount))),
                      DataCell(Text(_currency(entry.amountReceived))),
                      DataCell(Text(_currency(entry.changeAmount))),
                      DataCell(
                        _pill(
                          entry.paymentMethod,
                          _paymentColor(entry.paymentMethod),
                        ),
                      ),
                      DataCell(_pill(entry.status, _statusColor(entry.status))),
                      DataCell(
                        OutlinedButton.icon(
                          onPressed: () => _showReceiptModal(context, entry),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(64, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(
                              color: _dark.withValues(alpha: 0.08),
                            ),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('View'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No transactions match the current filters',
                style: TextStyle(color: _dark.withValues(alpha: 0.65)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Page ${_page + 1} of $_pageCount',
                  style: TextStyle(color: _dark.withValues(alpha: 0.75)),
                ),
                IconButton(
                  onPressed: _page == 0 ? null : () => setState(() => _page--),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _page >= _pageCount - 1
                      ? null
                      : () => setState(() => _page++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptPreview() {
    final entry = _selectedEntry;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: entry == null
          ? const Text('Select a transaction to preview receipt details')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipt Preview',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _detail('Transaction', entry.transactionId),
                _detail('Date', _formatDateTime(entry.dateTime)),
                _detail('Cashier', entry.cashierName),
                _detail('Payment', entry.paymentMethod),
                _detail('Status', entry.status),
                const Divider(height: 24),
                ...entry.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.productName} x${item.quantity}'),
                        ),
                        Text(_currency(item.subtotal)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                _detail('Amount Received', _currency(entry.amountReceived)),
                _detail('Change', _currency(entry.changeAmount)),
                const Divider(height: 8),
                _detail('Total', _currency(entry.totalAmount), bold: true),
              ],
            ),
    );
  }

  void _showReceiptModal(
    BuildContext context,
    _DashboardTransactionEntry entry,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detail('Transaction', entry.transactionId),
              _detail('Date', _formatDateTime(entry.dateTime)),
              _detail('Cashier', entry.cashierName),
              _detail('Payment', entry.paymentMethod),
              _detail('Status', entry.status),
              const Divider(height: 24),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...entry.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.productName} x${item.quantity}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        _currency(item.subtotal),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              _detail('Amount Received', _currency(entry.amountReceived)),
              _detail('Change', _currency(entry.changeAmount)),
              const Divider(height: 8),
              _detail('Total', _currency(entry.totalAmount), bold: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: _dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _green,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isDense: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(value: item, child: Text(label(item))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _dateLabel(_DateFilter value) => switch (value) {
    _DateFilter.all => 'All Dates',
    _DateFilter.today => 'Today',
    _DateFilter.week => 'Last 7 Days',
    _DateFilter.month => 'This Month',
  };

  String _sortLabel(_SortOption value) => switch (value) {
    _SortOption.newest => 'Newest',
    _SortOption.oldest => 'Oldest',
    _SortOption.amountHigh => 'Amount High',
    _SortOption.amountLow => 'Amount Low',
    _SortOption.cashier => 'Cashier',
    _SortOption.status => 'Status',
  };
}

class _DashboardTransactionController {
  const _DashboardTransactionController();

  Future<List<_DashboardTransactionEntry>> loadTransactions({
    required bool isOwner,
    required String username,
  }) async {
    final db = await DatabaseHelper.instance.database;
    debugPrint(
      '[TLog] Loading transactions: isOwner=$isOwner, username=$username',
    );

    final rows = await db.rawQuery('''
      SELECT
        s.sale_id,
        s.date_time,
        s.total_amount,
        s.amount_received,
        s.change_amount,
        s.transaction_status,
        u.name AS cashier_name,
        u.username AS cashier_username,
        pay.method AS payment_method,
        pay.status AS payment_status
      FROM Sales s
      INNER JOIN Users u ON u.user_id = s.user_id
      LEFT JOIN Payments pay ON pay.sale_id = s.sale_id
      ${isOwner ? '' : 'WHERE u.username = ?'}
      ORDER BY s.date_time DESC, s.sale_id DESC
      ''', isOwner ? const [] : [username]);

    debugPrint('[TLog] Query returned ${rows.length} rows');

    final entries = <_DashboardTransactionEntry>[];
    for (final row in rows) {
      final saleId = (row['sale_id'] as num?)?.toInt();
      if (saleId == null) continue;

      final itemRows = await db.rawQuery(
        '''
        SELECT
          si.quantity,
          si.subtotal,
          p.name AS product_name,
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
        return _DashboardTransactionItem(
          productName: (itemRow['product_name'] ?? 'Item').toString(),
          quantity: quantity,
          unitPrice:
              (itemRow['price'] as num?)?.toDouble() ??
              (quantity == 0 ? 0 : subtotal / quantity),
          subtotal: subtotal,
        );
      }).toList();

      final paymentStatus = (row['payment_status'] ?? '').toString();
      entries.add(
        _DashboardTransactionEntry(
          saleId: saleId,
          transactionId: 'TXN-${saleId.toString().padLeft(6, '0')}',
          dateTime:
              DateTime.tryParse((row['date_time'] ?? '').toString()) ??
              DateTime.now(),
          cashierName:
              (row['cashier_name'] ?? row['cashier_username'] ?? 'User')
                  .toString(),
          paymentMethod: _normalizePaymentMethod(
            (row['payment_method'] ?? 'Cash').toString(),
          ),
          status: _normalizeStatus(
            (row['transaction_status'] ?? '').toString(),
            paymentStatus,
          ),
          totalAmount: (row['total_amount'] as num?)?.toDouble() ?? 0.0,
          amountReceived: (row['amount_received'] as num?)?.toDouble() ?? 0.0,
          changeAmount: (row['change_amount'] as num?)?.toDouble() ?? 0.0,
          items: items,
        ),
      );
    }

    debugPrint('[TLog] Loaded ${entries.length} transaction entries');
    return entries;
  }

  static String _normalizePaymentMethod(String method) {
    final clean = method.trim();
    if (clean == 'GCash') return 'QR';
    if (clean == 'Card') return 'Card';
    if (clean == 'QR') return 'QR';
    return 'Cash';
  }

  static String _normalizeStatus(
    String transactionStatus,
    String paymentStatus,
  ) {
    if (transactionStatus == 'Refunded' || paymentStatus == 'Refunded') {
      return 'Refunded';
    }
    if (transactionStatus == 'Cancelled' || paymentStatus == 'Failed') {
      return 'Cancelled';
    }
    return 'Completed';
  }
}

class _DashboardTransactionEntry {
  final int saleId;
  final String transactionId;
  final DateTime dateTime;
  final String cashierName;
  final String paymentMethod;
  final String status;
  final double totalAmount;
  final double amountReceived;
  final double changeAmount;
  final List<_DashboardTransactionItem> items;

  const _DashboardTransactionEntry({
    required this.saleId,
    required this.transactionId,
    required this.dateTime,
    required this.cashierName,
    required this.paymentMethod,
    required this.status,
    required this.totalAmount,
    required this.amountReceived,
    required this.changeAmount,
    required this.items,
  });

  // ignore: avoid_types_as_parameter_names
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  String get productSummary {
    if (items.isEmpty) return 'No item details';
    return items
        .map((item) => '${item.productName} x${item.quantity}')
        .join(', ');
  }
}

class _DashboardTransactionItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const _DashboardTransactionItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });
}

class _DashboardTransactionSummary {
  final int totalTransactions;
  final double totalSales;
  final double cashSales;
  final double qrSales;
  final int cancelledOrRefunded;

  const _DashboardTransactionSummary({
    required this.totalTransactions,
    required this.totalSales,
    required this.cashSales,
    required this.qrSales,
    required this.cancelledOrRefunded,
  });

  factory _DashboardTransactionSummary.fromEntries(
    List<_DashboardTransactionEntry> entries,
  ) {
    double totalSales = 0;
    double cashSales = 0;
    double qrSales = 0;
    int cancelledOrRefunded = 0;

    for (final entry in entries) {
      if (entry.status == 'Cancelled' || entry.status == 'Refunded') {
        cancelledOrRefunded++;
        continue;
      }
      totalSales += entry.totalAmount;
      if (entry.paymentMethod == 'Cash') cashSales += entry.totalAmount;
      if (entry.paymentMethod == 'QR') qrSales += entry.totalAmount;
    }

    return _DashboardTransactionSummary(
      totalTransactions: entries.length,
      totalSales: totalSales,
      cashSales: cashSales,
      qrSales: qrSales,
      cancelledOrRefunded: cancelledOrRefunded,
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute $suffix';
}

String _currency(double value) => 'PHP ${value.toStringAsFixed(2)}';

Color _statusColor(String status) {
  return switch (status) {
    'Completed' => const Color(0xFF009661),
    'Refunded' => const Color(0xFF475569),
    'Cancelled' => const Color(0xFFDC2626),
    _ => const Color(0xFF667085),
  };
}

Color _paymentColor(String method) {
  return switch (method) {
    'Cash' => const Color(0xFF0F766E),
    'QR' => const Color(0xFF2563EB),
    'Card' => const Color(0xFF2563EB),
    _ => const Color(0xFF667085),
  };
}
