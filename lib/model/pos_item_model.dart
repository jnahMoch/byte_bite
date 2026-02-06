class POSItem {
  final String name;
  final int price;
  final int stock;
  final String unit;

  POSItem({
    required this.name,
    required this.price,
    required this.stock,
    required this.unit,
  });
}

// Mock data based on your image
List<POSItem> menuItems = [
  POSItem(name: "Chicken with Rice", price: 45, stock: 50, unit: "servings"),
  POSItem(name: "Corndog", price: 25, stock: 30, unit: "pieces"),
  POSItem(name: "Siomai", price: 20, stock: 100, unit: "pieces"),
  POSItem(name: "Empanada", price: 15, stock: 40, unit: "pieces"),
  POSItem(name: "Shake", price: 35, stock: 25, unit: "cups"),
  POSItem(name: "Lemonade", price: 30, stock: 30, unit: "cups"),
  POSItem(name: "Coke", price: 20, stock: 48, unit: "bottles"),
  POSItem(name: "Royal", price: 20, stock: 36, unit: "bottles"),
  POSItem(name: "Sprite", price: 20, stock: 24, unit: "bottles"),
  POSItem(name: "Bottled Water", price: 15, stock: 50, unit: "bottles"),
];