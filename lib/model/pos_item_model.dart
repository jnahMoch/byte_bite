class POSItem {
  final int? productId; // Link to database product
  final String name;
  final int price;
  int stock;
  final String unit;
  final String category;
  final int lowStockAlert;
  final String? image;

  POSItem({
    this.productId,
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
    this.category = 'Food',
    this.lowStockAlert = 10,
    this.image,
  });
}
