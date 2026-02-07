import 'package:flutter/material.dart';

// --- DATA MODEL ---
class POSItem {
  final String name;
  final int price;
  int stock;
  final String unit;
  final String category;
  final int lowStockAlert;

  POSItem({
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
    this.category = 'Food',
    this.lowStockAlert = 10,
  });
}

// --- SHARED INVENTORY DATA ---
class InventoryData {
  static final List<POSItem> items = [
    POSItem(name: "Chicken with Rice", price: 45, stock: 50, unit: "servings", category: "Food", lowStockAlert: 10),
    POSItem(name: "Corndog", price: 25, stock: 30, unit: "pieces", category: "Food", lowStockAlert: 5),
    POSItem(name: "Siomai", price: 20, stock: 100, unit: "pieces", category: "Food", lowStockAlert: 20),
    POSItem(name: "Empanada", price: 15, stock: 40, unit: "pieces", category: "Food", lowStockAlert: 10),
    POSItem(name: "Shake", price: 35, stock: 25, unit: "cups", category: "Beverage", lowStockAlert: 5),
    POSItem(name: "Lemonade", price: 30, stock: 30, unit: "cups", category: "Beverage", lowStockAlert: 5),
    POSItem(name: "Coke", price: 20, stock: 48, unit: "bottles", category: "Beverage", lowStockAlert: 10),
    POSItem(name: "Royal", price: 20, stock: 36, unit: "bottles", category: "Beverage", lowStockAlert: 10),
    POSItem(name: "Sprite", price: 20, stock: 36, unit: "bottles", category: "Beverage", lowStockAlert: 10),
    POSItem(name: "Bottled Water", price: 15, stock: 60, unit: "bottles", category: "Beverage", lowStockAlert: 15),
  ];
}

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  int _currentIndex = 0; // Tracks the selected bottom nav tab

  // 1. All Main Views Connected Here
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const POSGridView(),        // Index 0: POS
      const InventoryView(),     // Index 1: Inventory
      const ReportsView(),       // Index 2: Reports
      const BillsView(),         // Index 3: Bills
      const MenuView(),          // Index 4: Menu
      const DataManagementView(),// Index 5: Data
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header remains constant across all pages
          _buildHeader(context),
          
          // Body changes based on bottom bar selection
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.shopping_cart_outlined, 'POS'),
            _buildNavItem(1, Icons.inventory_2_outlined, 'Inventory'),
            _buildNavItem(2, Icons.description_outlined, 'Reports'),
            _buildNavItem(3, Icons.receipt_long_outlined, 'Bills', hasBadge: true),
            _buildNavItem(4, Icons.restaurant_menu_outlined, 'Menu'),
            _buildNavItem(5, Icons.settings_outlined, 'Data'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool hasBadge = false}) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF009661).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF009661) : Colors.grey,
                  size: 24,
                ),
              ),
              if (hasBadge)
                Positioned(
                  right: 8,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFF009661) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF009661),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/byte and bite logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Byte & Bite POS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Owner', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D47),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}

// --- SUB-VIEW 0: POS GRID ---
class POSGridView extends StatefulWidget {
  const POSGridView({super.key});

  @override
  State<POSGridView> createState() => _POSGridViewState();
}

