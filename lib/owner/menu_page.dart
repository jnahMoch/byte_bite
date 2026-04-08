import 'package:flutter/material.dart';

import 'homepage.dart' show InventoryData, POSItem;
import 'menu/ui/add_product_dialog.dart';
import 'menu/ui/menu_card.dart';
import '../ui/confirmation_dialog.dart';
import 'menu/ui/category_header.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  void _deleteProduct(POSItem item) async {
    final confirmed = await ConfirmationDialog.showDeleteConfirmation(
      context: context,
      itemName: item.name,
      additionalMessage: 'You will not be able to recover this product.',
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
    final foodItems = InventoryData.items
        .where((i) => i.category == 'Food')
        .toList();
    final beverageItems = InventoryData.items
        .where((i) => i.category == 'Beverage')
        .toList();

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(foodItems.length + beverageItems.length),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CategoryHeader(
                  title: 'Food Items',
                  count: '${foodItems.length}',
                  icon: Icons.restaurant_rounded,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                ...foodItems.map((item) => MenuCard(
                  item: item,
                  onEdit: () {},
                  onDelete: () => _deleteProduct(item),
                )),
                const SizedBox(height: 20),
                CategoryHeader(
                  title: 'Beverages',
                  count: '${beverageItems.length}',
                  icon: Icons.local_cafe_rounded,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 12),
                ...beverageItems.map((item) => MenuCard(
                  item: item,
                  onEdit: () {},
                  onDelete: () => _deleteProduct(item),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalItems) {
    return Container(
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
                child: const Icon(Icons.restaurant_menu_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menu Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    '$totalItems items total',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              showAddProductDialog(context, (newItem) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${newItem.name} added to menu'),
                    backgroundColor: const Color(0xFF009661),
                  ),
                );
              });
            },
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: const Text('Add Item',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009661),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}