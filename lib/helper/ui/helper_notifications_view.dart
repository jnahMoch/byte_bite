import 'package:flutter/material.dart';

import '../../owner/home/logic/notifications_controller.dart';

/// Notifications view for Helper showing low stock alerts and bill reminders
class HelperNotificationsView extends StatefulWidget {
  const HelperNotificationsView({super.key});

  @override
  State<HelperNotificationsView> createState() =>
      _HelperNotificationsViewState();
}

class _HelperNotificationsViewState extends State<HelperNotificationsView> {
  final NotificationsController _controller = const NotificationsController();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await _controller.initialize();
    final notifications = await _controller.getAllNotificationsSorted();

    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lowStockItems = _notifications
        .where((n) => (n['type'] ?? '').toString() == 'lowstock')
        .toList();
    final billReminders = _notifications
        .where((n) => (n['type'] ?? '').toString() == 'bill')
        .toList();
    final hasAlerts = lowStockItems.isNotEmpty || billReminders.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (hasAlerts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_notifications.length} alerts',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Operational alerts: Low stock & bill reminders',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !hasAlerts
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'All Good!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No alerts at the moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, i) {
                    final notification = _notifications[i];
                    return _notificationCard(notification);
                  },
                ),
        ),
      ],
    );
  }

  Widget _notificationCard(Map<String, dynamic> notification) {
    final type = (notification['type'] ?? 'lowstock').toString();
    final isLowStock = type == 'lowstock';
    final accent = isLowStock ? Colors.orange : Colors.blue;
    final accentLight = isLowStock
        ? Colors.orange.shade50
        : Colors.blue.shade50;
    final message = (notification['message'] ?? '').toString();
    final name = (notification['name'] ?? 'Unknown').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLowStock ? Icons.warning_amber_rounded : Icons.receipt_long,
              color: accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLowStock ? 'Low Stock Alert' : 'Bill Reminder',
                  style: TextStyle(fontWeight: FontWeight.bold, color: accent),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
