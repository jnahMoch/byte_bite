# Interactive Notifications - Developer Tips & Tricks

## Quick Reference

### Add a Notification
```dart
final manager = InteractiveNotificationManager();

await manager.createLowStockNotification(
  productName: 'Item Name',
  currentStock: 2,
  lowStockThreshold: 5,
  unit: 'pcs',
  context: context,
  onAddStock: () => handleAction(),
);
```

### Show Badge
```dart
ValueListenableBuilder<int>(
  valueListenable: NotificationBadgeService.pendingBadgeCountNotifier,
  builder: (context, count, _) {
    return NotificationBadgeIndicator(badgeCount: count);
  },
)
```

### Get All Notifications
```dart
final badgeService = NotificationBadgeService();
final badges = await badgeService.getActiveBadges();
```

### Mark as Done
```dart
await badgeService.resolveBadge('badge_id');
```

---

## Common Patterns

### Pattern 1: Auto-create Notifications on Data Change
```dart
class _MyPageState extends State<MyPage> {
  @override
  void initState() {
    super.initState();
    // Listen for data changes
    MyData.notifier.addListener(() {
      _checkAndCreateNotifications();
    });
  }

  Future<void> _checkAndCreateNotifications() async {
    for (final item in MyData.items) {
      if (item.needsNotification) {
        // Create notification
      }
    }
  }

  @override
  void dispose() {
    MyData.notifier.removeListener(() {});
    super.dispose();
  }
}
```

### Pattern 2: Resolve After Action
```dart
NotificationActionButton(
  action: NotificationAction(
    name: 'complete',
    label: 'Complete',
    onPressed: () async {
      // Do action
      await doSomething();
      
      // Resolve badge
      await badgeService.resolveBadge(badgeId);
      
      // Refresh UI
      setState(() {});
    },
  ),
)
```

### Pattern 3: Show Notification + Action
```dart
// Create notification
await manager.createLowStockNotification(...);

// Show snackbar
await manager.showNotificationSnackbar(
  context: context,
  message: 'Stock low!',
  actionLabel: 'Add',
  onAction: () => showDialog(),
);
```

### Pattern 4: Check Before Creating
```dart
final existing = await badgeService.getActiveBadges();
final alreadyExists = existing.any(
  (b) => b['notification_id'] == 'key'
);

if (!alreadyExists) {
  // Create new notification
}
```

---

## Debugging Tips

### Print All Badges
```dart
void _debugPrintBadges() async {
  final badges = await _badgeService.getActiveBadges();
  for (final badge in badges) {
    print('''
Badge: ${badge['title']}
ID: ${badge['badge_id']}
Priority: ${badge['priority']}
Active: ${badge['is_active']}
''');
  }
}
```

### Check Badge Count
```dart
print('Pending: ${NotificationBadgeService.pendingBadgeCountNotifier.value}');
```

### Check for Critical Badges
```dart
final hasCritical = await badgeService.hasCriticalBadges();
print('Critical: $hasCritical');
```

### Print Actions for Badge
```dart
final actions = await badgeService.getBadgeActions('badge_id');
print('Actions: ${actions.length}');
for (final action in actions) {
  print('  - ${action['action_label']}');
}
```

---

## Performance Tips

### 1. Load Notifications Once
```dart
// ❌ Bad: Loading every build
@override
Widget build(BuildContext context) {
  _badges = await badgeService.getActiveBadges(); // Called on every rebuild!
}

// ✅ Good: Load once in initState
@override
void initState() {
  super.initState();
  _loadBadges();
}

Future<void> _loadBadges() async {
  _badges = await badgeService.getActiveBadges();
}
```

### 2. Use ValueNotifiers for Reactive Updates
```dart
// ❌ Bad: Polling for updates
Timer.periodic(Duration(seconds: 1), (_) {
  setState(() {});
});

// ✅ Good: Listen to notifier
_badgeService.pendingBadgeCountNotifier.addListener(_refresh);
_badgeService.badgePriorityNotifier.addListener(_refresh);
```

### 3. Batch Resolve Operations
```dart
// ❌ Bad: Resolving one at a time
for (final badgeId in badgeIds) {
  await badgeService.resolveBadge(badgeId); // Multiple DB calls
}

// ✅ Good: Use bulk method
await manager.resolveBulkNotifications(badgeIds, badgeService);
```

### 4. Cache Badge Service Instance
```dart
// ✅ Good: Store in state, reuse
class _MyPageState extends State<MyPage> {
  late NotificationBadgeService _badgeService;

  @override
  void initState() {
    super.initState();
    _badgeService = NotificationBadgeService(); // Created once
  }
}
```

---

## Testing Scenarios

### Test 1: Low Stock Alert
```dart
// 1. Create notification
await manager.createLowStockNotification(
  productName: 'Test Item',
  currentStock: 0,
  lowStockThreshold: 5,
  unit: 'pcs',
  context: context,
);

// 2. Verify badge appears
expect(
  NotificationBadgeService.pendingBadgeCountNotifier.value,
  1,
);

// 3. Verify action button exists
final badges = await badgeService.getActiveBadges();
final actions = await badgeService.getBadgeActions(badges[0]['badge_id']);
expect(actions.length, greaterThan(0));

// 4. Test resolve
await badgeService.resolveBadge(badges[0]['badge_id']);
expect(
  NotificationBadgeService.pendingBadgeCountNotifier.value,
  0,
);
```

