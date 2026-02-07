import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title Section
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Inventory Management",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF050718),
            ),
          ),
        ),

        // 2. Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // 3. Inventory List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInventoryCard(
                name: "Corndog",
                category: "Food",
                price: "₱25",
                currentStock: "30 pieces",
                lowStockAlert: "5 pieces",
              ),
              _buildInventoryCard(
                name: "Siomai",
                category: "Food",
                price: "₱20",
                currentStock: "100 pieces",
                lowStockAlert: "20 pieces",
              ),
              _buildInventoryCard(
                name: "Empanada",
                category: "Food",
                price: "₱15",
                currentStock: "40 pieces",
                lowStockAlert: "10 pieces",
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to create the product cards
  Widget _buildInventoryCard({
    required String name,
    required String category,
    required String price,
    required String currentStock,
    required String lowStockAlert,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Info and Add Stock Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  Text(
                    category,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFF009661),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              // Add Stock Button
              OutlinedButton.icon(
                onPressed: () {
                  // Logic to increase stock goes here
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.grey),
                label: const Text(
                  "Add Stock",
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          ),

          // Bottom Row: Stock Levels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStockIndicator("Current Stock", currentStock, isAlert: false),
              _buildStockIndicator("Low Stock Alert", lowStockAlert, isAlert: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator(String label, String value, {required bool isAlert}) {
    return Column(
      crossAxisAlignment: isAlert ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF050718),
          ),
        ),
      ],
    );
  }
}