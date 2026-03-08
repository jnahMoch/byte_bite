class POSItem {
  final String name;
  final int price;
  int stock;
  final String unit;
  final String category;
  final int lowStockAlert;
  final String? image;

  POSItem({
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
    this.category = 'Food',
    this.lowStockAlert = 10,
    this.image,
  });
}
