import 'package:byte_bite/shared/inventory/inventory_page.dart'
    as shared_inventory;
import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const shared_inventory.InventoryPage(userRole: 'owner');
  }
}
