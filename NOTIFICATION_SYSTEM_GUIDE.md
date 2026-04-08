# Advanced Interactive Notifications System

## Overview
This document describes the enhanced notification system for Byte & Bite POS with interactive action buttons, visual badge indicators, and full offline support.

---

## Features

### 1. **Visual Badge Indicators** 🔴
- **Red dot/badge** showing pending notifications on the notification icon
- **Priority-based coloring**:
  - 🔴 **Critical** (Red): Out of stock, overdue payments
  - 🟠 **High** (Orange): Low stock, due soon
  - 🟡 **Normal** (Yellow): General alerts
  - ⚪ **Low** (Gray): Informational
- **Animated pulse effect** for critical alerts
- **Badge count** displaying total pending notifications

### 2. **Interactive Action Buttons**
Each notification can have multiple direct action buttons:
- **Quick actions** (e.g., "Add Stock", "Pay Now")
- **Primary actions** (highlighted, e.g., "Add Stock")
- **Secondary actions** (e.g., "View Details")
- **Loading states** during action execution

### 3. **Offline Support**
- All notifications and badges persisted locally using SQLite
- Badges sync to Firestore when online
- Actions queue and execute when connection restored
- No data loss in offline mode

### 4. **Notification Types**
- **Low Stock Alerts**: Product inventory warnings
- **Bill Reminders**: Payment due notifications
- **System Alerts**: General app notifications

---

## Implementation Guide

### Step 1: Initialize Badge Service

Initialize the badge service in your main app startup:

```dart
import 'package:byte_bite/exports.dart';

void main() async {
  // ... existing initialization code ...
  
  // Initialize notification badge service
  final badgeService = NotificationBadgeService();
  await badgeService.initialize();
  
  runApp(const ByteAndBiteApp());
}
```

### Step 2: Update UI with Badge Indicators

#### In POSHeader (Navigation Badge)

```dart
import 'package:byte_bite/exports.dart';

class POSHeader extends StatefulWidget {
  @override
  State<POSHeader> createState() => _POSHeaderState();
}

class _POSHeaderState extends State<POSHeader> {
  final NotificationBadgeService _badgeService = NotificationBadgeService();
  
  @override
  void initState() {
    super.initState();
    _badgeService.initialize();
    // Listen to badge count changes
    _badgeService.pendingBadgeCountNotifier.addListener(_refresh);
  }
  
  void _refresh() {
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    _badgeService.pendingBadgeCountNotifier.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_outlined),
            ),
            // Add notification badge indicator
            ValueListenableBuilder<int>(
              valueListenable: _badgeService.pendingBadgeCountNotifier,
              builder: (context, count, _) {
                return NotificationBadgeIndicator(
                  badgeCount: count,
                  priority: NotificationBadgeService.BadgePriority.high,
                  onTap: onNotifications,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
```

### Step 3: Create Low Stock Notifications

When a product stock drops below threshold:

```dart
import 'package:byte_bite/exports.dart';

Future<void> handleLowStockAlert(POSItem item) async {
  final manager = InteractiveNotificationManager();
  
  await manager.createLowStockNotification(
    productName: item.name,
    currentStock: item.stock,
    lowStockThreshold: item.lowStockAlert,
    unit: item.unit,
    context: context,
    onAddStock: () {
      // Navigate to add stock dialog
      _showAddStockDialog(item);
    },
    onViewDetails: () {
      // Navigate to product details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsPage(item: item),
        ),
      );
    },
  );
  
  // Show snackbar notification
  await manager.showNotificationSnackbar(
    context: context,
    message: '${item.name} is running low on stock!',
    priority: item.stock == 0 
      ? NotificationBadgeService.BadgePriority.critical 
      : NotificationBadgeService.BadgePriority.high,
    actionLabel: 'Add Stock',
    onAction: () => _showAddStockDialog(item),
  );
}
```

### Step 4: Create Bill Reminder Notifications

For payment reminders:

```dart
import 'package:byte_bite/exports.dart';

Future<void> handleBillReminder(Bill bill) async {
  final manager = InteractiveNotificationManager();
  
  await manager.createBillReminderNotification(
    billNumber: bill.number,
    amountDue: bill.totalAmount,
    dueDate: bill.dueDate,
    context: context,
    onMakePayment: () {
      _showPaymentDialog(bill);
    },
    onViewBill: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillDetailsPage(bill: bill),
        ),
      );
    },
    onExtendDue: () {
      _showExtendDueDateDialog(bill);
    },
  );
}
```

