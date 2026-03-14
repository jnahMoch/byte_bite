import 'package:byte_bite/owner/homepage.dart';
import 'package:flutter/material.dart';

/// Shows a dialog for entering details of a new inventory item.
///
/// Returns the created [POSItem] if the user taps "Add", or null if
/// cancelled.
Future<POSItem?> showAddItemDialog(BuildContext context) {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final unitController = TextEditingController();
  final lowStockController = TextEditingController(text: '10');
  String selectedCategory = 'Food';

  const categories = [
    'Food',
    'Beverages',
    'Snacks',
    'Desserts',
    'Supplies',
    'Other',
  ];

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
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
        floatingLabelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
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

  return showDialog<POSItem>(
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
                const Text(
                  'Add New Item',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 28),
                _buildSimpleInputField(
                  controller: nameController,
                  label: 'Name',
                ),
                const SizedBox(height: 16),
                _buildSimpleInputField(
                  controller: priceController,
                  label: 'Price',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildSimpleInputField(
                  controller: stockController,
                  label: 'Stock',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildSimpleInputField(
                  controller: unitController,
                  label: 'Unit (e.g., pieces)',
                ),
                const SizedBox(height: 16),
                _buildSimpleInputField(
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey[600],
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                      items: categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCategory = value!);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
                            unit: unitController.text.isNotEmpty
                                ? unitController.text
                                : 'pieces',
                            lowStockAlert:
                                int.tryParse(lowStockController.text) ?? 10,
                          );
                          Navigator.pop(dialogContext, newItem);
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill in Name, Price, and Stock',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009661),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
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
