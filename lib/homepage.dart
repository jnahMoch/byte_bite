import 'package:flutter/material.dart';

// 1. Data Model for Menu Items
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

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  // Mock data based on your image
  final List<POSItem> menuItems = [
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

  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section
          _buildHeader(context),

          // Category Tabs
          _buildCategoryTabs(),

          // Grid of Items
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuCard(menuItems[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF009661),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Byte & Bite POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Owner (owner)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate back to Login and clear the navigation stack
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D47),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _categoryButton("All"),
          const SizedBox(width: 8),
          _categoryButton("Food"),
          const SizedBox(width: 8),
          _categoryButton("Beverage"),
        ],
      ),
    );
  }

  Widget _categoryButton(String title) {
    bool isActive = selectedCategory == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedCategory = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF050718) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(POSItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '₱${item.price}',
            style: const TextStyle(
              color: Color(0xFF009661),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock: ${item.stock} ${item.unit}',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF009661),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'POS'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
        BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Bills'),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Data'),
      ],
    );
  }
}