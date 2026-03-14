import '../../homepage.dart' show InventoryData, POSItem;

/// Contains business logic and state management for the inventory section.
///
/// UI code should call into this class for any computations or mutations.
class InventoryCore {
  /// Returns a filtered list of items based on the search query.
  static List<dynamic> getFilteredItems(String query) {
    if (query.isEmpty) return InventoryData.items;
    return InventoryData.items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Adds a new item to the inventory.
  static void addItem(POSItem item) {
    InventoryData.items.add(item);
  }

  /// Increases the stock of the given [item] by [qty].
  static void addStock(dynamic item, int qty) {
    item.stock += qty;
  }

  /// Convenience helper used in the header of the page.
  static int totalProducts() => InventoryData.items.length;

  static String productsSummary() => '${InventoryData.items.length} products';
}