### Step 5: Display Interactive Notifications Dialog

Show interactive notifications in a bottom sheet or dialog:

```dart
import 'package:byte_bite/exports.dart';

Future<void> showNotificationsDialog() async {
  final badgeService = NotificationBadgeService();
  final manager = InteractiveNotificationManager();
  
  // Get all active notifications
  final notifications = await manager.getActiveNotifications(badgeService);
  
  showModalBottomSheet(
    context: context,
    builder: (context) => NotificationsPanel(
      notifications: notifications,
      onResolve: (badgeId) async {
        await badgeService.resolveBadge(badgeId);
        setState(() {}); // Refresh
      },
    ),
  );
}
```

### Step 6: Create Custom Notifications Panel Widget

```dart
class NotificationsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(String) onResolve;

  const NotificationsPanel({
    required this.notifications,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${notifications.length} Active Notifications',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...notifications.map((notif) {
            final priority = _getPriorityFromValue(notif['priority'] as int);
            final actions = (notif['actions'] as List<dynamic>? ?? [])
                .map((a) => NotificationAction(
                      name: a['action_name'] as String,
                      label: a['action_label'] as String,
                      isPrimary: (a['is_primary'] as int) == 1,
                    ))
                .toList();

            return InteractiveNotificationCard(
              badgeId: notif['badge_id'] as String,
              title: notif['title'] as String,
              description: notif['description'] as String?,
              priority: priority,
              actions: actions,
              onCardTap: () {
                // Navigate to notification details
              },
              onResolve: () => onResolve(notif['badge_id'] as String),
            );
          }).toList(),
        ],
      ),
    );
  }

  NotificationBadgeService.BadgePriority _getPriorityFromValue(int value) {
    switch (value) {
      case 3:
        return NotificationBadgeService.BadgePriority.critical;
      case 2:
        return NotificationBadgeService.BadgePriority.high;
      case 1:
        return NotificationBadgeService.BadgePriority.normal;
      default:
        return NotificationBadgeService.BadgePriority.low;
    }
  }
}
```

---

## API Reference

### NotificationBadgeService

#### Main Methods

```dart
// Initialize service
Future<void> initialize()

// Add a notification badge
Future<void> addBadge({
  required String badgeId,
  required String notificationId,
  required String type,
  required String title,
  String? description,
  BadgePriority priority = BadgePriority.normal,
  String? actionType,
  String? actionData,
})

// Add action button to badge
Future<void> addBadgeAction({
  required String badgeId,
  required String actionName,
  required String actionLabel,
  String? actionColor,
  String? iconName,
  bool isPrimary = false,
})

// Get all active badges
Future<List<Map<String, dynamic>>> getActiveBadges()

// Get actions for a badge
Future<List<Map<String, dynamic>>> getBadgeActions(String badgeId)

// Mark badge as resolved
Future<void> resolveBadge(String badgeId)

// Get badge count by priority
Future<Map<BadgePriority, int>> getBadgeCountByPriority()

// Check for critical badges
Future<bool> hasCriticalBadges()
```

#### Priority Levels

```dart
enum BadgePriority {
  critical(3),  // Red
  high(2),      // Orange
  normal(1),    // Yellow
  low(0),       // Gray
}
```

### InteractiveNotificationManager

```dart
// Create low stock notification
Future<void> createLowStockNotification({
  required String productName,
  required int currentStock,
  required int lowStockThreshold,
  required String unit,
  required BuildContext context,
  VoidCallback? onAddStock,
  VoidCallback? onViewDetails,
})

// Create bill reminder
Future<void> createBillReminderNotification({
  required String billNumber,
  required double amountDue,
  required String dueDate,
  required BuildContext context,
  VoidCallback? onMakePayment,
  VoidCallback? onViewBill,
  VoidCallback? onExtendDue,
})

// Show interactive notification dialog
Future<void> showInteractiveNotification({
  required BuildContext context,
  required String badgeId,
  required String title,
  String? description,
  BadgePriority priority = BadgePriority.normal,
  List<NotificationAction>? actions,
  VoidCallback? onResolved,
})

// Show snackbar notification
Future<void> showNotificationSnackbar({
  required BuildContext context,
  required String message,
  BadgePriority priority = BadgePriority.normal,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
})

// Get active notifications with actions
Future<List<Map<String, dynamic>>> getActiveNotifications(
  NotificationBadgeService badgeService
)

// Resolve multiple notifications
Future<void> resolveBulkNotifications(
  List<String> badgeIds,
  NotificationBadgeService badgeService,
)
```

