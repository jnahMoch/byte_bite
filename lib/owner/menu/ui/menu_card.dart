import 'package:flutter/material.dart';

import '../../homepage.dart' show POSItem;

class MenuCard extends StatelessWidget {
  final POSItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.stock <= item.lowStockAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A1A2E))),
                    ),
                    if (isLowStock) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [
                            Color(0xFFEF4444),
                            Color(0xFFDC2626)
                          ]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Low',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009661).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('₱${item.price}',
                          style: const TextStyle(
                              color: Color(0xFF009661),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.inventory_2_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text("${item.stock} ${item.unit}",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.notifications_outlined,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text("Alert at ${item.lowStockAlert} ${item.unit}",
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _ActionButton(
                icon: Icons.edit_rounded,
                color: const Color(0xFF6B7280),
                bgColor: const Color(0xFFF3F4F6),
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete_rounded,
                color: const Color(0xFFEF4444),
                bgColor: const Color(0xFFFEE2E2),
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
