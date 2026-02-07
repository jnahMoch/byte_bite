import 'package:flutter/material.dart';

class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Data Management",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 1. Storage Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7CFF), // Blue background from image
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storage, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Storage Overview",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _storageMetric("Products", "10"),
                    _storageMetric("Transactions", "0"),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _storageMetric("Bills", "3"),
                    _storageMetric("Data Size", "1.46 KB"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Export Backup Section
          _managementActionCard(
            title: "Export Backup",
            description: "Download all your data (products, transactions, bills) as a backup file. Keep this safe!",
            buttonLabel: "Export Data",
            buttonIcon: Icons.download,
            buttonColor: const Color(0xFF009661),
          ),

          const SizedBox(height: 16),

          // 3. Import Backup Section
          _managementActionCard(
            title: "Import Backup",
            description: "Restore your data from a previously exported backup file. This will replace current data.",
            buttonLabel: "Import Data",
            buttonIcon: Icons.upload,
            buttonColor: Colors.white,
            textColor: Colors.black,
            isOutlined: true,
          ),
          
          const SizedBox(height: 16),
          
          // 4. Reset Action (Dashed/Red Warning Area)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade200, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: Colors.red.shade50,
            ),
            child: Column(
              children: [
                Text("Danger Zone", style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text("Clear All Data", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // Helper for Storage Metrics in the Blue Card
  Widget _storageMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Helper for Export/Import White Cards
  Widget _managementActionCard({
    required String title,
    required String description,
    required String buttonLabel,
    required IconData buttonIcon,
    required Color buttonColor,
    Color textColor = Colors.white,
    bool isOutlined = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(buttonIcon, color: const Color(0xFF009661), size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(buttonIcon, color: textColor, size: 18),
              label: Text(buttonLabel, style: TextStyle(color: textColor)),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                elevation: 0,
                side: isOutlined ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}