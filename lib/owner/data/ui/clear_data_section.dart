import 'package:flutter/material.dart';

class ClearDataSection extends StatelessWidget {
  final VoidCallback onPressed;

  const ClearDataSection({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
              ),
              const SizedBox(width: 14),
              Text("Danger Zone", style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Permanently delete all data including products, transactions, and bills. This cannot be undone!",
            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
              label: const Text("Clear All Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
