import 'package:flutter/material.dart';
import 'notification_badge_service.dart';
import '../ui/notification_widgets.dart';

/// Manages interactive notifications with direct action support
class InteractiveNotificationManager {
  static final InteractiveNotificationManager _instance =
      InteractiveNotificationManager._internal();

  factory InteractiveNotificationManager() => _instance;
  InteractiveNotificationManager._internal();

  final Map<String, Function(BuildContext)> _actionHandlers = {};

  /// Register an action handler for a specific action type
  void registerActionHandler(
      String actionType, Future<void> Function(BuildContext) handler) {
    _actionHandlers[actionType] = handler;
  }

  /// Create an interactive low-stock notification
  Future<void> createLowStockNotification({
    required String productName,
    required int currentStock,
    required int lowStockThreshold,
    required String unit,
    required BuildContext context,
    VoidCallback? onAddStock,
    VoidCallback? onViewDetails,
  }) async {
    final badgeId = 'lowstock_${productName}_${DateTime.now().millisecondsSinceEpoch}';
    final badgeService = NotificationBadgeService();

    // Determine priority based on stock level
    late BadgePriority priority;
    if (currentStock == 0) {
      priority = BadgePriority.critical;
    } else if (currentStock <= lowStockThreshold ~/ 2) {
      priority = BadgePriority.high;
    } else {
      priority = BadgePriority.normal;
    }

    // Add badge
    await badgeService.addBadge(
      badgeId: badgeId,
      notificationId: 'lowstock:$productName',
      type: 'lowstock',
      title: 'Low Stock: $productName',
      description: '$currentStock $unit remaining (Alert: $lowStockThreshold)',
      priority: priority,
      actionType: 'low_stock',
      actionData: productName,
    );

    // Add action buttons
    if (onAddStock != null) {
      await badgeService.addBadgeAction(
        badgeId: badgeId,
        actionName: 'add_stock',
        actionLabel: 'Add Stock',
        actionColor: '#4CAF50',
        iconName: 'add_circle',
        isPrimary: true,
      );
    }

    if (onViewDetails != null) {
      await badgeService.addBadgeAction(
        badgeId: badgeId,
        actionName: 'view_details',
        actionLabel: 'View Details',
        actionColor: '#2196F3',
        iconName: 'info',
      );
    }
  }

  /// Create an interactive bill payment reminder
  Future<void> createBillReminderNotification({
    required String billNumber,
    required double amountDue,
    required String dueDate,
    required BuildContext context,
    VoidCallback? onMakePayment,
    VoidCallback? onViewBill,
    VoidCallback? onExtendDue,
  }) async {
    final badgeId = 'bill_${billNumber}_${DateTime.now().millisecondsSinceEpoch}';
    final badgeService = NotificationBadgeService();

    // Determine priority based on due date
    late BadgePriority priority;
    try {
      final dueDateParsed = DateTime.parse(dueDate);
      final daysUntilDue = dueDateParsed.difference(DateTime.now()).inDays;

      if (daysUntilDue <= 0) {
        priority = BadgePriority.critical;
      } else if (daysUntilDue <= 3) {
        priority = BadgePriority.high;
      } else {
        priority = BadgePriority.normal;
      }
    } catch (_) {
      priority = BadgePriority.normal;
    }

    // Add badge
    await badgeService.addBadge(
      badgeId: badgeId,
      notificationId: 'bill:$billNumber',
      type: 'bill',
      title: 'Payment Reminder: Bill #$billNumber',
      description: '₱${amountDue.toStringAsFixed(2)} due on $dueDate',
      priority: priority,
      actionType: 'bill_reminder',
      actionData: billNumber,
    );

    // Add action buttons
    if (onMakePayment != null) {
      await badgeService.addBadgeAction(
        badgeId: badgeId,
        actionName: 'make_payment',
        actionLabel: 'Pay Now',
        actionColor: '#4CAF50',
        iconName: 'payment',
        isPrimary: true,
      );
    }

    if (onExtendDue != null) {
      await badgeService.addBadgeAction(
        badgeId: badgeId,
        actionName: 'extend_due',
        actionLabel: 'Extend Due Date',
        actionColor: '#FF9800',
        iconName: 'schedule',
      );
    }

    if (onViewBill != null) {
      await badgeService.addBadgeAction(
        badgeId: badgeId,
        actionName: 'view_bill',
        actionLabel: 'View Details',
        actionColor: '#2196F3',
        iconName: 'receipt',
      );
    }
  }

  /// Create an interactive system alert
  Future<void> createSystemAlert({
    required String alertId,
    required String title,
    required String message,
    BadgePriority priority = BadgePriority.normal,
    List<NotificationAction>? actions,
  }) async {
    final badgeService = NotificationBadgeService();

    await badgeService.addBadge(
      badgeId: alertId,
      notificationId: 'system:$alertId',
      type: 'system',
      title: title,
      description: message,
      priority: priority,
      actionType: 'system_alert',
      actionData: alertId,
    );

    if (actions != null) {
      for (final action in actions) {
        await badgeService.addBadgeAction(
          badgeId: alertId,
          actionName: action.name,
          actionLabel: action.label,
          iconName: _getIconName(action.icon),
          isPrimary: action.isPrimary,
        );
      }
    }
  }

  /// Show interactive notification dialog with action buttons
  Future<void> showInteractiveNotification({
    required BuildContext context,
    required String badgeId,
    required String title,
    String? description,
    BadgePriority priority = BadgePriority.normal,
    List<NotificationAction>? actions,
    VoidCallback? onResolved,
  }) async {
    final badgeService = NotificationBadgeService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(0),
        content: SingleChildScrollView(
          child: InteractiveNotificationCard(
            badgeId: badgeId,
            title: title,
            description: description,
            priority: priority,
            actions: actions ?? [],
            onCardTap: () {},
            onResolve: () {
              badgeService.resolveBadge(badgeId);
              Navigator.pop(context);
              onResolved?.call();
            },
          ),
        ),
      ),
    );
  }

  /// Show notification snackbar with action
  Future<void> showNotificationSnackbar({
    required BuildContext context,
    required String message,
    BadgePriority priority = BadgePriority.normal,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) async {
    final backgroundColor = _getPriorityColor(priority);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Get all active notifications with actions
  Future<List<Map<String, dynamic>>> getActiveNotifications(
      NotificationBadgeService badgeService) async {
    final badges = await badgeService.getActiveBadges();
    final notificationsWithActions = <Map<String, dynamic>>[];

    for (final badge in badges) {
      final badgeId = badge['badge_id'] as String;
      final actions = await badgeService.getBadgeActions(badgeId);

      notificationsWithActions.add({
        ...badge,
        'actions': actions,
      });
    }

    return notificationsWithActions;
  }

  /// Resolve multiple notifications
  Future<void> resolveBulkNotifications(
    List<String> badgeIds,
    NotificationBadgeService badgeService,
  ) async {
    for (final badgeId in badgeIds) {
      await badgeService.resolveBadge(badgeId);
    }
  }

  /// Get icon name from IconData
  String _getIconName(IconData iconData) {
    return iconData.codePoint.toString();
  }

  /// Get color for priority level
  Color _getPriorityColor(BadgePriority priority) {
    switch (priority) {
      case BadgePriority.critical:
        return Colors.red;
      case BadgePriority.high:
        return Colors.deepOrange;
      case BadgePriority.normal:
        return Colors.orange;
      case BadgePriority.low:
        return Colors.grey;
    }
  }
}
