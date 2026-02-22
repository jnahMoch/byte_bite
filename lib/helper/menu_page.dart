// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../owner/homepage.dart' show InventoryData, SalesData, SalesTransaction;

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
            Text("Helper", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
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

  // Use shared InventoryData - synced with Owner
  List<Map<String, String>> get _items => InventoryData.items.map((item) => {
    'name': item.name,
    'price': '₱${item.price}',
    'stock': '${item.stock} ${item.unit}',
    'category': item.category,
    'image': item.image ?? '',
  }).toList();

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

    // Store cart items before clearing for receipt display
    final cartItems = List<Map<String, dynamic>>.from(_cart.map((c) => {
      'name': (c['item'] as Map<String, String>)['name'] ?? '',
      'price': int.tryParse(((c['item'] as Map<String, String>)['price'] ?? '0').replaceAll('₱', '')) ?? 0,
      'quantity': c['quantity'] as int,
    }));

    // Deduct stock from shared InventoryData (synced with Owner)
    for (var c in _cart) {
      final itemName = (c['item'] as Map<String, String>)['name'] ?? '';
      final qty = c['quantity'] as int;
      final inventoryItem = InventoryData.items.where((i) => i.name == itemName).firstOrNull;
      if (inventoryItem != null) {
        inventoryItem.stock = (inventoryItem.stock - qty).clamp(0, inventoryItem.stock);
      }
    }

    final paid = amountPaid;
    final total = _cartTotal; // Save total before clearing
    final change = paid - total;
    final now = DateTime.now();
    final receiptNumber = now.millisecondsSinceEpoch.toString();
    final paymentMethod = _selectedPayment.toUpperCase();

    // Record the transaction for reports
    SalesData.addTransaction(SalesTransaction(
      receiptNumber: receiptNumber,
      dateTime: now,
      items: cartItems,
      total: total,
      amountPaid: paid,
      change: change,
      paymentMethod: paymentMethod,
    ));

    setState(() {
      _cart.clear();
      _amountPaidController.clear();
      _change = 0;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Store branding
              const Text('BYTE & BITE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Smart POS Solution', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Text('Visayan Village, Tagum City', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              // Receipt details
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${_formatDate(now)}', style: const TextStyle(fontSize: 12)),
                    Text('Time: ${_formatTime(now)}', style: const TextStyle(fontSize: 12)),
                    Text('Receipt #: $receiptNumber', style: const TextStyle(fontSize: 12)),
                    Text('Payment: $paymentMethod', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Dotted divider
              _buildDottedDivider(),
              const SizedBox(height: 12),
              // Items list
              ...cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['name'], style: const TextStyle(fontSize: 13)),
                        Text('₱${item['price']}.00', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('x${item['quantity']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('₱${item['price'] * item['quantity']}.00', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              _buildDottedDivider(),
              const SizedBox(height: 12),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₱$total.00', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount Paid:', style: TextStyle(fontSize: 13)),
                  Text('₱${paid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Change:', style: TextStyle(fontSize: 13)),
                  Text('₱${change.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              _buildDottedDivider(),
              const SizedBox(height: 16),
              // Thank you message
              const Text('Thank you for your purchase!', style: TextStyle(fontSize: 12, color: Color(0xFF009661))),
              const Text('Come again soon!', style: TextStyle(fontSize: 12, color: Color(0xFF009661))),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _printReceipt(
                          cartItems: cartItems,
                          total: total,
                          paid: paid,
                          change: change,
                          receiptNumber: receiptNumber,
                          paymentMethod: paymentMethod,
                          date: now,
                        );
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009661),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildDottedDivider() {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.grey.shade300 : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _printReceipt({
    required List<Map<String, dynamic>> cartItems,
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
              pw.Text('BYTE & BITE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Smart POS Solution', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Visayan Village, Tagum City', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),
              pw.Container(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Date: ${_formatDate(date)}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Time: ${_formatTime(date)}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Receipt #: $receiptNumber', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Payment: $paymentMethod', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              // Items
              ...cartItems.map((item) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(item['name'].toString(), style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('P${item['price']}.00', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('x${item['quantity']}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                      pw.Text('P${item['price'] * item['quantity']}.00', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                ],
              )),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('P$total.00', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('P${paid.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Change:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('P${change.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),
              pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Come again soon!', style: const pw.TextStyle(fontSize: 10)),
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
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, idx) {
                final item = _filteredItems[idx];
                final isFood = item['category'] == 'Food';
                final iconData = isFood ? Icons.restaurant_rounded : Icons.local_cafe_rounded;
                final iconColor = isFood ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
                final imageUrl = item['image'] ?? '';
                
                return GestureDetector(
                  onTap: () => _addToCart(item),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image or icon placeholder
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(iconData, size: 40, color: iconColor.withOpacity(0.6)),
                                      ),
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
                                  )
                                : Center(
                                    child: Icon(iconData, size: 40, color: iconColor.withOpacity(0.6)),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Product details
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(item['price'] ?? '', style: const TextStyle(color: Color(0xFF009661), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('Stock: ${item['stock']}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                        ),
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
