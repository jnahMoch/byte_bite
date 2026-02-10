import 'package:flutter/material.dart';

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
            Text("Byte & Bite POS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Helper (helper)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 20, bottom: 20),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Logout"),
            ),
          )
        ],
      ),
      body: const MenuContent(),
    );
  }
}

// Cart entries are simple maps: {'item': Map<String,String>, 'quantity': int}

class MenuContent extends StatefulWidget {
  const MenuContent({super.key});

  @override
  State<MenuContent> createState() => _MenuContentState();
}
class _MenuContentState extends State<MenuContent> {
  String _selected = 'All';

  final List<Map<String, String>> _items = [
    {'name': 'Siomai Beef 4pcs', 'price': '₱35', 'stock': '50 orders', 'category': 'Food'},
    {'name': 'Siomai Beef 6pcs', 'price': '₱50', 'stock': '50 orders', 'category': 'Food'},
    {'name': 'Chicken with Rice', 'price': '₱45', 'stock': '50 servings', 'category': 'Food'},
    {'name': 'Corndog', 'price': '₱25', 'stock': '30 pieces', 'category': 'Food'},
    {'name': 'Empanada', 'price': '₱15', 'stock': '40 pieces', 'category': 'Food'},
    {'name': 'Iced Tea', 'price': '₱20', 'stock': '100 bottles', 'category': 'Beverage'},
  ];

  List<Map<String, String>> get _filteredItems {
    if (_selected == 'All') return _items;
    return _items.where((i) => i['category'] == _selected).toList();
  }
  // --- Cart & Checkout state and helpers ---
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

  void _calculateChange() {
    double? amountPaid = double.tryParse(_amountPaidController.text);
    setState(() {
      if (amountPaid != null && amountPaid >= _cartTotal) {
        _change = amountPaid - _cartTotal;
      } else {
        _change = 0;
      }
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart'), backgroundColor: Colors.green));
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _cart[index]['quantity'] += delta;
      if (_cart[index]['quantity'] <= 0) _cart.removeAt(index);
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  Widget _paymentOption(String label, IconData icon) {
    bool active = _selectedPayment == label;
    return GestureDetector(
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
          border: Border.all(color: active ? const Color(0xFF009661) : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.white : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : Colors.grey, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  int get _cartTotal => _cart.fold<int>(0, (s, c) {
    final price = int.tryParse((c['item']['price'] as String).replaceAll('₱', '')) ?? 0;
    return s + price * (c['quantity'] as int);
  });

  void _completeTransaction() {
    if (_cart.isEmpty) return;
    double? amountPaid = double.tryParse(_amountPaidController.text);
    if (amountPaid == null || amountPaid < _cartTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient payment'), backgroundColor: Colors.red));
      return;
    }

    // Deduct stock from string like '50 orders'
    for (var c in _cart) {
      final item = c['item'] as Map<String, String>;
      final qty = c['quantity'] as int;
      final stockText = item['stock'] ?? '';
      final stockNum = int.tryParse(stockText.split(' ').first) ?? 0;
      final remaining = stockNum - qty;
      item['stock'] = remaining > 0 ? '$remaining ${stockText.split(' ').skip(1).join(' ')}' : '0 ${stockText.split(' ').skip(1).join(' ')}';
    }

    final paid = amountPaid;
    final change = paid - _cartTotal;

    setState(() {
      _cart.clear();
      _amountPaidController.clear();
      _change = 0;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ₱$_cartTotal'),
            Text('Paid: ₱${paid.toStringAsFixed(0)}'),
            Text('Change: ₱${change.toStringAsFixed(2)}'),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu Management',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF050A1F)),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Item', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008A5E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Category pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['All', 'Food', 'Beverage'].map((label) {
              final bool active = _selected == label;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF00A66A) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey[800],
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Grid of items
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              itemCount: _filteredItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, idx) {
                final item = _filteredItems[idx];
                return GestureDetector(
                  onTap: () => _addToCart(item),
                  child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF050A1F))),
                      const SizedBox(height: 12),
                      Text(item['price'] ?? '', style: const TextStyle(color: Color(0xFF00A66A), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Stock: ${item['stock']}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ),

        // Checkout panel (appears when cart has items)
        if (_cart.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: Column(
              children: [
                // Cart items list
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final c = _cart[index];
                      final item = c['item'] as Map<String, String>;
                      final qty = c['quantity'] as int;
                      final price = int.tryParse(item['price']?.replaceAll('₱', '') ?? '0') ?? 0;
                      final total = price * qty;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('₱$price each', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _updateQuantity(index, -1),
                                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF009661), borderRadius: BorderRadius.circular(6)), child: const Text('-', style: TextStyle(color: Colors.white)))),
                              Container(width: 36, alignment: Alignment.center, child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600))),
                              GestureDetector(onTap: () => _updateQuantity(index, 1), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF009661), borderRadius: BorderRadius.circular(6)), child: const Text('+', style: TextStyle(color: Colors.white)))),
                              const SizedBox(width: 12),
                              SizedBox(width: 60, child: Text('₱$total.00', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009661)))),
                              const SizedBox(width: 8),
                              GestureDetector(onTap: () => _removeFromCart(index), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.delete_outline, color: Colors.red, size: 18))),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Method', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _paymentOption('Cash', Icons.payments_outlined)),
                        const SizedBox(width: 8),
                        Expanded(child: _paymentOption('GCash', Icons.phone_android)),
                        const SizedBox(width: 8),
                        Expanded(child: _paymentOption('QR', Icons.qr_code)),
                      ]),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('₱$_cartTotal.00', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF009661))),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                        child: Row(
                          children: [
                            Expanded(child: TextField(controller: _amountPaidController, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), decoration: const InputDecoration(hintText: '0', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
                            Column(children: [
                              GestureDetector(onTap: () { int current = int.tryParse(_amountPaidController.text) ?? 0; _amountPaidController.text = (current + 1).toString(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: const Icon(Icons.arrow_drop_up, size: 20))),
                              GestureDetector(onTap: () { int current = int.tryParse(_amountPaidController.text) ?? 0; if (current > 0) _amountPaidController.text = (current - 1).toString(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: const Icon(Icons.arrow_drop_down, size: 20))),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Change:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('₱${_change.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF009661))),
                      ]),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _completeTransaction, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009661), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Complete Transaction', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)))),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
// end of file
