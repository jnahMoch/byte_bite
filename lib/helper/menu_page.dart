import 'package:flutter/material.dart';
import '../data/inventory_data.dart';
import '../data/sales_data.dart';
import '../model/sales_transaction_model.dart';
import '../database_helper.dart';
import '../user_storage.dart';

// UI Components
import 'menu/ui/category_filter.dart';
import 'menu/ui/menu_items_grid.dart';
import 'menu/ui/checkout_panel.dart';
import 'menu/ui/receipt_dialog.dart';
import 'package:byte_bite/owner/menu/ui/add_product_dialog.dart' show showAddProductDialog;

// Logic & Helpers
import 'menu/logic/menu_business_logic.dart';

/// Helper Menu Page
/// Main entry point for the menu/POS system
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF008A5E),
        elevation: 0,
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Byte & Bite POS",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Helper",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: const MenuContent(),
    );
  }
}

/// Menu content with category filtering and cart management
class MenuContent extends StatefulWidget {
  const MenuContent({super.key});

  @override
  State<MenuContent> createState() => _MenuContentState();
}

class _MenuContentState extends State<MenuContent> {
  String _selectedCategory = 'All';
  final List<Map<String, dynamic>> _cart = [];
  String _selectedPayment = 'Cash';
  final TextEditingController _amountPaidController = TextEditingController();
  double _change = 0;

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

  // --- Getters for computed values ---

  List<Map<String, String>> get _items => InventoryData.items
      .map(
        (item) => {
          'name': item.name,
          'price': '₱${item.price}',
          'stock': '${item.stock} ${item.unit}',
          'category': item.category,
          'image': item.image ?? '',
        },
      )
      .toList();

  List<String> get _categories {
    final cats = InventoryData.items.map((e) => e.category).toSet().toList();
    return ['All', ...cats];
  }

  List<Map<String, String>> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((i) => i['category'] == _selectedCategory).toList();
  }

  int get _cartTotal => MenuBusinessLogic.calculateCartTotal(_cart);

  // --- Event handlers ---

  void _calculateChange() {
    double? amountPaid = double.tryParse(_amountPaidController.text);
    setState(() {
      _change = MenuBusinessLogic.calculateChange(amountPaid ?? 0, _cartTotal);
    });
  }

  void _addToCart(Map<String, String> item) {
    setState(() {
      final idx = _cart.indexWhere((c) => c['item']['name'] == item['name']);
      if (idx >= 0) {
        _cart[idx]['quantity'] += 1;
      } else {
        _cart.add({'item': item, 'quantity': 1});
      }
      _amountPaidController.clear();
      _change = 0;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _cart[index]['quantity'] += delta;
      if (_cart[index]['quantity'] <= 0) _cart.removeAt(index);
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _changePaymentMethod(String method) {
    setState(() => _selectedPayment = method);
  }

  Future<void> _completeTransaction() async {
    if (_cart.isEmpty) return;

    double? amountPaid = double.tryParse(_amountPaidController.text);
    if (amountPaid == null ||
        !MenuBusinessLogic.isPaymentSufficient(amountPaid, _cartTotal)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Extract cart items for receipt
    final cartItems = MenuBusinessLogic.extractCartItems(_cart);

    // Deduct stock from inventory
    for (var c in _cart) {
      final itemName = (c['item'] as Map<String, String>)['name'] ?? '';
      final qty = c['quantity'] as int;
      final inventoryItem = InventoryData.items.firstWhere(
        (i) => i.name == itemName,
        orElse: () => InventoryData.items.first,
      );
      if (inventoryItem.name == itemName) {
        inventoryItem.stock = (inventoryItem.stock - qty).clamp(
          0,
          inventoryItem.stock,
        );
      }
    }

    final paid = amountPaid;
    final total = _cartTotal;
    final change = paid - total;
    final now = DateTime.now();
    final receiptNumber = MenuBusinessLogic.generateReceiptNumber();
    final paymentMethod = MenuBusinessLogic.getPaymentMethodDisplay(
      _selectedPayment,
    );

    // persist header row so dashboard can query it
    try {
      /*final currentUserId = await UserStorage.resolveCurrentUserId();*/
      await DatabaseHelper.instance.recordSale(
        userId: 1,                                          //change//
        totalAmount: total.toDouble(),
        items: [],
        paymentMethod: paymentMethod,
        paymentStatus: 'Success',
      );
    } catch (e) {
      debugPrint('menu_page db recordSale failed: $e');
    }

    // Record transaction in memory afterwards (notifier will fire)
    SalesData.addTransaction(
      SalesTransaction(
        receiptNumber: receiptNumber,
        dateTime: now,
        items: cartItems,
        total: total,
        amountPaid: paid,
        change: change,
        paymentMethod: paymentMethod,
      ),
    );
    // Clear cart
    setState(() {
      _cart.clear();
      _amountPaidController.clear();
      _change = 0;
    });

    // Show receipt dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => ReceiptDialog(
          cartItems: cartItems,
          total: total,
          paid: paid,
          change: change,
          receiptNumber: receiptNumber,
          paymentMethod: paymentMethod,
          date: now,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 12),

        // Category filter
        CategoryFilter(
          selectedCategory: _selectedCategory,
          categories: _categories,
          onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
        ),

        // Menu items grid with checkout panel
        Expanded(
          child: Column(
            children: [
              // Menu items grid
              Expanded(
                child: MenuItemsGrid(
                  filteredItems: _filteredItems,
                  onAddToCart: _addToCart,
                ),
              ),

              // Checkout panel (shown when cart has items)
              if (_cart.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: CheckoutPanel(
                      cart: _cart,
                      cartTotal: _cartTotal,
                      change: _change,
                      selectedPayment: _selectedPayment,
                      amountPaidController: _amountPaidController,
                      onUpdateQuantity: _updateQuantity,
                      onRemoveFromCart: _removeFromCart,
                      onPaymentMethodChanged: _changePaymentMethod,
                      onCompleteTransaction: _completeTransaction,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Menu Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF050A1F),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              showAddProductDialog(context, (newItem) {
                setState(() {});
              });
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text(
              'Add Item',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008A5E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
