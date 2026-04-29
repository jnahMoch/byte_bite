import 'package:byte_bite/shared/inventory/inventory_page.dart' as SharedInventory;
import 'package:flutter/material.dart';

class HelperInventoryView extends StatelessWidget {
  const HelperInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SharedInventory.InventoryPage(userRole: 'helper');
  }
}
