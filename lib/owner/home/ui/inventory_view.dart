import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/inventory_data.dart';
import '../../../model/pos_item_model.dart';
import '../logic/inventory_controller.dart';
import '../logic/notifications_controller.dart';
import '../../../ui/confirmation_dialog.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});
  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final InventoryController _inventoryController = const InventoryController();
  final NotificationsController _notificationsController =
      const NotificationsController();
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
    await _notificationsController.syncLowStockAlertsWithInventory();
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
    await _notificationsController.syncLowStockAlertsWithInventory();
  }

  List<POSItem> get filteredItems {
    if (_searchQuery.isEmpty) return InventoryData.items;
    return InventoryData.items
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showAddStockDialog(POSItem item) {
    final TextEditingController stockController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock - ${item.name}'),
        content: TextField(
          controller: stockController,
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
              int? qty = int.tryParse(stockController.text);
              if (qty != null && qty > 0) {
                final confirmed = await ConfirmationDialog.showRestockConfirmation(
                  context: context,
                  itemName: item.name,
                  quantity: qty,
                );

                if (!confirmed!) return;

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

                await _persistItemUpdate(original: item, updated: updated);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $qty ${item.unit} to ${item.name}'),
                    backgroundColor: const Color(0xFF009661),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final stockController = TextEditingController(text: item.stock.toString());
    final priceController = TextEditingController(text: item.price.toString());
    final thresholdController = TextEditingController(
      text: item.lowStockAlert.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Low Stock Alert',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final parsedStock = int.tryParse(stockController.text);
              final parsedThreshold = int.tryParse(thresholdController.text);
              final parsedPrice = int.tryParse(priceController.text);

              if (parsedStock == null ||
                  parsedThreshold == null ||
                  parsedPrice == null) {
                return;
              }

              final confirmed = await ConfirmationDialog.showEditConfirmation(
                context: context,
                itemName: item.name,
              );

              if (!confirmed!) return;

              final updated = POSItem(
                productId: item.productId,
                name: item.name,
                price: parsedPrice,
                stock: parsedStock,
                unit: item.unit,
                category: item.category,
                lowStockAlert: parsedThreshold,
                image: item.image,
              );

              await _persistItemUpdate(original: item, updated: updated);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} updated successfully'),
                  backgroundColor: const Color(0xFF009661),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Inventory Management",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
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
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildProductImageThumb(item.image),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.category,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddStockDialog(item),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF009661)),
                label: const Text(
                  'Add Stock',
                  style: TextStyle(color: Color(0xFF009661), fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF009661)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showEditItemDialog(item),
                icon: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Color(0xFF3B82F6),
                ),
                label: const Text(
                  'Edit',
                  style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₱${item.price}',
            style: const TextStyle(
              color: Color(0xFF009661),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.stock} ${item.unit}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isLowStock ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low Stock Alert',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.lowStockAlert} ${item.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImageThumb(String? imagePathOrUrl) {
    final fallback = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF009661).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined, color: Color(0xFF009661)),
    );

    if (imagePathOrUrl == null || imagePathOrUrl.trim().isEmpty) {
      return fallback;
    }

    final imageRef = imagePathOrUrl.trim();
    final parsed = Uri.tryParse(imageRef);
    final isNetwork =
        parsed != null && (parsed.scheme == 'http' || parsed.scheme == 'https');

    if (isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageRef,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        ),
      );
    }

    final file = File(imageRef);
    if (!file.existsSync()) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
