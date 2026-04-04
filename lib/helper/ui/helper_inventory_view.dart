import 'dart:io';

import 'package:byte_bite/helper/logic/helper_business_logic.dart';
import 'package:byte_bite/helper/logic/inventory_controller.dart';
import 'package:byte_bite/model/pos_item_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/inventory_data.dart';

/// Inventory view for Helper to check stock and update quantities
class HelperInventoryView extends StatefulWidget {
  const HelperInventoryView({super.key});

  @override
  State<HelperInventoryView> createState() => _HelperInventoryViewState();
}

class _HelperInventoryViewState extends State<HelperInventoryView> {
  final InventoryController _inventoryController = const InventoryController();
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final loaded = await _inventoryController.loadProducts();
    if (!mounted) return;

    setState(() {
      InventoryData.items
        ..clear()
        ..addAll(loaded);
    });
    InventoryData.notifier.value = List<POSItem>.from(InventoryData.items);
  }

  Future<void> _persistItemUpdate({
    required POSItem original,
    required POSItem updated,
  }) async {
    await _inventoryController.updateProduct(
      original: original,
      updated: updated,
    );

    final index = InventoryData.items.indexOf(original);
    if (index >= 0) {
      InventoryData.items[index] = POSItem(
        productId: original.productId,
        name: updated.name,
        price: updated.price,
        stock: updated.stock,
        unit: updated.unit,
        category: updated.category,
        lowStockAlert: updated.lowStockAlert,
        image: updated.image,
      );
    }

    if (mounted) {
      setState(() {});
    }
    InventoryData.notifier.value = List<POSItem>.from(InventoryData.items);
  }

  List<String> get _categories =>
      HelperBusinessLogic.getCategories(InventoryData.items);

  List<String> get _statuses => ['All', 'In Stock', 'Low Stock'];

  List<POSItem> get _filteredItems {
    var items = InventoryData.items;

    // Filter by category
    if (_selectedCategory != 'All') {
      items = items
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Filter by stock status
    if (_selectedStatus == 'Low Stock') {
      items = items.where((item) => item.stock <= item.lowStockAlert).toList();
    } else if (_selectedStatus == 'In Stock') {
      items = items.where((item) => item.stock > item.lowStockAlert).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = HelperBusinessLogic.getLowStockCount(
      InventoryData.items,
    );
    final totalProducts = InventoryData.items.length;
    final totalStock = InventoryData.items.fold(
      0,
      (sum, item) => sum + item.stock,
    );
    final inventoryValue = InventoryData.items
        .fold(0.0, (sum, item) => sum + (item.price * item.stock))
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: const Color(0xFF009661),
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Item',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInventoryOverview(
              totalProducts,
              totalStock,
              lowStockCount,
              inventoryValue,
            ),
            _buildSearchAndFilters(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildItemsList(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatusFilters()),
              const SizedBox(width: 12),
              _buildCategoryDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusFilterButton('All'),
          const SizedBox(width: 8),
          _buildStatusFilterButton('Low Stock'),
          const SizedBox(width: 8),
          _buildStatusFilterButton('In Stock'),
        ],
      ),
    );
  }

  Widget _buildStatusFilterButton(String status) {
    final isSelected = status == _selectedStatus;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009661) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF009661) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          icon: Icon(Icons.expand_more, size: 20, color: Colors.grey.shade600),
          items: _categories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value!),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
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
    );
  }

  Widget _buildInventoryOverview(
    int totalProducts,
    int totalStock,
    int lowStockCount,
    double inventoryValue,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF009661), Color(0xFF00B377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009661).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Inventory Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem(
                Icons.inventory_2_outlined,
                'Total Items',
                '$totalProducts',
              ),
              _buildOverviewItem(
                Icons.widgets_outlined,
                'Total Stock',
                '$totalStock',
              ),
              _buildOverviewItem(
                Icons.warning_amber_rounded,
                'Low Stock',
                '$lowStockCount',
              ),
              _buildOverviewItem(
                Icons.attach_money,
                'Value',
                '₱${inventoryValue.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return _filteredItems.isEmpty
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
            ],
          )
        : Column(
            children: _filteredItems
                .map((item) => _buildInventoryCard(item))
                .toList(),
          );
  }

  Widget _buildInventoryCard(POSItem item) {
    final isLowStock = item.stock <= item.lowStockAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLowStock
            ? Border.all(color: Colors.orange.shade200, width: 1.5)
            : null,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        if (isLowStock) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade400,
                                  Colors.orange.shade300,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Low Stock',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          item.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 8),
                        Text(
                          '₱${item.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF009661),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showUpdateStockDialog(item),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.stock} ${item.unit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showUpdateStockDialog(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009661),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  'Add Stock',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(POSItem item) {
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Product',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Current: ${item.stock} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF009661),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quantity to Add (${item.unit})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final qty =
                              int.tryParse(quantityController.text) ?? 0;
                          if (qty > 0) {
                            final updated = POSItem(
                              productId: item.productId,
                              name: item.name,
                              price: item.price,
                              stock: item.stock + qty,
                              unit: item.unit,
                              category: item.category,
                              lowStockAlert: item.lowStockAlert,
                              image: item.image,
                            );

                            await _persistItemUpdate(
                              original: item,
                              updated: updated,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added $qty ${item.unit} to ${item.name}',
                                ),
                                backgroundColor: const Color(0xFF009661),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009661),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
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
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController();
    final lowStockController = TextEditingController(text: '10');
    String selectedCategory = 'Food';
    String? selectedImagePath;

    final categories = [
      'Food',
      'Beverage',
      'Snacks',
      'Desserts',
      'Supplies',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF009661),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Item',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Fill in the product details',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image Label
                        const Text(
                          'Product Image',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Image picker section
                        StatefulBuilder(
                          builder: (context, imageSetState) {
                            return GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (pickedFile != null) {
                                  imageSetState(() {
                                    selectedImagePath = pickedFile.path;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: selectedImagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.file(
                                          File(selectedImagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF009661,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.image_outlined,
                                              size: 32,
                                              color: Color(0xFF009661),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Tap to add product image',
                                            style: TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Camera or Gallery',
                                            style: TextStyle(
                                              color: Color(0xFFCCCCCC),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Product Name
                        const Text(
                          'Product Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInputFieldWithIcon(
                          controller: nameController,
                          label: 'e.g., Fried Chicken',
                          icon: Icons.shopping_bag_outlined,
                        ),
                        const SizedBox(height: 20),
                        // Price and Stock Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Price (₱)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInputFieldWithIcon(
                                    controller: priceController,
                                    label: '0.00',
                                    icon: Icons.attach_money,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Stock',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInputFieldWithIcon(
                                    controller: stockController,
                                    label: '0',
                                    icon: Icons.inventory_2_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Unit and Low Alert Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Unit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInputFieldWithIcon(
                                    controller: unitController,
                                    label: 'pcs, cups, etc.',
                                    icon: Icons.category_outlined,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Low Alert',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInputFieldWithIcon(
                                    controller: lowStockController,
                                    label: '10',
                                    icon: Icons.warning_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Category
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setDialogState(
                                  () => selectedCategory = 'Food',
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedCategory == 'Food'
                                        ? const Color(0xFF009661)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selectedCategory == 'Food'
                                          ? const Color(0xFF009661)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restaurant,
                                        color: selectedCategory == 'Food'
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Food',
                                        style: TextStyle(
                                          color: selectedCategory == 'Food'
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          fontWeight: selectedCategory == 'Food'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setDialogState(
                                  () => selectedCategory = 'Beverage',
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedCategory == 'Beverage'
                                        ? const Color(0xFF009661)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selectedCategory == 'Beverage'
                                          ? const Color(0xFF009661)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.local_drink_outlined,
                                        color: selectedCategory == 'Beverage'
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Beverage',
                                        style: TextStyle(
                                          color: selectedCategory == 'Beverage'
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          fontWeight:
                                              selectedCategory == 'Beverage'
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (nameController.text.isNotEmpty &&
                                      priceController.text.isNotEmpty &&
                                      stockController.text.isNotEmpty) {
                                    final newItem = POSItem(
                                      name: nameController.text,
                                      category: selectedCategory,
                                      price:
                                          int.tryParse(priceController.text) ??
                                          0,
                                      stock:
                                          int.tryParse(stockController.text) ??
                                          0,
                                      unit: unitController.text.isNotEmpty
                                          ? unitController.text
                                          : 'pieces',
                                      lowStockAlert:
                                          int.tryParse(
                                            lowStockController.text,
                                          ) ??
                                          10,
                                      image: selectedImagePath,
                                    );

                                    final created = await _inventoryController
                                        .createProduct(item: newItem);
                                    if (!mounted) return;

                                    setState(() {
                                      InventoryData.items.add(created);
                                    });
                                    InventoryData.notifier.value =
                                        List<POSItem>.from(InventoryData.items);

                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context);
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${nameController.text} added to inventory',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF009661,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in Name, Price, and Stock',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF009661),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFieldWithIcon({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(icon, color: const Color(0xFF009661), size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