### Test 2: Offline Persistence
```dart
// 1. Create notification
await manager.createLowStockNotification(...);

// 2. Get count
final countBefore = 
  NotificationBadgeService.pendingBadgeCountNotifier.value;

// 3. Disconnect network (airplane mode)
// 4. Restart app
// 5. Verify count is same
final countAfter = 
  NotificationBadgeService.pendingBadgeCountNotifier.value;
expect(countAfter, countBefore);
```

### Test 3: Action Button Click
```dart
// 1. Create card with action
final card = InteractiveNotificationCard(
  /* parameters */
  actions: [
    NotificationAction(
      name: 'test',
      label: 'Test',
      onPressed: () {
        testActionCalled = true;
      },
    ),
  ],
);

// 2. Find action button
final actionButton = find.byType(NotificationActionButton);
await tester.tap(actionButton);
await tester.pumpAndSettle();

// 3. Verify action executed
expect(testActionCalled, true);
```

---

## Customization Guide

### Change Badge Colors
```dart
Color _getCustomColor(BadgePriority priority) {
  switch (priority) {
    case BadgePriority.critical:
      return Colors.deepPurple; // Custom color
    case BadgePriority.high:
      return Colors.indigo;
    default:
      return Colors.blue;
  }
}
```

### Custom Badge Widget
```dart
class CustomBadge extends StatelessWidget {
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
      ),
      child: Text(count.toString()),
    );
  }
}
```

### Custom Action Button Style
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  onPressed: () {},
  child: Text('Custom'),
)
```

---

## Integration Checklist

Production deployment checklist:

- [ ] Initialize `NotificationBadgeService` in `main()`
- [ ] Update header to show badge
- [ ] Implement low stock check in inventory
- [ ] Implement bill reminder check
- [ ] Handle offline scenarios
- [ ] Test badge animations
- [ ] Test action buttons
- [ ] Verify database setup
- [ ] Test with large notification counts
- [ ] Monitor performance
- [ ] Add error handling
- [ ] Test cleanup (7-day resolution cleanup)
- [ ] Document custom implementations
- [ ] Add analytics (optional)

---

## Gotchas & Solutions

### Gotcha 1: Badge Not Updating UI
**Problem**: Changed badge but UI doesn't refresh
**Solution**: 
```dart
// Listen to notifier
_badgeService.pendingBadgeCountNotifier.addListener(_refresh);

// Or rebuild manually
setState(() {});
```

### Gotcha 2: Duplicate Notifications
**Problem**: Same notification created multiple times
**Solution**:
```dart
final existing = await badgeService.getActiveBadges();
if (!existing.any((b) => b['notification_id'] == 'key')) {
  // Create only if doesn't exist
}
```

### Gotcha 3: Actions Not Working
**Problem**: Clicking action button does nothing
**Solution**:
```dart
// Ensure onPressed is defined
NotificationAction(
  name: 'test',
  label: 'Test',
  onPressed: () async {  // ← Must have async function
    await doSomething();
  },
)
```

### Gotcha 4: Memory Leaks
**Problem**: Listeners not removed
**Solution**:
```dart
@override
void dispose() {
  // Remove all listeners
  _badgeService.pendingBadgeCountNotifier.removeListener(_refresh);
  super.dispose();
}
```

### Gotcha 5: Database Not Initialized
**Problem**: Badges not persisting
**Solution**:
```dart
// Call initialize early in main()
void main() async {
  final badgeService = NotificationBadgeService();
  await badgeService.initialize(); // ← Don't forget!
  
  runApp(const MyApp());
}
```

---

## Pro Tips

### Tip 1: Use Extensions for Clean Code
```dart
extension QuickNotifications on BuildContext {
  Future<void> showLowStockAlert(String item, int stock) {
    return InteractiveNotificationManager()
        .createLowStockNotification(
          productName: item,
          currentStock: stock,
          context: this,
        );
  }
}

// Usage
await context.showLowStockAlert('Chicken', 2);
```

### Tip 2: Create Helper Methods
```dart
Future<void> _createAndShowNotification(String title) async {
  await _badgeService.addBadge(
    badgeId: '${DateTime.now().millisecondsSinceEpoch}',
    notificationId: title,
    type: 'alert',
    title: title,
    priority: BadgePriority.high,
  );
  
  await _manager.showNotificationSnackbar(
    context: context,
    message: title,
  );
}
```

### Tip 3: Monitor with Analytics
```dart
// Track notification creation
FirebaseAnalytics.instance.logEvent(
  name: 'notification_created',
  parameters: {
    'type': 'low_stock',
    'priority': 'high',
  },
);

// Track action clicks
FirebaseAnalytics.instance.logEvent(
  name: 'notification_action',
  parameters: {
    'action': 'add_stock',
  },
);
```

### Tip 4: Use Separate Themes
```dart
final criticalTheme = {
  'color': Colors.red,
  'icon': Icons.error,
  'sound': 'critical_alert.mp3',
};
```

---

## Resources

- **Full Guide**: `NOTIFICATION_SYSTEM_GUIDE.md`
- **Quick Start**: `NOTIFICATION_QUICK_START.md`
- **Example Integration**: `INTEGRATION_EXAMPLE_POSHOMEPAGE.md`
- **Code Examples**: `lib/ui/enhanced_notification_ui.dart`

---

## Questions?

Check the documentation files first, then examine:
1. Inline code comments
2. Example implementations
3. Database schema definitions
4. API reference in docstrings
