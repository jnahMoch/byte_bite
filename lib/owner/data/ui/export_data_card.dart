import 'package:flutter/material.dart';

class ExportDataCard extends StatelessWidget {
  final VoidCallback onPressed;

  const ExportDataCard({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009661), Color(0xFF00B67A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Text("Export Backup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Download all your data (products, transactions, bills) as a backup file. Keep this safe!",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
              label: const Text("Export Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009661),
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
