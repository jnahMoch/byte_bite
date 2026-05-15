# Security Quick Start Guide

This guide shows the minimal steps to integrate security features into your existing pages.

## 1. Add Permission Checks to Controllers/Logic

### Before (No Security)
```dart
class InventoryController {
  Future<void> deleteProduct(int id) async {
    await database.deleteProduct(id);
  }
}
```

### After (With Security)
```dart
import 'package:byte_bite/auth/permission_service.dart';

class InventoryController {
  final PermissionService _permissions = PermissionService();

  Future<void> deleteProduct(int id) async {
    // Throws exception if user lacks permission
    _permissions.requirePermission(
      Permission.deleteInventory,
      'delete product',
    );
    await database.deleteProduct(id);
  }
}
```

---

## 2. Hide UI Elements Based on Permissions

### Before (Everyone sees all buttons)
```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      ElevatedButton(onPressed: _edit, child: Text('Edit')),
      ElevatedButton(onPressed: _delete, child: Text('Delete')),
    ],
  );
}
```

### After (Show only allowed actions)
```dart
import 'package:byte_bite/auth/permission_service.dart';

class MyPage extends StatelessWidget {
  final PermissionService _permissions = PermissionService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show edit button only if user has permission
        if (_permissions.hasPermission(Permission.editInventory))
          ElevatedButton(onPressed: _edit, child: Text('Edit')),
        
        // Show delete button only for owner
        if (_permissions.isOwner())
          ElevatedButton(onPressed: _delete, child: Text('Delete')),
      ],
    );
  }
}
```

---

## 3. Add Session Timeout to Your Dashboards

### Before (No session management)
```dart
class POSHomePage extends StatefulWidget {
  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  // No session handling
}
```

### After (With session timeout)
```dart
import 'package:byte_bite/auth/session_timeout_handler.dart';

class POSHomePage extends StatefulWidget {
  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> 
    with SessionTimeoutMixin {
  // Session timeout automatically managed!
  // User logs out after 25 min of inactivity
  // Warning shown at 20 min
  
  @override
  void _handleSessionExpired() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }
}
```

---

## 4. Protect Routes with Guards

### Before (Any URL can access any page)
```dart
MaterialApp(
  routes: {
    '/settings': (context) => SettingsPage(),
  },
)
```

### After (Only owner can access settings)
```dart
import 'package:byte_bite/auth/route_guard.dart';

MaterialApp(
  onGenerateRoute: (settings) {
    if (settings.name == '/settings') {
      return ProtectedRoute(
        requireOwner: true,
        settings: settings,
        builder: (context) => SettingsPage(),
      );
    }
    return null;
  },
)
```

---

## 5. Wrap Interactive Pages with Activity Tracker

### Before (No activity tracking)
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: MyContent(),
  );
}
```

### After (Activity resets session timer)
```dart
import 'package:byte_bite/auth/session_timeout_handler.dart';

