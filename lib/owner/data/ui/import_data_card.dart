import 'package:flutter/material.dart';

class ImportDataCard extends StatelessWidget {
  final VoidCallback onPressed;

  const ImportDataCard({super.key, required this.onPressed});

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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_rounded, color: Color(0xFF3B82F6), size: 22),
              ),
              const SizedBox(width: 14),
              const Text("Import Backup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Restore your data from a previously exported backup file. This will replace current data.",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.upload_rounded, color: Color(0xFF3B82F6), size: 20),
              label: const Text("Import Data", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
