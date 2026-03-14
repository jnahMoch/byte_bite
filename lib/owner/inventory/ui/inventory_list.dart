import 'package:flutter/material.dart';
import 'inventory_card.dart';

/// A scrollable list of inventory items. The [onItemUpdated] callback is
/// invoked whenever an item is changed (e.g. stock added) so that the caller
/// can refresh state.
class InventoryList extends StatelessWidget {
  final List<dynamic> items;
  final void Function() onItemUpdated;

  const InventoryList({
    super.key,
    required this.items,
    required this.onItemUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InventoryCard(item: item, onUpdated: onItemUpdated);
      },
    );
  }
}