@override
Widget build(BuildContext context) {
  return ActivityTracker(
    child: Scaffold(
      body: MyContent(),
    ),
  );
}
```

---

## 6. Handle Permission Exceptions Gracefully

### Before (Crashes on permission error)
```dart
void _deleteItem() {
  _permissions.requirePermission(
    Permission.deleteInventory,
    'delete',
  );
  // If exception thrown, widget crashes!
}
```

### After (Gracefully handle errors)
```dart
void _deleteItem() {
  try {
    _permissions.requirePermission(
      Permission.deleteInventory,
      'delete',
    );
    // Delete logic here
  } on PermissionDeniedException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## Implementation Checklist

For each existing page, follow this checklist:

### Owner-Only Pages (Settings, Reports, etc.)
- [ ] Add route guard: `ProtectedRoute(requireOwner: true, ...)`
- [ ] Add SessionTimeoutMixin to state class
- [ ] Wrap content with ActivityTracker
- [ ] Add permission checks to controllers

### Shared Pages (Inventory, Sales, etc.)
- [ ] Add permission checks in all controllers
- [ ] Hide edit/delete buttons based on permission
- [ ] Show help text for helpers: "View only - contact owner to edit"
- [ ] Add try-catch blocks around actions
- [ ] Add SessionTimeoutMixin if interactive

### Database Operations
- [ ] Check permission before insert/update/delete
- [ ] Throw PermissionDeniedException if denied
- [ ] Log who performed what action (for audit)

---

## Testing Your Changes

### Quick Test: Check Permissions Work
```dart
test('Helper cannot delete inventory', () {
  final perms = PermissionService();
  expect(() {
    perms.requirePermission(
      Permission.deleteInventory,
      'delete',
    );
  }, throwsA(isA<PermissionDeniedException>()));
});
```

### Quick Test: Route Guards Work
```dart
testWidgets('Settings page redirects unauthorized users', (tester) async {
  // Try to navigate to settings
  Navigator.pushNamed(context, '/settings');
  
  // Should show unauthorized page, not SettingsPage
  expect(find.text('Access Denied'), findsOneWidget);
});
```

---

## Common Patterns

### Pattern 1: Owner-Only Button
```dart
if (_permissions.isOwner())
  ElevatedButton(onPressed: _doSomething, child: Text('Owner Only')),
```

### Pattern 2: View-Only Message for Helpers
```dart
if (_permissions.isHelper())
  Container(
    padding: EdgeInsets.all(16),
    color: Colors.blue[100],
    child: Text('You have view-only access'),
  ),
```

### Pattern 3: Conditional Action in Menu
```dart
PopupMenuButton(
  itemBuilder: (context) {
    final items = [
      PopupMenuItem(value: 'view', child: Text('View')),
    ];
    
    if (_permissions.hasPermission(Permission.editInventory)) {
      items.add(PopupMenuItem(value: 'edit', child: Text('Edit')));
    }
    
    return items;
  },
)
```

### Pattern 4: Protected Async Operation
```dart
Future<void> _saveChanges() async {
  try {
    _permissions.requirePermission(
      Permission.editInventory,
      'save changes',
    );
    
    final result = await _controller.save();
    _showSuccess('Changes saved');
  } on PermissionDeniedException catch (e) {
    _showError(e.message);
  } catch (e) {
    _showError('Failed to save');
  }
}
```

---

## Debugging Tips

### Issue: Permission always denied
**Solution:** Check user role is set correctly
```dart
final role = UserStorage.currentUserRole;
print('Current role: $role'); // Should be 'Owner' or 'Helper'
```

### Issue: Session doesn't timeout
**Solution:** Make sure SessionTimeoutMixin is used and ActivityTracker wraps content
```dart
// Verify mixin is added
class MyPage extends State with SessionTimeoutMixin { }

// Verify ActivityTracker wraps interactive content
ActivityTracker(child: Scaffold(...))
```

### Issue: Backup fails with permission
**Solution:** Check user is Owner
```dart
_permissions.requireOwner();
final path = await backupService.createBackup();
```

---

## Next Steps

1. **For Existing Pages:**
   - Start with high-priority pages (Settings, Manage Helpers, Reports)
   - Use SECURITY_EXAMPLE_INVENTORY_PAGE.dart as reference
   - Test with both Owner and Helper accounts

2. **For New Features:**
   - Always include permission checks in controllers
   - Hide UI elements based on permissions
   - Use route guards for owner-only pages

3. **For Testing:**
   - Test with Helper account (should see limited options)
   - Test with Owner account (should see all options)
   - Test session timeout (leave idle for 25+ minutes)
   - Test backup creation and restore

---

## Need More Details?

- Full guide: See [SECURITY_IMPLEMENTATION_GUIDE.md](SECURITY_IMPLEMENTATION_GUIDE.md)
- Code example: See [SECURITY_EXAMPLE_INVENTORY_PAGE.dart](lib/SECURITY_EXAMPLE_INVENTORY_PAGE.dart)
- Summary: See [SECURITY_SUMMARY.md](SECURITY_SUMMARY.md)
