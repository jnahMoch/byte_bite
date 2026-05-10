import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../model/pos_item_model.dart';
import '../../../data/inventory_data.dart';
import '../../../ui/confirmation_dialog.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});
  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    final alertController = TextEditingController(text: '10');
    String selectedCategory = 'Food';
    String? selectedImagePath;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF009661), Color(0xFF00B377)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_box_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Menu Item', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Fill in the product details', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text('Product Image', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      enableDrag: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) => Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 20),
                              const Text('Choose Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 512, maxHeight: 512, imageQuality: 80);
                                        if (image != null) setModalState(() => selectedImagePath = image.path);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(color: const Color(0xFF009661).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                                        child: const Column(
                                          children: [
                                            Icon(Icons.camera_alt_rounded, size: 40, color: Color(0xFF009661)),
                                            SizedBox(height: 8),
                                            Text('Camera', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF009661))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
                                        if (image != null) setModalState(() => selectedImagePath = image.path);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                                        child: const Column(
                                          children: [
                                            Icon(Icons.photo_library_rounded, size: 40, color: Color(0xFF3B82F6)),
                                            SizedBox(height: 8),
                                            Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selectedImagePath != null ? const Color(0xFF009661) : Colors.grey.shade300, width: selectedImagePath != null ? 2 : 1),
                    ),
                    child: selectedImagePath != null
                        ? Stack(
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(selectedImagePath!), width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
                              Positioned(
                                top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => selectedImagePath = null),
                                  child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF009661).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.add_photo_alternate_outlined, size: 28, color: Color(0xFF009661))),
                              const SizedBox(height: 8),
                              const Text('Tap to add image', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Item Name', prefixIcon: const Icon(Icons.fastfood_outlined, color: Color(0xFF009661)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Price', prefixText: '₱', prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF009661)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: stockController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stock', prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF009661)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(child: TextField(controller: unitController, decoration: InputDecoration(labelText: 'Unit', hintText: 'pcs', prefixIcon: const Icon(Icons.straighten, color: Color(0xFF009661)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: alertController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Low Alert', prefixIcon: const Icon(Icons.warning_amber_rounded, color: Color(0xFF009661)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  ],
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(labelText: 'Category', prefixIcon: const Icon(Icons.category, color: Color(0xFF009661)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: ['Food', 'Beverage'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                            setState(() {
                              InventoryData.items.add(POSItem(
                                name: nameController.text,
                                price: int.tryParse(priceController.text) ?? 0,
                                stock: int.tryParse(stockController.text) ?? 0,
                                unit: unitController.text.isNotEmpty ? unitController.text : 'pcs',
                                category: selectedCategory,
                                lowStockAlert: int.tryParse(alertController.text) ?? 10,
                                image: selectedImagePath,
                              ));
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameController.text} added!'), backgroundColor: const Color(0xFF009661)));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009661), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: Colors.white), SizedBox(width: 8), Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(POSItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());
    final unitController = TextEditingController(text: item.unit);
    final alertController = TextEditingController(text: item.lowStockAlert.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alertController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Alert',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final confirmed = await ConfirmationDialog.showEditConfirmation(
                context: context,
                itemName: nameController.text,
              );

              if (!confirmed!) return;

              setState(() {
                final index = InventoryData.items.indexOf(item);
                if (index != -1) {
                  InventoryData.items[index] = POSItem(
                    name: nameController.text,
                    price: int.tryParse(priceController.text) ?? item.price,
                    stock: int.tryParse(stockController.text) ?? item.stock,
                    unit: unitController.text,
                    category: item.category,
                    lowStockAlert: int.tryParse(alertController.text) ?? item.lowStockAlert,
                  );
                }
              });
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${nameController.text} updated successfully'),
                  backgroundColor: const Color(0xFF009661),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009661)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteItem(POSItem item) async {
    final confirmed = await ConfirmationDialog.showDeleteConfirmation(
      context: context,
      itemName: item.name,
      additionalMessage: 'This action cannot be undone.',
    );

    if (!confirmed!) return;

    setState(() {
      InventoryData.items.remove(item);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted successfully'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<POSItem> foodItems = InventoryData.items.where((i) => i.category == 'Food').toList();
    List<POSItem> beverageItems = InventoryData.items.where((i) => i.category == 'Beverage').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Item', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009661),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              const Icon(Icons.restaurant, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                'Food Items (${foodItems.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...foodItems.map((item) => _menuItemCard(item)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              const Icon(Icons.local_drink, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                'Beverage Items (${beverageItems.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...beverageItems.map((item) => _menuItemCard(item)),
        ],
      ),
    );
  }

  Widget _menuItemCard(POSItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₱${item.price}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009661),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Stock: ${item.stock} ${item.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Alert: ${item.lowStockAlert} ${item.unit}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          GestureDetector(
            onTap: () => _showEditItemDialog(item),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          GestureDetector(
            onTap: () => _deleteItem(item),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outlined,
                size: 18,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
