import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../model/pos_item_model.dart';
import '../../../data/inventory_data.dart';
import '../logic/inventory_controller.dart';

class InventoryMenuView extends StatefulWidget {
  const InventoryMenuView({super.key});
  @override
  State<InventoryMenuView> createState() => _InventoryMenuViewState();
}

class _InventoryMenuViewState extends State<InventoryMenuView> {
  final InventoryController _inventoryController = const InventoryController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedFilter = 'All';

  List<POSItem> get filteredItems {
    var items = InventoryData.items.toList();
    if (_searchQuery.isNotEmpty) {
      items = items
          .where(
            (i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedCategory != 'All') {
      items = items.where((i) => i.category == _selectedCategory).toList();
    }
    if (_selectedFilter == 'Low Stock') {
      items = items.where((i) => i.stock <= i.lowStockAlert).toList();
    } else if (_selectedFilter == 'In Stock') {
      items = items.where((i) => i.stock > i.lowStockAlert).toList();
    }
    return items;
  }

  int get totalItems => InventoryData.items.length;
  int get totalStock => InventoryData.items.fold(0, (sum, i) => sum + i.stock);
  int get lowStockCount =>
      InventoryData.items.where((i) => i.stock <= i.lowStockAlert).length;
  double get inventoryValue => InventoryData.items
      .fold(0, (sum, i) => sum + (i.price * i.stock))
      .toDouble();

  String _syncErrorMessage(Object error) {
    if (error is cf.FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Saved locally, but Firebase denied write access. Check Firestore rules for products collection.';
      }
      if (error.code == 'not-authenticated') {
        return 'Saved locally, but Firebase sync requires an authenticated user. Please log in online first.';
      }
      return 'Saved locally, but Firebase sync failed: ${error.code}.';
    }
    return 'Saved locally, but sync failed: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF009661), Color(0xFF00B377)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inventory Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statBox(
                        'Total Items',
                        '$totalItems',
                        Icons.inventory_2_outlined,
                      ),
                      _statBox(
                        'Total Stock',
                        '$totalStock',
                        Icons.widgets_outlined,
                      ),
                      _statBox(
                        'Low Stock',
                        '$lowStockCount',
                        Icons.warning_amber_outlined,
                      ),
                      _statBox(
                        'Value',
                        '₱${inventoryValue.toStringAsFixed(0)}',
                        Icons.attach_money,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _filterChip(
                        'All',
                        _selectedFilter == 'All',
                        () => setState(() => _selectedFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        'Low Stock',
                        _selectedFilter == 'Low Stock',
                        () => setState(() => _selectedFilter = 'Low Stock'),
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        'In Stock',
                        _selectedFilter == 'In Stock',
                        () => setState(() => _selectedFilter = 'In Stock'),
                        color: Colors.green,
                      ),
                      const Spacer(),
                      _categoryDropdown(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) =>
                    _inventoryCard(filteredItems[index]),
              ),
            ),
          ],
        ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddItemDialog(),
            backgroundColor: const Color(0xFF009661),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Item',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    bool active,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? (color ?? const Color(0xFF009661)) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? (color ?? const Color(0xFF009661))
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          items: [
            'All',
            'Food',
            'Beverage',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
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
        border: Border.all(
          color: isLowStock ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (isLowStock) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Low',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} • ₱${item.price}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoChip(Icons.inventory_2, '${item.stock} ${item.unit}'),
                    const SizedBox(width: 8),
                    _infoChip(
                      Icons.warning_amber,
                      'Alert: ${item.lowStockAlert}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _showEditItemDialog(item),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF009661),
                ),
              ),
              IconButton(
                onPressed: () => _showAddStockDialog(item),
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showAddStockDialog(POSItem item) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock - ${item.name}'),
        content: TextField(
          controller: controller,
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
            onPressed: () async {
              int? qty = int.tryParse(controller.text);
              if (qty != null && qty > 0) {
                final index = InventoryData.items.indexOf(item);
                if (index < 0) {
                  Navigator.pop(context);
                  return;
                }

                final updatedItem = POSItem(
                  productId: item.productId,
                  name: item.name,
                  price: item.price,
                  stock: item.stock + qty,
                  unit: item.unit,
                  category: item.category,
                  lowStockAlert: item.lowStockAlert,
                  image: item.image,
                );

                setState(() {
                  InventoryData.items[index] = updatedItem;
                });
                Navigator.pop(context);

                try {
                  await _inventoryController.updateProduct(
                    original: item,
                    updated: updatedItem,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_syncErrorMessage(e)),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added $qty ${item.unit} to ${updatedItem.name}',
                    ),
                    backgroundColor: const Color(0xFF009661),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009661),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(POSItem item) {
    final nameC = TextEditingController(text: item.name);
    final priceC = TextEditingController(text: item.price.toString());
    final stockC = TextEditingController(text: item.stock.toString());
    final alertC = TextEditingController(text: item.lowStockAlert.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alertC,
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => InventoryData.items.remove(item));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final parsedPrice = int.tryParse(priceC.text.trim());
              final parsedStock = int.tryParse(stockC.text.trim());
              final parsedAlert = int.tryParse(alertC.text.trim());
              final parsedName = nameC.text.trim();

              if (parsedName.isEmpty ||
                  parsedPrice == null ||
                  parsedStock == null ||
                  parsedAlert == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please provide valid Name, Price, Stock, and Low Stock Alert values.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final index = InventoryData.items.indexOf(item);
              if (index < 0) {
                Navigator.pop(context);
                return;
              }

              final updatedItem = POSItem(
                productId: item.productId,
                name: parsedName,
                price: parsedPrice,
                stock: parsedStock,
                unit: item.unit,
                category: item.category,
                lowStockAlert: parsedAlert,
                image: item.image,
              );

              setState(() {
                InventoryData.items[index] = updatedItem;
              });

              try {
                await _inventoryController.updateProduct(
                  original: item,
                  updated: updatedItem,
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_syncErrorMessage(e)),
                    backgroundColor: Colors.orange,
                  ),
                );
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product updated successfully.'),
                  backgroundColor: Color(0xFF009661),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009661),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final stockC = TextEditingController();
    final unitC = TextEditingController();
    final alertC = TextEditingController(text: '10');
    String category = 'Food';
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
                      child: const Icon(
                        Icons.add_box_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Item',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          'Fill in the product details',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Product Image',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      enableDrag: true,
                      useSafeArea: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Choose Image Source',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      final XFile? image = await picker
                                          .pickImage(
                                            source: ImageSource.camera,
                                            maxWidth: 512,
                                            maxHeight: 512,
                                            imageQuality: 80,
                                          );
                                      if (image != null) {
                                        setModalState(
                                          () => selectedImagePath = image.path,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF009661,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.camera_alt_rounded,
                                            size: 40,
                                            color: Color(0xFF009661),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Camera',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF009661),
                                            ),
                                          ),
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
                                      final XFile? image = await picker
                                          .pickImage(
                                            source: ImageSource.gallery,
                                            maxWidth: 512,
                                            maxHeight: 512,
                                            imageQuality: 80,
                                          );
                                      if (image != null) {
                                        setModalState(
                                          () => selectedImagePath = image.path,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF3B82F6,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.photo_library_rounded,
                                            size: 40,
                                            color: Color(0xFF3B82F6),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Gallery',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ),
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
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedImagePath != null
                            ? const Color(0xFF009661)
                            : Colors.grey.shade300,
                        width: selectedImagePath != null ? 2 : 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: selectedImagePath != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(selectedImagePath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setModalState(
                                    () => selectedImagePath = null,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF009661),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Image added',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF009661,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: Color(0xFF009661),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to add product image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Camera or Gallery',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  controller: nameC,
                  label: 'Product Name',
                  hint: 'e.g., Fried Chicken',
                  icon: Icons.fastfood_outlined,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: priceC,
                        label: 'Price (₱)',
                        hint: '0.00',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: stockC,
                        label: 'Stock',
                        hint: '0',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: unitC,
                        label: 'Unit',
                        hint: 'pcs, cups, etc.',
                        icon: Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: alertC,
                        label: 'Low Alert',
                        hint: '10',
                        icon: Icons.warning_amber_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCategoryChip(
                      'Food',
                      category,
                      Icons.restaurant,
                      (val) => setModalState(() => category = val),
                    ),
                    const SizedBox(width: 12),
                    _buildCategoryChip(
                      'Beverage',
                      category,
                      Icons.local_cafe,
                      (val) => setModalState(() => category = val),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameC.text.trim();
                          final price = int.tryParse(priceC.text.trim());

                          if (name.isEmpty || price == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Please fill in valid Name and Price'),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            return;
                          }

                          final localItem = POSItem(
                            name: name,
                            price: price,
                            stock: int.tryParse(stockC.text.trim()) ?? 0,
                            unit: unitC.text.trim().isEmpty
                                ? 'pcs'
                                : unitC.text.trim(),
                            category: category,
                            lowStockAlert:
                                int.tryParse(alertC.text.trim()) ?? 10,
                            image: selectedImagePath,
                          );

                          setState(() {
                            InventoryData.items.add(localItem);
                          });

                          Navigator.pop(context);

                          try {
                            final persisted = await _inventoryController
                                .createProduct(item: localItem);
                            if (context.mounted) {
                              final idx = InventoryData.items.indexOf(
                                localItem,
                              );
                              if (idx >= 0) {
                                setState(() {
                                  InventoryData.items[idx] = persisted;
                                });
                              }
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_syncErrorMessage(e)),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$name added successfully!'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF009661),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009661),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Add Item',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: const Color(0xFF009661), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    String label,
    String selected,
    IconData icon,
    Function(String) onSelect,
  ) {
    final isSelected = label == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF009661), Color(0xFF00B377)],
                  )
                : null,
            color: isSelected ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