// Cart item model
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
    return InventoryData.items.where((item) => item.category == _selectedCategory).toList();
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

  void _completeTransaction() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty'), backgroundColor: Colors.red),
      );
      return;
    }

    double? amountPaid = double.tryParse(_amountPaidController.text);
    if (amountPaid == null || amountPaid < cartTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient payment amount'), backgroundColor: Colors.red),
      );
      return;
    }

    double change = amountPaid - cartTotal;
    final now = DateTime.now();
    final receiptNumber = now.millisecondsSinceEpoch.toString();
    final savedCart = List<CartItem>.from(_cart);
    final savedTotal = cartTotal;
    
    // Deduct from inventory
    for (var cartItem in _cart) {
      cartItem.item.stock -= cartItem.quantity;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text('Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _cart.clear();
                        _amountPaidController.clear();
                        _change = 0;
                      });
                    },
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Store info
              const Text('BYTE & BITE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF009661))),
              const Text('Smart POS Solution', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Text('Visayan Village, Tagum City', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              const Divider(),
              // Transaction details
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${_formatDate(now)}', style: const TextStyle(fontSize: 12)),
                    Text('Time: ${_formatTime(now)}', style: const TextStyle(fontSize: 12)),
                    Text('Receipt #: $receiptNumber', style: const TextStyle(fontSize: 12)),
                    Text('Payment: $_selectedPayment', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              // Items
              ...savedCart.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('x${item.quantity}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₱${item.total}.00', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('₱${item.item.price}.00', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              )),
              const Divider(),
              const SizedBox(height: 8),
              // Totals
              _receiptRow('TOTAL:', '₱$savedTotal.00', bold: true),
              _receiptRow('Amount Paid:', '₱${amountPaid.toStringAsFixed(2)}'),
              _receiptRow('Change:', '₱${change.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Thank you for your purchase!', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const Text('Come again soon!', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Print functionality placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Printing receipt...')),
                        );
                      },
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _cart.clear();
                          _amountPaidController.clear();
                          _change = 0;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009661),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        // Category tabs
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
        // Product grid
        Expanded(
          flex: 2,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) => _itemCard(filteredItems[index]),
          ),
        ),
        // Cart & Checkout section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Cart items
              if (_cart.isNotEmpty) ...[
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) => _cartItemRow(_cart[index], index),
                  ),
                ),
                const Divider(height: 1),
              ],
              // Payment method
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Method', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _paymentOption('Cash', Icons.payments_outlined),
                        const SizedBox(width: 8),
                        _paymentOption('GCash', Icons.phone_android),
                        const SizedBox(width: 8),
                        _paymentOption('QR', Icons.qr_code),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Total row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('₱$cartTotal.00', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF009661))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Amount paid with spinner look
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountPaidController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  int current = int.tryParse(_amountPaidController.text) ?? 0;
                                  _amountPaidController.text = (current + 1).toString();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: const Icon(Icons.arrow_drop_up, size: 20),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  int current = int.tryParse(_amountPaidController.text) ?? 0;
                                  if (current > 0) {
                                    _amountPaidController.text = (current - 1).toString();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: const Icon(Icons.arrow_drop_down, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Change row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Change:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('₱${_change.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF009661))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Complete button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009661),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Complete Transaction', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
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
            border: Border.all(color: active ? const Color(0xFF009661) : Colors.grey.shade300),
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

  Widget _itemCard(POSItem item) => GestureDetector(
    onTap: () => _addToCart(item),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF009661),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            '₱${item.price}',
            style: const TextStyle(
              color: Color(0xFF009661),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stock: ${item.stock} ${item.unit}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _cartItemRow(CartItem cartItem, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cartItem.item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('₱${cartItem.item.price} each', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
          // Quantity controls with green - and +
          Row(
            children: [
              GestureDetector(
                onTap: () => _updateQuantity(index, -1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF009661),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
              Container(
                width: 36,
                alignment: Alignment.center,
                child: Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              GestureDetector(
                onTap: () => _updateQuantity(index, 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF009661),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Total price
          SizedBox(
            width: 60,
            child: Text('₱${cartItem.total}.00', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009661))),
          ),
          // Delete button
          GestureDetector(
            onTap: () => _removeFromCart(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(Icons.delete_outline, color: Colors.red, size: 18),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF009661) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? const Color(0xFF009661) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? Colors.white : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUB-VIEW 1: INVENTORY ---
class InventoryView extends StatefulWidget {
  const InventoryView({super.key});
  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  String _searchQuery = '';

  List<POSItem> get filteredItems {
    if (_searchQuery.isEmpty) return InventoryData.items;
    return InventoryData.items
        .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showAddStockDialog(POSItem item) {
    final TextEditingController stockController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock - ${item.name}'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity to add',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              int? qty = int.tryParse(stockController.text);
              if (qty != null && qty > 0) {
                setState(() {
                  item.stock += qty;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $qty ${item.unit} to ${item.name}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009661)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Inventory Management",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) => _inventoryCard(filteredItems[index]),
          ),
        ),
      ],
    );
  }

  Widget _inventoryCard(POSItem item) {
    bool isLowStock = item.stock <= item.lowStockAlert;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.category,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddStockDialog(item),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF009661)),
                label: const Text(
                  'Add Stock',
                  style: TextStyle(color: Color(0xFF009661), fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF009661)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₱${item.price}',
            style: const TextStyle(
              color: Color(0xFF009661),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.stock} ${item.unit}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isLowStock ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low Stock Alert',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.lowStockAlert} ${item.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- SUB-VIEW 2: REPORTS ---
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Reports and Analytics Dashboard"));
  }
}

// --- SUB-VIEW 3: BILLS ---
class BillsView extends StatelessWidget {
  const BillsView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Bill Reminders & Tracking"));
  }
}

// --- SUB-VIEW 4: MENU ---
class MenuView extends StatelessWidget {
  const MenuView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Menu Editing & Customization"));
  }
}

// --- SUB-VIEW 5: DATA ---
class DataManagementView extends StatelessWidget {
  const DataManagementView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Storage & Backup Management"));
  }
}