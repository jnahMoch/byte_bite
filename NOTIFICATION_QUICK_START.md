# Interactive Notifications Quick Start

## 30-Second Setup

### 1. Initialize in main.dart
```dart
void main() async {
  // ... existing code ...
  
  final badgeService = NotificationBadgeService();
  await badgeService.initialize();
  
  runApp(const ByteAndBiteApp());
}
```

### 2. Add Badge to Header
```dart
ValueListenableBuilder<int>(
  valueListenable: NotificationBadgeService.pendingBadgeCountNotifier,
  builder: (context, count, _) {
    return NotificationBadgeIndicator(
      badgeCount: count,
      priority: NotificationBadgeService.BadgePriority.high,
      onTap: () => _showNotifications(),
    );
  },
)
```

### 3. Create Notifications
```dart
final manager = InteractiveNotificationManager();

// Low stock alert
await manager.createLowStockNotification(
  productName: 'Chicken Burger',
  currentStock: 2,
  lowStockThreshold: 5,
  unit: 'pcs',
  context: context,
  onAddStock: () => _showAddStockDialog(),
);

// Bill reminder
await manager.createBillReminderNotification(
  billNumber: 'INV-001',
  amountDue: 5000,
  dueDate: '2026-04-15',
  context: context,
  onMakePayment: () => _processPayment(),
);
```

---

## Key Components

### NotificationBadgeService
Persists and manages notification badges

**Key Methods:**
- `initialize()` - Must call once on app startup
- `addBadge()` - Create new notification
- `addBadgeAction()` - Add action button
- `getActiveBadges()` - Get all pending notifications
- `resolveBadge()` - Mark as handled

### InteractiveNotificationManager
Creates specific notification types with actions

**Key Methods:**
- `createLowStockNotification()` - Stock alerts
- `createBillReminderNotification()` - Payment reminders
- `showInteractiveNotification()` - Show dialog
- `showNotificationSnackbar()` - Show snackbar

### NotificationBadgeIndicator
Visual badge widget with animated pulse

```dart
NotificationBadgeIndicator(
  badgeCount: 5,
  priority: NotificationBadgeService.BadgePriority.critical,
  animated: true,
  onTap: () => showNotifications(),
)
```

### InteractiveNotificationCard
Notification display with action buttons

```dart
InteractiveNotificationCard(
  badgeId: 'lowstock_item1',
  title: 'Low Stock: Chicken',
  description: '2 pcs remaining',
  priority: NotificationBadgeService.BadgePriority.high,
  actions: [
    NotificationAction(
      name: 'add_stock',
      label: 'Add Stock',
      icon: Icons.add_circle,
      isPrimary: true,
      onPressed: () => addStock(),
    ),
  ],
  onCardTap: () => showDetails(),
  onResolve: () => closeNotification(),
)
```

---

## Badge Priorities

```dart
BadgePriority.critical   // 🔴 Red - Urgent (00 stock, overdue)
BadgePriority.high       // 🟠 Orange - Important (low stock, due soon)
BadgePriority.normal     // 🟡 Yellow - Standard (alerts)
BadgePriority.low        // ⚪ Gray - Info (low priority)
```

---

## Complete Example: Low Stock Alert

```dart
import 'package:byte_bite/exports.dart';

class InventoryPage extends StatefulWidget {
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _badgeService = NotificationBadgeService();
  final _manager = InteractiveNotificationManager();

  @override
  void initState() {
    super.initState();
    _checkLowStock();
  }

  Future<void> _checkLowStock() async {
    final items = InventoryData.items;
    
    for (final item in items.where((i) => i.stock <= i.lowStockAlert)) {
      // Create notification badge
      await _manager.createLowStockNotification(
        productName: item.name,
        currentStock: item.stock,
        lowStockThreshold: item.lowStockAlert,
        unit: item.unit,
        context: context,
        onAddStock: () => _showAddStockDialog(item),
        onViewDetails: () => _viewProductDetails(item),
      );
    }
  }

  void _showAddStockDialog(POSItem item) {
    // Implementation...
  }

  void _viewProductDetails(POSItem item) {
    // Implementation...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          // Show badge count
          ValueListenableBuilder<int>(
            valueListenable: NotificationBadgeService.pendingBadgeCountNotifier,
            builder: (context, count, _) {
              return BadgeWidget(badgeCount: count);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Your inventory items...
        ],
      ),
    );
  }
}
```

---

## Offline Support

Notifications work 100% offline:

```dart
// This works offline - saved to local SQLite database
await badgeService.addBadge(...);

// When online, syncs to Firestore automatically
// No additional code needed!
```

---

## Display Notifications in UI

### Option 1: Modal Bottom Sheet
```dart
Future<void> _showNotifications() async {
  final notifications = await _badgeService.getActiveBadges();
  
  showModalBottomSheet(
    context: context,
    builder: (context) => NotificationsPanel(
      notifications: notifications,
    ),
  );
}
```

### Option 2: Dialog
```dart
await _manager.showInteractiveNotification(
  context: context,
  badgeId: 'lowstock_item1',
  title: 'Low Stock Alert',
  description: 'Chicken is running low',
  priority: NotificationBadgeService.BadgePriority.high,
  actions: [
    NotificationAction(
      name: 'add_stock',
      label: 'Add Stock',
      isPrimary: true,
      onPressed: () => addStock(),
    ),
  ],
);
```

### Option 3: Snackbar
```dart
await _manager.showNotificationSnackbar(
  context: context,
  message: 'Chicken is running low on stock',
  actionLabel: 'Add Stock',
  onAction: () => addStock(),
);
```

---

## Handle Actions

Actions are handled directly with callbacks:

```dart
NotificationAction(
  name: 'add_stock',
  label: 'Add Stock',
  icon: Icons.add,
  isPrimary: true,
  onPressed: () async {
    // Show dialog or navigate
    await _showAddStockDialog();
    
    // Resolve badge
    await _badgeService.resolveBadge(badgeId);
  },
)
```

---

## Mark as Resolved

```dart
// Single badge
await _badgeService.resolveBadge('lowstock_item1');

// Multiple badges
await _manager.resolveBulkNotifications([id1, id2, id3], _badgeService);

// Auto-resolve on action
await _badgeService.resolveBadge(badgeId);
```

---

## Check for Critical Alerts

```dart
final hasCritical = await _badgeService.hasCriticalBadges();

if (hasCritical) {
  // Show red banner or alert
}
```

---

## Database Persistence

All notifications stored in SQLite:
- Survives app restart
- Works offline
- Auto-syncs when online
- Cleaned up after 7 days (resolved)

---

## Testing Checklist

- [ ] Badge shows on notification icon
- [ ] Badge animation works
- [ ] Action buttons are clickable
- [ ] Offline - notifications persist
- [ ] Offline - actions execute when online
- [ ] Badge resolves after action
- [ ] Multiple notifications display
- [ ] Priority colors display correctly
- [ ] Snackbar shows action button
- [ ] Dialog shows all action buttons

---

## Common Issues

### Badge not showing
→ Check `pendingBadgeCountNotifier.value` in debug

### Actions not executing
→ Verify `onPressed` callback is properly defined

### Data lost after offline
→ Verify `initialize()` was called early in app startup

### Badge persists after resolve
→ Call `refresh()` or rebuild widget after `resolveBadge()`

---

## Next Steps

1. ✅ Add to header for visibility
2. ✅ Create low stock badges  
3. ✅ Create bill reminders
4. ✅ Add action buttons
5. ✅ Display notifications panel
6. ✅ Test offline persistence
7. ✅ Customize colors/styles
8. Consider: Analytics, History, User preferences
