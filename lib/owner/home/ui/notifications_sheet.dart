import 'package:flutter/material.dart';

import '../../../data/inventory_data.dart';

class NotificationsSheet extends StatelessWidget {
  final ScrollController scrollController;
  const NotificationsSheet({super.key, required this.scrollController});

  List<Map<String, dynamic>> get lowStockAlerts {
    return InventoryData.items
        .where((i) => i.stock <= i.lowStockAlert)
        .map((i) => {
              'name': i.name,
              'message': 'Only ${i.stock} ${i.unit} left',
              'type': 'lowstock',
              'item': i,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notifications',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('${lowStockAlerts.length}',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (lowStockAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text('All clear!',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('No alerts at the moment',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 14)),
                ],
              ),
            )
          else ...[
            const Text('Low Stock Alerts',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333))),
            const SizedBox(height: 12),
            ...lowStockAlerts.map((alert) => _alertCard(alert)),
          ],
        ],
      ),
    );
  }

  Widget _alertCard(Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.warning_amber,
                color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(alert['message'],
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
