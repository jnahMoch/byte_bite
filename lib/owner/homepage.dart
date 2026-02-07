import 'package:flutter/material.dart';

// --- DATA MODEL ---
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
  int _currentIndex = 0; // Tracks the selected bottom nav tab

  // 1. All Main Views Connected Here
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const POSGridView(),        // Index 0: POS
      const InventoryView(),     // Index 1: Inventory
      const ReportsView(),       // Index 2: Reports
      const BillsView(),         // Index 3: Bills
      const MenuView(),          // Index 4: Menu
      const DataManagementView(),// Index 5: Data
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header remains constant across all pages
          _buildHeader(context),
          
          // Body changes based on bottom bar selection
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF009661),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Switch Page
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'POS'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Bills'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Data'),
        ],
      ),
    );
  }

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
              Text('Byte & Bite POS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Owner (owner)', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D47),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}

// --- SUB-VIEW 0: POS GRID ---
class POSGridView extends StatefulWidget {
  const POSGridView({super.key});

  @override
  State<POSGridView> createState() => _POSGridViewState();
}

class _POSGridViewState extends State<POSGridView> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _tab("All", true), const SizedBox(width: 8),
              _tab("Food", false), const SizedBox(width: 8),
              _tab("Beverage", false),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) => _itemCard(menuItems[index]),
          ),
        ),
      ],
    );
  }

  Widget _tab(String label, bool active) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF050718) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
    ),
  );

  Widget _itemCard(POSItem item) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2),
        const SizedBox(height: 6),
        Text('₱${item.price}', style: const TextStyle(color: Color(0xFF009661), fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text('Stock: ${item.stock} ${item.unit}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    ),
  );
}

// --- SUB-VIEW 1: INVENTORY ---
class InventoryView extends StatelessWidget {
  const InventoryView({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.all(16), child: Text("Inventory Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(decoration: InputDecoration(hintText: "Search products...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
        ),
        const Expanded(child: Center(child: Text("Inventory Items List Here"))),
      ],
    );
  }
}

// --- SUB-VIEW 2: REPORTS ---
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Reports and Analytics Dashboard"));
  }
}

// --- SUB-VIEW 3: BILLS ---
class BillsView extends StatelessWidget {
  const BillsView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Bill Reminders & Tracking"));
  }
}

// --- SUB-VIEW 4: MENU ---
class MenuView extends StatelessWidget {
  const MenuView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Menu Editing & Customization"));
  }
}

// --- SUB-VIEW 5: DATA ---
class DataManagementView extends StatelessWidget {
  const DataManagementView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Storage & Backup Management"));
  }
}