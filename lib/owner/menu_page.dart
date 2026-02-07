import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Section with Title and Add Item Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Menu Management",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text("Add Item", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009661),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // 2. Menu List with Categories
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Food Category
              _buildCategoryHeader("Food Items (4)", Icons.restaurant),
              _menuManagementCard("Chicken with Rice", "₱45", "50 servings", "10 servings"),
              _menuManagementCard("Corndog", "₱25", "30 pieces", "5 pieces"),
              _menuManagementCard("Siomai", "₱20", "100 pieces", "20 pieces"),
              _menuManagementCard("Empanada", "₱15", "40 pieces", "10 pieces"),

              const SizedBox(height: 16),

              // Beverage Category
              _buildCategoryHeader("Beverage Items (6)", Icons.local_drink),
              // Placeholder for Beverage Items
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("Beverage items listed here", style: TextStyle(color: Colors.grey))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for Category Headers
  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color.fromRGBO(5, 7, 24, 0.7)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF050718)),
          ),
        ],
      ),
    );
  }

  // Helper for individual Menu Management Cards
  Widget _menuManagementCard(String name, String price, String stock, String alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Item Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(price, style: const TextStyle(color: Color(0xFF009661), fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Text("Stock: $stock", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text("Alert: $alert", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),

          // Action Buttons (Edit and Delete)
          Row(
            children: [
              _actionButton(Icons.edit_note, Colors.grey.shade700, Colors.grey.shade100),
              const SizedBox(width: 8),
              _actionButton(Icons.delete_outline, Colors.red, const Color(0xFFFFF5F5)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for the Edit/Delete icons
  Widget _actionButton(IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}