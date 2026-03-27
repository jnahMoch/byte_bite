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

class POSGridView extends StatefulWidget {
  const POSGridView({super.key});

  @override
  State<POSGridView> createState() => _POSGridViewState();
}

class CartItem {
  final POSItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  int get total => item.price * quantity;
}

class _POSGridViewState extends State<POSGridView> {
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
        userId: 1, // replace with actual current user id if available
        totalAmount: savedTotal.toDouble(),
        items: itemsForDB,
        paymentMethod: _selectedPayment,
        paymentStatus: 'Success',
      );
    } catch (e) {
      debugPrint('pos_grid_view recordSale failed: $e');
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
                // Premium Header
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
                      const Text(
                        'BYTE & BITE',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'OFFICIAL RECEIPT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Receipt #: $receiptNumber',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Receipt Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Transaction Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(now),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(now),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Payment',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _selectedPayment,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Items Section Header
                          const Text(
                            'ITEMS PURCHASED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Items List
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              children: [
                                ...savedCart.asMap().entries.map((entry) {
                                  final item = entry.value;
                                  final isLast =
                                      entry.key == savedCart.length - 1;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.item.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'P${item.item.price}.00 × ${item.quantity}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              'P${item.total}.00',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!isLast)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                            ),
                                            child: Divider(
                                              height: 1,
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Summary Section
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Subtotal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'P$savedTotal.00',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Amount Paid',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'P${amountPaid.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'CHANGE',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00A86B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Text(
                                      'P${change.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF00A86B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Thank You Message
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Thank you for your purchase!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Text(
                                  'Come again soon!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isPrintingStarted
                              ? null
                              : () async {
                                  setDialogState(
                                    () => isPrintingStarted = true,
                                  );
                                  await _printReceipt(
                                    cartItems: savedCart,
                                    total: savedTotal,
                                    paid: amountPaid,
                                    change: change,
                                    receiptNumber: receiptNumber,
                                    paymentMethod: _selectedPayment,
                                    date: now,
                                  );
                                  if (ctx.mounted) {
                                    setDialogState(
                                      () => isPrintingStarted = false,
                                    );
                                  }
                                },
                          icon: Icon(
                            isPrintingStarted
                                ? Icons.hourglass_bottom
                                : Icons.print_outlined,
                            size: 18,
                          ),
                          label: Text(
                            isPrintingStarted ? 'Printing...' : 'Print',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00A86B),
                            disabledForegroundColor: Colors.grey[300],
                            side: BorderSide(
                              color: isPrintingStarted
                                  ? Colors.grey[300]!
                                  : const Color(0xFF00A86B),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _cart.clear();
                              _amountPaidController.clear();
                              _change = 0;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A86B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
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

  Future<void> _printReceipt({
    required List<CartItem> cartItems,
    required int total,
    required double paid,
    required double change,
    required String receiptNumber,
    required String paymentMethod,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'BYTE & BITE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Smart POS Solution',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Visayan Village, Tagum City',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Date: ${_formatDate(date)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Time: ${_formatTime(date)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Receipt #: $receiptNumber',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Payment: $paymentMethod',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              // Items
              ...cartItems.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          item.item.name,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'P${item.item.price}.00',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'x${item.quantity}',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey,
                          ),
                        ),
                        pw.Text(
                          'P${item.total}.00',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'P$total.00',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Amount Paid:',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'P${paid.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    'P${change.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),
              pw.Text(
                'Thank you for your purchase!',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Come again soon!',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 16),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
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
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _isCartExpanded
                                        ? Icons.keyboard_arrow_down
                                        : Icons.keyboard_arrow_up,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_cart.isNotEmpty)
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 180,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      itemCount: _cart.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _cartItemRow(
                                            _cart[index],
                                            index,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade200,
                                        Colors.grey.shade100,
                                      ],
                                    ),
                                  ),
                                ),

                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Payment Method Label & Options
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF009661,
                                          ).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Payment Method',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF333333),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                _paymentOption(
                                                  'Cash',
                                                  Icons.payments_outlined,
                                                ),
                                                const SizedBox(width: 10),
                                                _paymentOption(
                                                  'QR',
                                                  Icons.qr_code,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Total Display Card
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF009661,
                                              ).withValues(alpha: 0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total Amount Due',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₱$cartTotal.00',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF009661),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF009661,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.local_offer_rounded,
                                                color: Color(0xFF009661),
                                                size: 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Amount Paid Input Card
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                                left: 12,
                                                right: 12,
                                              ),
                                              child: Text(
                                                'Amount Paid',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _amountPaidController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF009661),
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: '0',
                                                      hintStyle: TextStyle(
                                                        fontSize: 20,
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 10,
                                                          ),
                                                      prefix: Text(
                                                        '₱ ',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                            0xFF009661,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      left: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          int current =
                                                              int.tryParse(
                                                                _amountPaidController
                                                                    .text,
                                                              ) ??
                                                              0;
                                                          _amountPaidController
                                                                  .text =
                                                              (current + 1)
                                                                  .toString();
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 5,
                                                              ),
                                                          child: Icon(
                                                            Icons.arrow_drop_up,
                                                            size: 20,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        height: 1,
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                      ),
                                                      GestureDetector(
                                                        onTap: () {
                                                          int current =
                                                              int.tryParse(
                                                                _amountPaidController
                                                                    .text,
                                                              ) ??
                                                              0;
                                                          if (current > 0) {
                                                            _amountPaidController
                                                                    .text =
                                                                (current - 1)
                                                                    .toString();
                                                          }
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 5,
                                                              ),
                                                          child: Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            size: 20,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Change Display Card
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _change > 0
                                              ? const Color(
                                                  0xFF009661,
                                                ).withValues(alpha: 0.08)
                                              : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: _change > 0
                                                ? const Color(
                                                    0xFF009661,
                                                  ).withValues(alpha: 0.3)
                                                : Colors.grey.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Change',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '₱${_change.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    color: _change > 0
                                                        ? const Color(
                                                            0xFF009661,
                                                          )
                                                        : Colors.grey.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _change > 0
                                                    ? const Color(
                                                        0xFF009661,
                                                      ).withValues(alpha: 0.15)
                                                    : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _change > 0
                                                    ? Icons.check_circle
                                                    : Icons.info,
                                                color: _change > 0
                                                    ? const Color(0xFF009661)
                                                    : Colors.grey.shade400,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Complete Transaction Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _completeTransaction,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF009661,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                            shadowColor: const Color(
                                              0xFF009661,
                                            ).withValues(alpha: 0.4),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Complete Transaction',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            crossFadeState: _isCartExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
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
    bool active = _selectedCategory == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF009661) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? const Color(0xFF009661) : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
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
    Widget fallbackIcon() => Center(
      child: Icon(iconData, size: 40, color: iconColor.withValues(alpha: 0.6)),
    );

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
          width: double.infinity,
          height: double.infinity,
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
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => fallbackIcon(),
      ),
    );
  }

  Widget _cartItemRow(CartItem cartItem, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.8),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Item Name & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₱${cartItem.item.price}/each',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _updateQuantity(index, -1),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF009661),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text(
                        '−',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateQuantity(index, 1),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF009661),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Total Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF009661).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '₱${cartItem.total}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF009661),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Delete Button
          GestureDetector(
            onTap: () => _removeFromCart(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Center(
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade600,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(String label, IconData icon) {
    bool active = _selectedPayment == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPayment = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF00A86B), Color(0xFF009661)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? Colors.transparent : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF009661).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPayment = label;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: active ? Colors.white : Colors.grey.shade600,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.white : Colors.grey.shade700,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
