import 'package:flutter/material.dart';

import '../../homepage.dart' show InventoryData, POSItem;

Future<POSItem?> showAddItemDialog(BuildContext context) {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final unitController = TextEditingController();
  final lowStockController = TextEditingController(text: '10');
  String selectedCategory = 'Food';

  final categories = [
    'Food',
    'Beverages',
    'Snacks',
    'Desserts',
    'Supplies',
    'Other',
  ];

  Widget buildSimpleInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
        floatingLabelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFF00BF6D), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }

  return showDialog<POSItem>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          constraints: const BoxConstraints(maxWidth: 320),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Item',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 28),

                buildSimpleInputField(
                  controller: nameController,
                  label: 'Name',
                ),
                const SizedBox(height: 16),

                buildSimpleInputField(
                  controller: priceController,
                  label: 'Price',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                buildSimpleInputField(
                  controller: stockController,
                  label: 'Stock',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                buildSimpleInputField(
                  controller: unitController,
                  label: 'Unit (e.g., pieces)',
                ),
                const SizedBox(height: 16),

                buildSimpleInputField(
                  controller: lowStockController,
                  label: 'Low Stock Alert',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                        color: Color(0xFF00BF6D),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final price = int.tryParse(
                            priceController.text.trim(),
                          );
                          final stock = int.tryParse(
                            stockController.text.trim(),
                          );
                          final unit = unitController.text.trim();
                          final lowStockAlert =
                              int.tryParse(lowStockController.text.trim()) ??
                              10;

                          if (name.isNotEmpty &&
                              price != null &&
                              stock != null &&
                              unit.isNotEmpty) {
                            final newItem = POSItem(
                              name: name,
                              price: price,
                              stock: stock,
                              unit: unit,
                              category: selectedCategory,
                              lowStockAlert: lowStockAlert,
                            );

                            Navigator.pop(dialogContext, newItem);
                          } else {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all fields with valid values',
                                ),
                                backgroundColor: Color(0xFFE53E3E),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BF6D),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add Item',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

void showAddProductDialog(
  BuildContext context,
  Function(POSItem) onProductAdded,
) {
  showAddItemDialog(context).then((item) {
    if (item == null) return;
    InventoryData.items.add(item);
    onProductAdded(item);
  });
}