---

## Usage Examples

### Example 1: Low Stock Alert with Actions

```dart
import 'package:byte_bite/exports.dart';

// When inventory is synced and stock is low
for (final item in InventoryData.items.where((i) => i.stock <= i.lowStockAlert)) {
  final manager = InteractiveNotificationManager();
  
  await manager.createLowStockNotification(
    productName: item.name,
    currentStock: item.stock,
    lowStockThreshold: item.lowStockAlert,
    unit: item.unit,
    context: context,
    onAddStock: () {
      // Show add stock dialog
    },
    onViewDetails: () {
      // Navigate to product details
    },
  );
}
```

### Example 2: Display Badge in Header

```dart
class POSHeader extends StatefulWidget {
  @override
  State<POSHeader> createState() => _POSHeaderState();
}

class _POSHeaderState extends State<POSHeader> {
  late NotificationBadgeService _badgeService;

  @override
  void initState() {
    super.initState();
    _badgeService = NotificationBadgeService();
    _badgeService.pendingBadgeCountNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: _showNotifications,
          icon: const Icon(Icons.notifications_outlined),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _badgeService.pendingBadgeCountNotifier,
          builder: (context, count, _) {
            return NotificationBadgeIndicator(
              badgeCount: count,
              animated: true,
              onTap: _showNotifications,
            );
          },
        ),
      ],
    );
  }
}
```

### Example 3: Offline Persistence

Badges are automatically persisted:

```dart
// All notifications stay in local database even when offline
// When online, they sync to Firestore via the sync mechanism

// Mark as resolved (works offline too)
final badgeService = NotificationBadgeService();
await badgeService.resolveBadge('lowstock_item1');

// Resolved badges are cleared after 7 days (maintenance)
await badgeService.clearResolvedBadges();
```

---

## Database Schema

### NotificationBadges Table
```
badge_id          TEXT PRIMARY KEY
notification_id   TEXT
type             TEXT
priority         INTEGER (0-3)
title            TEXT
description      TEXT
is_active        INTEGER (0/1)
created_at       TEXT (ISO 8601)
updated_at       TEXT (ISO 8601)
action_type      TEXT
action_data      TEXT
```

### NotificationActions Table
```
action_id       TEXT PRIMARY KEY
badge_id        TEXT FOREIGN KEY
action_name     TEXT
action_label    TEXT
action_color    TEXT
icon_name       TEXT
is_primary      INTEGER (0/1)
created_at      TEXT (ISO 8601)
```

---

## Integration Checklist

- [ ] Initialize `NotificationBadgeService` in `main()`
- [ ] Update `POSHeader` to show badge indicator
- [ ] Create handler for low stock alerts
- [ ] Create handler for bill reminders
- [ ] Display notifications panel in UI
- [ ] Test offline persistence
- [ ] Test action button functionality
- [ ] Update settings for notification preferences
- [ ] Add notification history/archive
- [ ] Setup analytics tracking for actions

---

## Best Practices

1. **Always initialize** badge service before showing notifications
2. **Use appropriate priorities** based on alert severity
3. **Provide direct actions** to reduce steps for user resolution
4. **Test offline** before deploying
5. **Clean up old badges** periodically with `clearResolvedBadges()`
6. **Use snackbars** for transient notifications, dialogs for important ones
7. **Listen to notifiers** for reactive UI updates
8. **Handle errors gracefully** - notifications are non-critical

---

## Troubleshooting

### Badges not showing
- Verify `NotificationBadgeService.initialize()` was called
- Check that badge count notifier is being listened to
- Ensure database tables were created

### Actions not working
- Verify `onPressed` callback is set correctly
- Check loading state during async operations
- Ensure context is valid when showing dialogs

### Offline issues
- Verify SQLite database permissions
- Check local storage capacity
- Test sync when back online

---

## Future Enhancements

- [ ] Push notification integration
- [ ] Email notification digest
- [ ] Notification history/archive
- [ ] User notification preferences sync
- [ ] Notification templates
- [ ] Bulk notification management
- [ ] Scheduling notifications
- [ ] Rich notification formatting
- [ ] Notification analytics
