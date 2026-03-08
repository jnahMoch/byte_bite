import 'package:flutter/material.dart';
import 'homepage.dart' show InventoryData, POSItem;

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    final alertController = TextEditingController(text: '5');
    String selectedCategory = 'Food';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 340),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add New Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 20, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Product Name *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Chicken with Rice',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Category *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    items: ['Food', 'Beverage'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setDialogState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  const Text('Price (₱) *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Initial Stock *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Unit *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: unitController,
                              decoration: InputDecoration(
                                hintText: 'e.g., pieces',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Low Stock Alert Threshold', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: alertController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '5',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final price = int.tryParse(priceController.text) ?? 0;
                            final stock = int.tryParse(stockController.text) ?? 0;
                            final unit = unitController.text.trim();
                            final alert = int.tryParse(alertController.text) ?? 5;

                            if (name.isNotEmpty && price > 0 && unit.isNotEmpty) {
                              setState(() {
                                InventoryData.items.add(POSItem(
                                  name: name,
                                  price: price,
                                  stock: stock,
                                  unit: unit,
                                  category: selectedCategory,
                                  lowStockAlert: alert,
                                ));
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$name added to menu'),
                                  backgroundColor: const Color(0xFF009661),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009661),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add Product', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteProduct(POSItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                InventoryData.items.remove(item);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodItems = InventoryData.items.where((i) => i.category == 'Food').toList();
    final beverageItems = InventoryData.items.where((i) => i.category == 'Beverage').toList();

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Menu Management",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          "${foodItems.length + beverageItems.length} items total",
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  label: const Text("Add Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009661),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                
                _buildCategoryHeader("Food Items", "${foodItems.length}", Icons.restaurant_rounded, const Color(0xFFEF4444)),
                const SizedBox(height: 12),
                ...foodItems.map((item) => _menuManagementCard(item)),

                const SizedBox(height: 20),

                _buildCategoryHeader("Beverages", "${beverageItems.length}", Icons.local_cafe_rounded, const Color(0xFF3B82F6)),
                const SizedBox(height: 12),
                ...beverageItems.map((item) => _menuManagementCard(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, String count, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _menuManagementCard(POSItem item) {
    final isLowStock = item.stock <= item.lowStockAlert;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
                    ),
                    if (isLowStock) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Low', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009661).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('₱${item.price}', style: const TextStyle(color: Color(0xFF009661), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text("${item.stock} ${item.unit}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.notifications_outlined, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text("Alert at ${item.lowStockAlert} ${item.unit}", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          Row(
            children: [
              _actionButton(Icons.edit_rounded, const Color(0xFF6B7280), const Color(0xFFF3F4F6), () {}),
              const SizedBox(width: 8),
              _actionButton(Icons.delete_rounded, const Color(0xFFEF4444), const Color(0xFFFEE2E2), () => _deleteProduct(item)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}