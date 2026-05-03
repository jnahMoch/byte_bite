import 'package:byte_bite/shared/inventory/inventory_page.dart'
    as shared_inventory;
import 'package:flutter/material.dart';

class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return const shared_inventory.InventoryPage(userRole: 'owner');
  }
}
