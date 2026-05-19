import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../../model/pos_item_model.dart';
import '../../../model/sales_transaction_model.dart';
import '../../../data/inventory_data.dart';
import '../../../data/sales_data.dart';
import '../../../database_helper.dart';
import '../../../user_storage.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  String _searchQuery = '';
  double _change = 0;
  bool _cartBumped = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _amountPaidController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _amountPaidController.removeListener(_calculateChange);
    _amountPaidController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _calculateChange() {
    _syncChange();
  }

  void _syncChange() {
    double? amountPaid = double.tryParse(_amountPaidController.text);
    setState(() {
      if (amountPaid != null && amountPaid >= cartTotal) {
        _change = amountPaid - cartTotal;
      } else {
        _change = 0;
      }
    });
  }

  void _recalculateChangeValue() {
    final amountPaid = double.tryParse(_amountPaidController.text);
    _change = amountPaid != null && amountPaid >= cartTotal
        ? amountPaid - cartTotal
        : 0;
  }

  List<POSItem> get filteredItems {
    var items = InventoryData.items.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      items = items.where((item) {
        return item.category == _selectedCategory ||
            (_selectedCategory == 'Beverage' && item.category == 'Beverages');
      }).toList();
    }

    return items;
  }

  int get cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  String get _transactionPaymentMethod =>
      _selectedPayment == 'QR' ? 'Cash' : _selectedPayment;

  void _addToCart(POSItem item) {
    setState(() {
      final existingIndex = _cart.indexWhere((c) => c.item.name == item.name);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(item: item));
      }
      // brief visual feedback when item added
      _cartBumped = true;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _cartBumped = false);
      });
    });
  }

  void _updateQuantity(int index, int delta) {
    if (index < 0 || index >= _cart.length) {
      return;
    }
    _cart[index].quantity += delta;
    if (_cart[index].quantity <= 0) {
      _cart.removeAt(index);
    }
  }

  void _removeFromCart(int index) {
    if (index < 0 || index >= _cart.length) {
      return;
    }
    _cart.removeAt(index);
  }

  void _applyCartSheetAction(StateSetter setModalState, VoidCallback action) {
    if (!mounted) return;

    setModalState(() {
      action();
      _recalculateChangeValue();
    });
    setState(() {});
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

  Future<void> _completeTransaction(BuildContext modalContext) async {
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

    final change = amountPaid - cartTotal;
    final now = DateTime.now();
    final receiptNumber = now.millisecondsSinceEpoch.toString();
    final savedCart = List<CartItem>.from(_cart);
    final savedTotal = cartTotal;
    final paymentMethod = _transactionPaymentMethod;

    // Build DB items and validate stock before committing
    final itemsForDB = <Map<String, dynamic>>[];
    final db = await DatabaseHelper.instance.database;
    for (final cartItem in savedCart) {
      final productId = await _resolveProductId(cartItem.item);

      final rows = await db.query(
        'Products',
        columns: ['stock_quantity'],
        where: 'product_id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      final available = rows.isNotEmpty
          ? (rows.first['stock_quantity'] as num).toInt()
          : 0;

      if (available < cartItem.quantity) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Insufficient stock for ${cartItem.item.name} (available: $available)',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      itemsForDB.add({
        'product_id': productId,
        'quantity': cartItem.quantity,
        'subtotal': (cartItem.item.price * cartItem.quantity).toDouble(),
      });
    }

    try {
      // Resolve current user's ID (fall back to owner if missing)
      final currentUsername = UserStorage.currentUser ?? '';
      int currentUserId = 1; // default owner

      if (currentUsername.isNotEmpty) {
        final userRecord = await DatabaseHelper.instance.getUserByUsername(
          currentUsername,
        );
        if (userRecord != null && userRecord.containsKey('user_id')) {
          currentUserId = (userRecord['user_id'] as num).toInt();
        }
      }

      await DatabaseHelper.instance.recordSale(
        userId: currentUserId,
        totalAmount: savedTotal.toDouble(),
        items: itemsForDB,
        paymentMethod: paymentMethod,
        paymentStatus: 'Success',
        amountReceived: amountPaid,
        changeAmount: change,
        transactionStatus: 'Completed',
      );
    } catch (e) {
      debugPrint('helper_pos_grid_view recordSale failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // DB commit succeeded — update in-memory stock and app state
    for (final cartItem in savedCart) {
      cartItem.item.stock -= cartItem.quantity;
    }

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
        paymentMethod: paymentMethod,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
    _showSaleSuccessDialog(
      savedCart,
      savedTotal,
      amountPaid,
      change,
      now,
      receiptNumber,
      paymentMethod,
    );
  }

  void _showSaleSuccessDialog(
    List<CartItem> savedCart,
    int savedTotal,
    double amountPaid,
    double change,
    DateTime now,
    String receiptNumber,
    String paymentMethod,
  ) {
    bool isPrintingStarted = false;
    final receiptBoundaryKey = GlobalKey();

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
                Expanded(
                  child: RepaintBoundary(
                    key: receiptBoundaryKey,
                    child: Column(
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
                                  'System‑Generated Sales Slip',
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
                                'System Receipt #: $receiptNumber',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              paymentMethod,
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
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        ...savedCart.asMap().entries.map((
                                          entry,
                                        ) {
                                          final item = entry.value;
                                          final isLast =
                                              entry.key == savedCart.length - 1;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item.item.name,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 3,
                                                          ),
                                                          Text(
                                                            'P${item.item.price}.00 × ${item.quantity}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .grey,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      'P${item.total}.00',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (!isLast)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 10,
                                                        ),
                                                    child: Divider(
                                                      height: 1,
                                                      color:
                                                          Colors.grey.shade200,
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
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Divider(height: 1),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'CHANGE',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              'P${change.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Center(
                                    child: Text(
                                      'System‑generated sales slip. Official BIR receipt issued separately.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: isPrintingStarted
                                ? null
                                : () async {
                                    setDialogState(
                                      () => isPrintingStarted = true,
                                    );
                                    try {
                                      await _downloadReceipt(
                                        receiptBoundaryKey: receiptBoundaryKey,
                                        receiptNumber: receiptNumber,
                                      );
                                    } catch (e) {
                                      debugPrint('Receipt download error: $e');
                                    }
                                    if (mounted) {
                                      setDialogState(
                                        () => isPrintingStarted = false,
                                      );
                                    }
                                  },
                            icon: Icon(
                              isPrintingStarted
                                  ? Icons.hourglass_bottom
                                  : Icons.download_outlined,
                              size: 18,
                            ),
                            label: Text(
                              isPrintingStarted ? 'Downloading...' : 'Download',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
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
                              'New Order',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
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

  Future<void> _downloadReceipt({
    required GlobalKey receiptBoundaryKey,
    required String receiptNumber,
  }) async {
    final buildContext = receiptBoundaryKey.currentContext;
    if (buildContext == null) {
      throw StateError('Receipt view is not ready for export.');
    }

    final renderObject = buildContext.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Receipt boundary is unavailable.');
    }

    await WidgetsBinding.instance.endOfFrame;

    if (renderObject.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;
    }

    final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to encode receipt image.');
    }

    final directory = await getDownloadsDirectory();
    final targetDirectory =
        directory ?? await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Receipt_${receiptNumber}_$timestamp.png';
    final file = File('${targetDirectory.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt image saved: $fileName'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    const double barHeight = 72.0;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF7C8794),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, barHeight + 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) =>
                    _itemCard(filteredItems[index]),
              ),
            ),
          ],
        ),

        // Sticky bottom cart bar
        if (_cart.isNotEmpty)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12),
              child: GestureDetector(
                onTap: _showCartBottomSheet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: barHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _cartBumped
                        ? const Color(0xFF009661).withValues(alpha: 0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: Color(0xFF009661),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _cart.length == 1
                                ? 'Cart (1 item)'
                                : 'Cart (${_cart.length} items)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF009661),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '₱$cartTotal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_up,
                            color: Color(0xFF009661),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.2,
        maxChildSize: 0.95,
        builder: (context, controller) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  for (int i = 0; i < _cart.length; i++)
                    Padding(
                      key: ValueKey('${_cart[i].item.name}-$i'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF009661,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    color: Color(0xFF009661),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _cart[i].item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${_cart[i].item.price} × ${_cart[i].quantity}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₱${_cart[i].total}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF009661),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _applyCartSheetAction(
                                          setModalState,
                                          () => _updateQuantity(i, -1),
                                        );
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          color: Color(0xFFDC2626),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_cart[i].quantity}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        _applyCartSheetAction(
                                          setModalState,
                                          () => _updateQuantity(i, 1),
                                        );
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Color(0xFF009661),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _applyCartSheetAction(
                                      setModalState,
                                      () => _removeFromCart(i),
                                    );
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009661).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount Due',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '₱$cartTotal',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009661),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _applyCartSheetAction(
                              setModalState,
                              () => _selectedPayment = 'Cash',
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedPayment == 'Cash'
                                  ? const Color(0xFF009661)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Cash',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedPayment == 'Cash'
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _applyCartSheetAction(
                              setModalState,
                              () => _selectedPayment = 'QR',
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedPayment == 'QR'
                                  ? const Color(0xFF009661)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'QR',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedPayment == 'QR'
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
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
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₱${_change.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _completeTransaction(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009661),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Complete Transaction',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final inCart = _cart.any((c) => c.item.name == item.name);

    return GestureDetector(
      onTap: () => _addToCart(item),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            // Image section
            Expanded(
              flex: 32,
              child: Stack(
                children: [
                  Container(
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
                  if (inCart)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Content section
            Expanded(
              flex: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${item.price}',
                    style: const TextStyle(
                      color: Color(0xFF009661),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      'Stock: ${item.stock} ${item.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
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

    // Check if it's a network URL
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

    // Check if it's an asset path
    if (imageRef.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imageRef,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => fallbackIcon(),
        ),
      );
    }

    // Otherwise, treat as file path
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
