// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'homepage.dart' show InventoryData, POSItem;

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredItems {
    if (_searchQuery.isEmpty) return InventoryData.items;
    return InventoryData.items
        .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showAddNewItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    final lowStockController = TextEditingController(text: '10');
    String selectedCategory = 'Food';
    
    final categories = ['Food', 'Beverages', 'Snacks', 'Desserts', 'Supplies', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            constraints: const BoxConstraints(maxWidth: 320),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Add New Item',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Name field
                  _buildSimpleInputField(
                    controller: nameController,
                    label: 'Name',
                  ),
                  const SizedBox(height: 16),
                  
                  // Price field
                  _buildSimpleInputField(
                    controller: priceController,
                    label: 'Price',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Stock field
                  _buildSimpleInputField(
                    controller: stockController,
                    label: 'Stock',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Unit field
                  _buildSimpleInputField(
                    controller: unitController,
                    label: 'Unit (e.g., pieces)',
                  ),
                  const SizedBox(height: 16),
                  
                  // Low Stock Alert field
                  _buildSimpleInputField(
                    controller: lowStockController,
                    label: 'Low Stock Alert',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Category dropdown
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        isDense: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                        items: categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedCategory = value!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.purple[400],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty && 
                              priceController.text.isNotEmpty && 
                              stockController.text.isNotEmpty) {
                            final newItem = POSItem(
                              name: nameController.text,
                              category: selectedCategory,
                              price: int.tryParse(priceController.text) ?? 0,
                              stock: int.tryParse(stockController.text) ?? 0,
                              unit: unitController.text.isNotEmpty ? unitController.text : 'pieces',
                              lowStockAlert: int.tryParse(lowStockController.text) ?? 10,
                            );
                            setState(() {
                              InventoryData.items.add(newItem);
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${nameController.text} added to inventory'),
                                  backgroundColor: const Color(0xFF009661),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in Name, Price, and Stock'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009661),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildSimpleInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
        ),
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, dynamic item) {
    final TextEditingController quantityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Product info
              const Text('Product', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Current: ${item.stock} ${item.unit}', style: const TextStyle(fontSize: 12, color: Color(0xFF009661))),
              const SizedBox(height: 16),
              // Quantity input
              Text('Quantity to Add (${item.unit})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF009661)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
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
                        final qty = int.tryParse(quantityController.text) ?? 0;
                        if (qty > 0) {
                          setState(() {
                            item.stock += qty;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $qty ${item.unit} to ${item.name}'),
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
                      child: const Text('Add Stock', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Inventory",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${InventoryData.items.length} products',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddNewItemDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                      label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009661),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return _buildInventoryCard(
                  context: context,
                  item: item,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create the product cards
  Widget _buildInventoryCard({
    required BuildContext context,
    required dynamic item,
  }) {
    final bool isLowStock = item.stock <= item.lowStockAlert;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLowStock ? Border.all(color: Colors.orange.shade200, width: 1.5) : null,
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
          // Top Row: Info and Add Stock Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F2937)),
                          ),
                        ),
                        if (isLowStock) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade400, Colors.orange.shade300],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Low Stock',
                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₱${item.price}',
                      style: const TextStyle(
                        color: Color(0xFF009661),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              // Add Stock Button
              ElevatedButton.icon(
                onPressed: () => _showAddStockDialog(context, item),
                icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF009661)),
                label: const Text(
                  "Add Stock",
                  style: TextStyle(color: Color(0xFF009661), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009661).withValues(alpha: 0.1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStockIndicator("Current Stock", "${item.stock} ${item.unit}", Icons.inventory_2_rounded, const Color(0xFF009661)),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: _buildStockIndicator("Alert Level", "${item.lowStockAlert} ${item.unit}", Icons.notifications_outlined, const Color(0xFFF59E0B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }
}