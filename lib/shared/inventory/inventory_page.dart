import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:byte_bite/data/inventory_data.dart';
import 'package:byte_bite/model/pos_item_model.dart';
import 'package:byte_bite/owner/home/logic/inventory_controller.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  final String userRole;

  const InventoryPage({super.key, required this.userRole});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const Color _green = Color(0xFF009661);
  static const Color _dark = Color(0xFF18212F);
  static const List<String> _categories = ['All', 'Food', 'Beverage'];

  final InventoryController _inventoryController = const InventoryController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalItems => InventoryData.items.length;
  int get _totalStock => InventoryData.items.fold(0, (sum, i) => sum + i.stock);
  int get _lowStockCount =>
      InventoryData.items.where((i) => i.stock <= i.lowStockAlert).length;
  int get _inventoryValue =>
      InventoryData.items.fold(0, (sum, i) => sum + (i.price * i.stock));

  List<POSItem> get _filteredItems {
    var items = InventoryData.items.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      items = items.where((item) {
        return item.category == _selectedCategory ||
            (_selectedCategory == 'Beverage' && item.category == 'Beverages');
      }).toList();
    }

    if (_selectedFilter == 'Low Stock') {
      items = items.where((item) => item.stock <= item.lowStockAlert).toList();
    } else if (_selectedFilter == 'In Stock') {
      items = items.where((item) => item.stock > item.lowStockAlert).toList();
    }

    return items;
  }

  String _syncErrorMessage(Object error) {
    if (error is cf.FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Saved locally, but Firebase denied write access.';
      }
      if (error.code == 'not-authenticated') {
        return 'Saved locally, but Firebase sync needs login first.';
      }
      return 'Saved locally, but Firebase sync failed: ${error.code}.';
    }
    return 'Saved locally, but sync failed: $error';
  }

  void _notifyInventoryChanged() {
    InventoryData.notifier.value = List<POSItem>.from(InventoryData.items);
  }

  Future<void> _persistUpdate({
    required POSItem original,
    required POSItem updated,
    String? successMessage,
  }) async {
    final index = InventoryData.items.indexOf(original);
    if (index < 0) return;

    setState(() {
      InventoryData.items[index] = updated;
    });
    _notifyInventoryChanged();

    try {
      await _inventoryController.updateProduct(
        original: original,
        updated: updated,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncErrorMessage(e)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (!mounted || successMessage == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addItem(POSItem item) async {
    setState(() => InventoryData.items.add(item));
    _notifyInventoryChanged();
    Navigator.pop(context);

    try {
      final persisted = await _inventoryController.createProduct(item: item);
      final index = InventoryData.items.indexOf(item);
      if (mounted && index >= 0) {
        setState(() => InventoryData.items[index] = persisted);
        _notifyInventoryChanged();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncErrorMessage(e)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added successfully.'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController(text: 'pcs');
    final alertController = TextEditingController(text: '10');
    var category = 'Food';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return _InventoryFormDialog(
            title: 'Add Item',
            subtitle: 'Create a new product record',
            icon: Icons.add_box_outlined,
            primaryLabel: 'Add Item',
            category: category,
            nameController: nameController,
            priceController: priceController,
            stockController: stockController,
            unitController: unitController,
            alertController: alertController,
            onCategoryChanged: (value) {
              setDialogState(() => category = value);
            },
            onCancel: () => Navigator.pop(dialogContext),
            onPrimary: () {
              final parsedPrice = int.tryParse(priceController.text.trim());
              final parsedStock = int.tryParse(stockController.text.trim());
              final parsedAlert = int.tryParse(alertController.text.trim());
              final name = nameController.text.trim();
              final unit = unitController.text.trim();

              if (name.isEmpty ||
                  parsedPrice == null ||
                  parsedStock == null ||
                  parsedAlert == null) {
                _showValidationSnackBar(
                  dialogContext,
                  'Please fill in valid name, price, stock, and alert values.',
                );
                return;
              }

              final item = POSItem(
                name: name,
                price: parsedPrice,
                stock: parsedStock,
                unit: unit.isEmpty ? 'pcs' : unit,
                category: category,
                lowStockAlert: parsedAlert,
              );
              _addItem(item);
            },
          );
        },
      ),
    );
  }

  void _showEditItemDialog(POSItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());
    final unitController = TextEditingController(text: item.unit);
    final alertController = TextEditingController(
      text: item.lowStockAlert.toString(),
    );
    var category = item.category == 'Beverages' ? 'Beverage' : item.category;
    if (!_categories.contains(category)) category = 'Food';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return _InventoryFormDialog(
            title: 'Edit Item',
            subtitle: item.name,
            icon: Icons.edit_outlined,
            primaryLabel: 'Save Changes',
            category: category,
            nameController: nameController,
            priceController: priceController,
            stockController: stockController,
            unitController: unitController,
            alertController: alertController,
            onCategoryChanged: (value) {
              setDialogState(() => category = value);
            },
            onCancel: () => Navigator.pop(dialogContext),
            onPrimary: () async {
              final parsedPrice = int.tryParse(priceController.text.trim());
              final parsedStock = int.tryParse(stockController.text.trim());
              final parsedAlert = int.tryParse(alertController.text.trim());
              final name = nameController.text.trim();
              final unit = unitController.text.trim();

              if (name.isEmpty ||
                  parsedPrice == null ||
                  parsedStock == null ||
                  parsedAlert == null) {
                _showValidationSnackBar(
                  dialogContext,
                  'Please fill in valid name, price, stock, and alert values.',
                );
                return;
              }

              final updated = POSItem(
                productId: item.productId,
                name: name,
                price: parsedPrice,
                stock: parsedStock,
                unit: unit.isEmpty ? 'pcs' : unit,
                category: category,
                lowStockAlert: parsedAlert,
                image: item.image,
              );

              Navigator.pop(dialogContext);
              await _persistUpdate(
                original: item,
                updated: updated,
                successMessage: '$name updated successfully.',
              );
            },
          );
        },
      ),
    );
  }

  void _showValidationSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddStockDialog(POSItem item) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogHeader(
                icon: Icons.add_circle_outline,
                title: 'Add Stock',
                subtitle: item.name,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current stock: ${item.stock} ${item.unit}',
                  style: const TextStyle(
                    color: _dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InventoryTextField(
                controller: quantityController,
                label: 'Quantity to Add',
                hint: '0',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final qty =
                            int.tryParse(quantityController.text.trim()) ?? 0;
                        if (qty <= 0) {
                          _showValidationSnackBar(
                            dialogContext,
                            'Enter a stock quantity greater than zero.',
                          );
                          return;
                        }

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

                        Navigator.pop(dialogContext);
                        await _persistUpdate(
                          original: item,
                          updated: updated,
                          successMessage:
                              'Added $qty ${item.unit} to ${item.name}.',
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 96.0 + MediaQuery.of(context).padding.bottom;

    return Container(
      color: const Color(0xFFF6F8FA),
      child: Stack(
        children: [
          Column(
            children: [
              _buildOverview(),
              _buildTools(),
              Expanded(
                child: _filteredItems.isEmpty
                    ? const _EmptyInventoryState()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) =>
                            _buildInventoryCard(_filteredItems[index]),
                      ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: FloatingActionButton.extended(
              onPressed: _showAddItemDialog,
              backgroundColor: _green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_green, Color(0xFF00B377)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Inventory Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('Items', '$_totalItems', Icons.widgets_outlined),
              _statBox('Stock', '$_totalStock', Icons.inventory_2_outlined),
              _statBox('Low', '$_lowStockCount', Icons.warning_amber_outlined),
              _statBox('Value', 'P$_inventoryValue', Icons.payments_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 19, color: Colors.white.withValues(alpha: 0.82)),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTools() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF7C8794)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _filterChip('All'),
              const SizedBox(width: 8),
              _filterChip('Low Stock', color: Colors.red),
              const SizedBox(width: 8),
              _filterChip('In Stock', color: _green),
              const Spacer(),
              _categoryDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, {Color? color}) {
    final active = _selectedFilter == label;
    final activeColor = color ?? _green;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? activeColor : const Color(0xFFE1E6EA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF657080),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E6EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            color: Color(0xFF384252),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedCategory = value);
          },
        ),
      ),
    );
  }

  Widget _buildInventoryCard(POSItem item) {
    final isLowStock = item.stock <= item.lowStockAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLowStock ? Colors.orange.shade200 : const Color(0xFFE8EDF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.category == 'Beverage'
                      ? Icons.local_cafe_outlined
                      : Icons.restaurant_outlined,
                  color: _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _dark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isLowStock) const SizedBox(width: 8),
                        if (isLowStock) _lowStockBadge(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.category} - P${item.price}',
                      style: const TextStyle(
                        color: Color(0xFF7B8490),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _cardAction(
                icon: Icons.edit_outlined,
                color: const Color(0xFF2563EB),
                onTap: () => _showEditItemDialog(item),
              ),
              const SizedBox(width: 6),
              _cardAction(
                icon: Icons.add_circle_outline,
                color: _green,
                onTap: () => _showAddStockDialog(item),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _infoTile(
                    'Current Stock',
                    '${item.stock} ${item.unit}',
                    Icons.inventory_2_outlined,
                    isLowStock ? Colors.red : _green,
                  ),
                ),
                Container(width: 1, height: 38, color: const Color(0xFFE2E7EC)),
                Expanded(
                  child: _infoTile(
                    'Alert Level',
                    '${item.lowStockAlert} ${item.unit}',
                    Icons.notifications_outlined,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lowStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'Low',
        style: TextStyle(
          color: Colors.orange.shade800,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _cardAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: icon == Icons.edit_outlined ? 'Edit item' : 'Add stock',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7B8490),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _dark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryFormDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryLabel;
  final String category;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final TextEditingController unitController;
  final TextEditingController alertController;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onCancel;
  final VoidCallback onPrimary;

  const _InventoryFormDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryLabel,
    required this.category,
    required this.nameController,
    required this.priceController,
    required this.stockController,
    required this.unitController,
    required this.alertController,
    required this.onCategoryChanged,
    required this.onCancel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DialogHeader(icon: icon, title: title, subtitle: subtitle),
                const SizedBox(height: 20),
                _InventoryTextField(
                  controller: nameController,
                  label: 'Product Name',
                  hint: 'e.g. Mango Shake 16oz',
                  icon: Icons.fastfood_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InventoryTextField(
                        controller: priceController,
                        label: 'Price',
                        hint: '0',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InventoryTextField(
                        controller: stockController,
                        label: 'Stock',
                        hint: '0',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InventoryTextField(
                        controller: unitController,
                        label: 'Unit',
                        hint: 'pcs',
                        icon: Icons.straighten_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InventoryTextField(
                        controller: alertController,
                        label: 'Low Alert',
                        hint: '10',
                        icon: Icons.warning_amber_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(
                    color: Color(0xFF303A46),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _CategoryButton(
                      label: 'Food',
                      icon: Icons.restaurant_outlined,
                      selected: category == 'Food',
                      onTap: () => onCategoryChanged('Food'),
                    ),
                    const SizedBox(width: 10),
                    _CategoryButton(
                      label: 'Beverage',
                      icon: Icons.local_cafe_outlined,
                      selected: category == 'Beverage',
                      onTap: () => onCategoryChanged('Beverage'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onPrimary,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(primaryLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009661),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
}

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF009661).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFF009661)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF18212F),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7B8490),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }
}

class _InventoryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _InventoryTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF009661), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF009661), width: 1.4),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF009661) : const Color(0xFFF3F6F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF009661)
                  : const Color(0xFFE1E6EA),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF697586),
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF697586),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyInventoryState extends StatelessWidget {
  const _EmptyInventoryState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, color: Color(0xFF9CA3AF), size: 42),
          SizedBox(height: 10),
          Text(
            'No products found',
            style: TextStyle(
              color: Color(0xFF657080),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
