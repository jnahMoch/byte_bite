import 'package:flutter/material.dart';

import '../logic/notifications_controller.dart';
import 'notification_detail_view.dart';

class NotificationsSheet extends StatefulWidget {
  final ScrollController scrollController;
  const NotificationsSheet({super.key, required this.scrollController});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final NotificationsController _controller = const NotificationsController();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersistedAlerts();
  }

  Future<void> _loadPersistedAlerts() async {
    await _controller.initialize();
    final alerts = await _controller.getAllNotificationsSorted();

    // Opening the notifications view marks current alerts as read.
    await _controller.markAllAsRead();

    if (!mounted) return;
    setState(() {
      _notifications = alerts;
      _isLoading = false;
    });
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
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ValueListenableBuilder<int>(
                valueListenable: NotificationsController.unreadCountNotifier,
                builder: (context, unreadCount, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All clear!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No alerts at the moment',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              'All Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            ..._notifications.map((alert) => _alertCard(context, alert)),
          ],
        ],
      ),
    );
  }

  Widget _alertCard(BuildContext context, Map<String, dynamic> alert) {
    final type = (alert['type'] ?? 'lowstock').toString();
    final isLowStock = type == 'lowstock';
    final accent = isLowStock ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLowStock ? Colors.orange.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLowStock ? Icons.warning_amber : Icons.receipt_long,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  alert['message'],
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final id = (alert['id'] ?? '').toString();
              if (id.isNotEmpty && isLowStock) {
                await _controller.markAsRead(id);
              }
              final item = alert['item'];
              final currentStock = item is Map<String, dynamic>
                  ? (item['stock'] as num?)?.toInt() ?? 0
                  : (item.stock as int? ?? 0);
              final unit = item is Map<String, dynamic>
                  ? (item['unit'] as String? ?? 'pcs')
                  : (item.unit as String? ?? 'pcs');
              final lowStockThreshold = item is Map<String, dynamic>
                  ? (item['lowStockAlert'] as num?)?.toInt() ?? 0
                  : (item.lowStockAlert as int? ?? 0);
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationDetailView(
                    productName: alert['name'],
                    alertType: alert['type'],
                    currentStock: currentStock,
                    unit: unit,
                    lowStockThreshold: lowStockThreshold,
                    amountDue:
                        (alert['amountDue'] as num?)?.toDouble() ??
                        (item is Map<String, dynamic>
                            ? (item['amountDue'] as num?)?.toDouble()
                            : null),
                    dueDate:
                        (alert['dueDate'] as String?) ??
                        (item is Map<String, dynamic>
                            ? (item['dueDate'] as String?)
                            : null),
                    paymentStatus:
                        (alert['paymentStatus'] as String?) ??
                        (item is Map<String, dynamic>
                            ? (item['paymentStatus'] as String?)
                            : null),
                  ),
                ),
              );
            },
            child: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
