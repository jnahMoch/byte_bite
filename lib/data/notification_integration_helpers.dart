import 'package:flutter/material.dart';
import 'notification_badge_service.dart';

/// Extension on NotificationsController to add interactive notification support
extension InteractiveNotifications on dynamic {
  /// Add a badge for each low stock item
  static Future<void> createLowStockBadges({
    required List<dynamic> items,
    required BuildContext context,
  }) async {
    final badgeService = NotificationBadgeService();

    for (final item in items) {
      if (item.stock <= item.lowStockAlert) {
        final badgeId = 'lowstock_${item.name}_${DateTime.now().millisecondsSinceEpoch}';

        // Determine priority
        late BadgePriority priority;
        if (item.stock == 0) {
          priority = BadgePriority.critical;
        } else if (item.stock <= item.lowStockAlert ~/ 2) {
          priority = BadgePriority.high;
        } else {
          priority = BadgePriority.normal;
        }

        await badgeService.addBadge(
          badgeId: badgeId,
          notificationId: 'lowstock:${item.name}',
          type: 'lowstock',
          title: 'Low Stock: ${item.name}',
          description: '${item.stock} ${item.unit} remaining (Alert: ${item.lowStockAlert})',
          priority: priority,
          actionType: 'low_stock',
          actionData: item.name,
        );

        // Add action buttons
        await badgeService.addBadgeAction(
          badgeId: badgeId,
          actionName: 'add_stock',
          actionLabel: 'Add Stock',
          actionColor: '#4CAF50',
          iconName: 'add_circle',
          isPrimary: true,
        );

        await badgeService.addBadgeAction(
          badgeId: badgeId,
          actionName: 'view_details',
          actionLabel: 'Details',
          actionColor: '#2196F3',
          iconName: 'info',
        );
      }
    }
  }

  /// Add a badge for overdue bill reminders
  static Future<void> createBillReminders({
    required List<dynamic> bills,
    required BuildContext context,
  }) async {
    final badgeService = NotificationBadgeService();

    for (final bill in bills) {
      try {
        final dueDateParsed = DateTime.parse(bill.dueDate);
        final daysUntilDue = dueDateParsed.difference(DateTime.now()).inDays;

        final badgeId = 'bill_${bill.number}_${DateTime.now().millisecondsSinceEpoch}';

        late BadgePriority priority;
        if (daysUntilDue <= 0) {
          priority = BadgePriority.critical;
        } else if (daysUntilDue <= 3) {
          priority = BadgePriority.high;
        } else {
          priority = BadgePriority.normal;
        }

        await badgeService.addBadge(
          badgeId: badgeId,
          notificationId: 'bill:${bill.number}',
          type: 'bill',
          title: 'Payment Reminder: Bill #${bill.number}',
          description: '₱${bill.totalAmount.toStringAsFixed(2)} due on ${bill.dueDate}',
          priority: priority,
          actionType: 'bill_reminder',
          actionData: bill.number,
        );

        // Add action buttons
        await badgeService.addBadgeAction(
          badgeId: badgeId,
          actionName: 'pay_now',
          actionLabel: 'Pay Now',
          actionColor: '#4CAF50',
          iconName: 'payment',
          isPrimary: true,
        );

        await badgeService.addBadgeAction(
          badgeId: badgeId,
          actionName: 'extend_due',
          actionLabel: 'Extend',
          actionColor: '#FF9800',
          iconName: 'schedule',
        );
      } catch (e) {
        debugPrint('Error creating bill reminder: $e');
      }
    }
  }
}

/// Reusable widget to display notification badges count in navigation items
class NotificationBadgeWidget extends StatelessWidget {
  final int badgeCount;
  final BadgePriority priority;
  final VoidCallback? onTap;

  const NotificationBadgeWidget({
    super.key,
    this.badgeCount = 0,
    this.priority = BadgePriority.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeCount == 0) {
      return const SizedBox.shrink();
    }

    Color badgeColor;
    switch (priority) {
      case BadgePriority.critical:
        badgeColor = Colors.red;
        break;
      case BadgePriority.high:
        badgeColor = Colors.deepOrange;
        break;
      case BadgePriority.normal:
        badgeColor = Colors.orange;
        break;
      case BadgePriority.low:
        badgeColor = Colors.grey;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Text(
          badgeCount > 99 ? '99+' : '$badgeCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Helper widget to show notification status in UI
class NotificationStatusWidget extends StatefulWidget {
  final Duration refreshInterval;
  final Widget Function(BuildContext, bool hasCritical, int count) builder;

  const NotificationStatusWidget({
    super.key,
    this.refreshInterval = const Duration(seconds: 30),
    required this.builder,
  });

  @override
  State<NotificationStatusWidget> createState() =>
      _NotificationStatusWidgetState();
}

class _NotificationStatusWidgetState extends State<NotificationStatusWidget> {
  late NotificationBadgeService _badgeService;
  bool _hasCritical = false;
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();
    _badgeService = NotificationBadgeService();
    _badgeService.initialize().then((_) {
      _updateStatus();
      NotificationBadgeService.pendingBadgeCountNotifier.addListener(_refreshStatus);
    });
  }

  Future<void> _updateStatus() async {
    final hasCritical = await _badgeService.hasCriticalBadges();
    final count = NotificationBadgeService.pendingBadgeCountNotifier.value;

    if (mounted) {
      setState(() {
        _hasCritical = hasCritical;
        _badgeCount = count;
      });
    }
  }

  void _refreshStatus() {
    _updateStatus();
  }

  @override
  void dispose() {
    NotificationBadgeService.pendingBadgeCountNotifier.removeListener(_refreshStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _hasCritical, _badgeCount);
  }
}
