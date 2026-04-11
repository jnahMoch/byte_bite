import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../model/pos_item_model.dart';
import '../../../model/sales_transaction_model.dart';
import '../../../data/inventory_data.dart';
import '../../../data/sales_data.dart';
import '../../../database_helper.dart';

class HelperPOSGridView extends StatefulWidget {
  const HelperPOSGridView({super.key});

  @override
  State<HelperPOSGridView> createState() => _HelperPOSGridViewState();
}

class CartItem {
  final POSItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  int get total => item.price * quantity;
}

class _HelperPOSGridViewState extends State<HelperPOSGridView> {
  String _selectedCategory = 'All';
  String _selectedPayment = 'Cash';
  final List<CartItem> _cart = [];
  final TextEditingController _amountPaidController = TextEditingController();
  double _change = 0;
  bool _isCartExpanded = false;

  @override
  void initState() {
    super.initState();
    _amountPaidController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _amountPaidController.removeListener(_calculateChange);
    _amountPaidController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    double? amountPaid = double.tryParse(_amountPaidController.text);
    setState(() {
      if (amountPaid != null && amountPaid >= cartTotal) {
        _change = amountPaid - cartTotal;
      } else {
        _change = 0;
      }
    });
  }

  List<POSItem> get filteredItems {
    if (_selectedCategory == 'All') return InventoryData.items;
    return InventoryData.items
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  int get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  void _addToCart(POSItem item) {
    setState(() {
      final existingIndex = _cart.indexWhere((c) => c.item.name == item.name);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(item: item));
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  Future<int> _resolveProductId(POSItem item) async {
    if (item.productId != null) return item.productId!;

    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'Products',
      columns: ['product_id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [item.name],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return (existing.first['product_id'] as num).toInt();
    }

    final insertedId = await DatabaseHelper.instance.insertProduct({
      'name': item.name,
      'category': item.category,
      'price': item.price.toDouble(),
      'stock_quantity': item.stock,
      'min_threshold': item.lowStockAlert,
      'description': null,
    });
    return insertedId;
  }

  Future<void> _completeTransaction() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? amountPaid = double.tryParse(_amountPaidController.text);
    if (amountPaid == null || amountPaid < cartTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient payment amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double change = amountPaid - cartTotal;
    final now = DateTime.now();
    final receiptNumber = now.millisecondsSinceEpoch.toString();
    final savedCart = List<CartItem>.from(_cart);
    final savedTotal = cartTotal;

    for (var cartItem in _cart) {
      cartItem.item.stock -= cartItem.quantity;
    }

    // add to in‑memory list as before
    SalesData.addTransaction(
      SalesTransaction(
        receiptNumber: receiptNumber,
        dateTime: now,
        items: savedCart
            .map(
              (c) => {
                'name': c.item.name,
                'price': c.item.price,
                'quantity': c.quantity,
              },
            )
            .toList(),
        total: savedTotal,
        amountPaid: amountPaid,
        change: change,
        paymentMethod: _selectedPayment,
      ),
    );

    // persist the sale to the SQLite database with cart items
    try {
      // Build items list with resolved product IDs to avoid seed-product fallback.
      final itemsForDB = <Map<String, dynamic>>[];
      for (final cartItem in savedCart) {
        final productId = await _resolveProductId(cartItem.item);
        itemsForDB.add({
          'product_id': productId,
          'quantity': cartItem.quantity,
          'subtotal': (cartItem.item.price * cartItem.quantity).toDouble(),
        });
      }

      await DatabaseHelper.instance.recordSale(
        userId: 1,
        totalAmount: savedTotal.toDouble(),
        items: itemsForDB,
        paymentMethod: _selectedPayment,
        paymentStatus: 'Success',
      );
    } catch (e) {
      debugPrint('helper_pos_grid_view recordSale failed: $e');
    }

    _showSaleSuccessDialog(
      savedCart,
      savedTotal,
      amountPaid,
      change,
      now,
      receiptNumber,
    );
  }

  void _showSaleSuccessDialog(
    List<CartItem> savedCart,
    int savedTotal,
    double amountPaid,
    double change,
    DateTime now,
    String receiptNumber,
  ) {
    bool isPrintingStarted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 700, maxWidth: 420),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00A86B), Color(0xFF008450)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Transaction Successful!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Receipt #$receiptNumber',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (var item in savedCart) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.item.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.quantity} x ₱${item.item.price}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₱${item.total}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF009661),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₱$savedTotal',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount Paid',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₱${amountPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF009661),
                              ),
                            ),
                            Text(
                              '₱${change.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF009661),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Payment: $_selectedPayment',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy hh:mm a').format(now),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isPrintingStarted
                            ? null
                            : () async {
                                setDialogState(() => isPrintingStarted = true);
                                try {
                                  final pdf = _generatePDF(
                                    receiptNumber,
                                    now,
                                    savedCart,
                                    savedTotal,
                                  );
                                  await Printing.layoutPdf(
                                    onLayout: (format) async => pdf.save(),
                                  );
                                } catch (e) {
                                  debugPrint('Print error: $e');
                                }
                                if (mounted) {
                                  setDialogState(
                                    () => isPrintingStarted = false,
                                  );
                                }
                              },
                        icon: const Icon(Icons.print),
                        label: const Text('Print Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009661),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _cart.clear();
                            _amountPaidController.clear();
                            _change = 0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: const Color(0xFF1A1A2E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('New Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  pw.Document _generatePDF(
    String receiptNumber,
    DateTime dateTime,
    List<CartItem> items,
    int total,
  ) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) => pw.Column(
          children: [
            pw.Text(
              'Byte & Bite POS',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Receipt #$receiptNumber'),
            pw.Text(dateTime.toString()),
            pw.SizedBox(height: 10),
            pw.Divider(),
            for (var item in items) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item.item.name} x${item.quantity}'),
                  pw.Text('₱${item.total}'),
                ],
              ),
            ],
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('₱$total'),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _tab("All"),
              const SizedBox(width: 10),
              _tab("Food"),
              const SizedBox(width: 10),
              _tab("Beverage"),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) =>
                      _itemCard(filteredItems[index]),
                ),
              ),
              if (_cart.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCartExpanded = !_isCartExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: const Color(
                                0xFF009661,
                              ).withValues(alpha: 0.05),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.shopping_cart,
                                        color: Color(0xFF009661),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cart (${_cart.length} items)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF009661),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '₱$cartTotal',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _isCartExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: const Color(0xFF009661),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isCartExpanded) ...[
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  for (int i = 0; i < _cart.length; i++)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Product image or icon
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF009661,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.shopping_bag,
                                              color: const Color(0xFF009661),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Product info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _cart[i].item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₱${_cart[i].item.price} each',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Quantity and price
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₱${_cart[i].total}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF009661),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF009661,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _updateQuantity(
                                                            i,
                                                            -1,
                                                          ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 3,
                                                            ),
                                                        child: const Icon(
                                                          Icons.remove,
                                                          size: 14,
                                                          color: Color(
                                                            0xFF009661,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      child: Text(
                                                        '${_cart[i].quantity}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _updateQuantity(i, 1),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 3,
                                                            ),
                                                        child: const Icon(
                                                          Icons.add,
                                                          size: 14,
                                                          color: Color(
                                                            0xFF009661,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _removeFromCart(i),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  // Total Amount Due
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF009661,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF009661,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Amount Due',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        Text(
                                          '₱$cartTotal',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF009661),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _selectedPayment = 'Cash',
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _selectedPayment == 'Cash'
                                                  ? const Color(0xFF009661)
                                                  : Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    _selectedPayment == 'Cash'
                                                    ? const Color(0xFF009661)
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.wallet,
                                                  color:
                                                      _selectedPayment == 'Cash'
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Cash',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        _selectedPayment ==
                                                            'Cash'
                                                        ? Colors.white
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _selectedPayment = 'QR Code',
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _selectedPayment == 'QR Code'
                                                  ? const Color(0xFF009661)
                                                  : Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    _selectedPayment ==
                                                        'QR Code'
                                                    ? const Color(0xFF009661)
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.qr_code,
                                                  color:
                                                      _selectedPayment ==
                                                          'QR Code'
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'QR Code',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        _selectedPayment ==
                                                            'QR Code'
                                                        ? Colors.white
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _amountPaidController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      labelText: 'Amount Paid',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF009661,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Change: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '₱${_change.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Color(0xFF009661),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _completeTransaction,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF009661,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Complete Transaction',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab(String label) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedCategory == label
              ? const Color(0xFF009661)
              : Colors.transparent,
          border: Border.all(
            color: _selectedCategory == label
                ? const Color(0xFF009661)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _selectedCategory == label ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _itemCard(POSItem item) {
    final isFood = item.category == 'Food';
    final iconData = isFood
        ? Icons.restaurant_rounded
        : Icons.local_cafe_rounded;
    final iconColor = isFood
        ? const Color(0xFFEF4444)
        : const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () => _addToCart(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildItemImage(
                  imagePathOrUrl: item.image,
                  iconData: iconData,
                  iconColor: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '₱${item.price}',
                    style: const TextStyle(
                      color: Color(0xFF009661),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${item.stock} ${item.unit}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage({
    required String? imagePathOrUrl,
    required IconData iconData,
    required Color iconColor,
  }) {
    Widget fallbackIcon() =>
        Center(child: Icon(iconData, size: 40, color: iconColor));

    if (imagePathOrUrl == null || imagePathOrUrl.trim().isEmpty) {
      return fallbackIcon();
    }

    final imageRef = imagePathOrUrl.trim();
    final parsed = Uri.tryParse(imageRef);
    final isNetwork =
        parsed != null && (parsed.scheme == 'http' || parsed.scheme == 'https');

    if (isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageRef,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallbackIcon(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            );
          },
        ),
      );
    }

    final file = File(imageRef);
    if (!file.existsSync()) {
      return fallbackIcon();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackIcon(),
      ),
    );
  }
}

class DateFormat {
  DateFormat(String format);

  String format(DateTime date) {
    final months = [
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
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year $hour:$minute $ampm';
  }
}
