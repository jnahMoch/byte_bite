# Security Implementation Guide for Byte & Bite POS

This document provides guidelines on how to integrate the new security features into the Byte & Bite application.

## Table of Contents
1. [Permission Service Usage](#permission-service-usage)
2. [Route Guards](#route-guards)
3. [Backup Service](#backup-service)
4. [Session Timeout](#session-timeout)
5. [Firebase Security Rules](#firebase-security-rules)
6. [Best Practices](#best-practices)

---

## Permission Service Usage

### Overview
The `PermissionService` provides role-based access control through a centralized permission system.

### Checking Permissions in Controllers/Logic

```dart
import 'package:byte_bite/auth/permission_service.dart';

class ProductController {
  final PermissionService _permissions = PermissionService();

  Future<void> deleteProduct(int productId) async {
    // Throws PermissionDeniedException if user lacks permission
    _permissions.requirePermission(
      Permission.deleteInventory,
      'delete product',
    );

    // Proceed with deletion only if permission granted
    await _database.deleteProduct(productId);
  }

  Future<void> restockProduct(int productId, int quantity) async {
    // Check if user has specific permission
    if (!_permissions.hasPermission(Permission.restockInventory)) {
      throw PermissionDeniedException('Cannot restock inventory');
    }

    // Proceed with restock
    await _database.updateStock(productId, quantity);
  }
}
```

### Checking Permissions in Widgets

```dart
import 'package:byte_bite/auth/permission_service.dart';

class InventoryPage extends StatelessWidget {
  final PermissionService _permissions = PermissionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          // Only show edit button for users with edit permission
          if (_permissions.hasPermission(Permission.editInventory))
            ElevatedButton(
              onPressed: () => _editProduct(context),
              child: const Text('Edit Product'),
            ),

          // Only show delete button for owners
          if (_permissions.isOwner())
            ElevatedButton(
              onPressed: () => _deleteProduct(),
              child: const Text('Delete Product'),
            ),

          // Show "View Only" badge for helpers
          if (_permissions.isHelper())
            const Chip(label: Text('View Only')),
        ],
      ),
    );
  }
}
```

### Common Permission Patterns

```dart
// Check single permission
_permissions.hasPermission(Permission.editInventory);

// Check multiple permissions (any one)
_permissions.hasAnyPermission([
  Permission.editInventory,
  Permission.createExpense,
]);

// Check multiple permissions (all required)
_permissions.hasAllPermissions([
  Permission.viewReports,
  Permission.exportData,
]);

// Require owner role
_permissions.requireOwner();

// Check roles
_permissions.isOwner();  // true if Owner
_permissions.isHelper(); // true if Helper
```

---

## Route Guards

### Using ProtectedRoute

```dart
// In main.dart
onGenerateRoute: (settings) {
  if (settings.name == '/owner-reports') {
    return ProtectedRoute(
      requireOwner: true,
      settings: settings,
      builder: (context) => const ReportsPage(),
    );
  }
  
  if (settings.name == '/manage-helpers') {
    return ProtectedRoute(
      requiredPermission: Permission.manageUsers,
      settings: settings,
      builder: (context) => const ManageHelpersPage(),
    );
  }
  
  return null;
}
```

### Using RouteGuard in Code

```dart
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      // Ensure only owner can access this page
      RouteGuard().requireOwnerAccess(routeName: '/settings');
      
      return _buildSettingsUI();
    } catch (e) {
      // Show unauthorized screen
      return Scaffold(
        appBar: AppBar(title: const Text('Unauthorized')),
        body: const Center(
          child: Text('You do not have permission to access this page.'),
        ),
      );
    }
  }
}
```

---

## Backup Service

### Creating Backups

```dart
import 'package:byte_bite/auth/backup_service.dart';

// Manual backup creation
final backupService = BackupService();

try {
  final backupPath = await backupService.createBackup();
  print('Backup created at: $backupPath');
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Backup created successfully')),
  );
} on BackupException catch (e) {
  print('Backup failed: ${e.message}');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Backup failed: ${e.message}')),
  );
}
```

### Restoring from Backup

```dart
// Restore from a backup file
try {
  final success = await backupService.restoreBackup(backupPath);
  
  if (success) {
    print('Backup restored successfully');
    // Restart app or refresh data
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
} on BackupException catch (e) {
  print('Restore failed: ${e.message}');
}
```

### Listing Available Backups

```dart
final backups = await backupService.listBackups();

for (final backup in backups) {
  print('${backup.name} - ${backup.sizeInMB} MB - ${backup.created}');
}

// Show backups in UI
ListView.builder(
  itemCount: backups.length,
  itemBuilder: (context, index) {
    final backup = backups[index];
    return ListTile(
      title: Text(backup.name),
      subtitle: Text('${backup.sizeInMB} MB - ${backup.created}'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            child: const Text('Restore'),
            onTap: () => _restoreBackup(backup.path),
          ),
          PopupMenuItem(
            child: const Text('Delete'),
            onTap: () => _deleteBackup(backup.path),
          ),
        ],
      ),
    );
  },
)
```

### Automatic Backups

Automatic backups are triggered in `main.dart`:

```dart
// In main.dart
await BackupService().scheduleAutomaticBackups();

// This creates a daily backup if one hasn't been created today
// Backups are stored in the app's documents directory
```

---

## Session Timeout

### Using SessionTimeoutMixin

```dart
import 'package:byte_bite/auth/session_timeout_handler.dart';

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> with SessionTimeoutMixin {
  
  @override
  void initState() {
    super.initState();
    // SessionTimeoutMixin automatically initializes session monitoring
  }

  @override
  void dispose() {
    // SessionTimeoutMixin automatically cleans up timers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap your main content with ActivityTracker
    return ActivityTracker(
      child: Scaffold(
        appBar: AppBar(title: const Text('POS')),
        body: _buildContent(),
      ),
    );
  }

  void _buildContent() {
    // Your POS content here
  }

  @override
  void _handleSessionExpired() {
    // Called when session expires after 25 minutes of inactivity
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
```

### Manual Session Management

```dart
// Check if session is still valid
final isValid = await SessionTimeoutHandler().isSessionValid();

if (!isValid) {
  // Force logout
  await SessionTimeoutHandler().forceLogout(context);
}

// Reset activity timer on user interaction
SessionTimeoutHandler().resetActivity(context: context);
```

---

## Firebase Security Rules

### Deployment

The `firestore.rules` file contains comprehensive security rules. To deploy:

```bash
# Using Firebase CLI
firebase deploy --only firestore:rules

# Or through Firebase Console:
# 1. Go to Firestore Database
# 2. Click "Rules" tab
# 3. Copy content from firestore.rules
# 4. Paste and Publish
```

### Rule Structure

**Owner Access:**
- Can read/write user documents
- Can create/update/delete products
- Can manage all expenses and bills
- Can view reports and analytics
- Can manage backups

**Helper Access:**
- Can read products
- Can create sales transactions
- Can read transactions
- Can view basic data only

**Public Collections:**
- None (all require authentication)

---

## Best Practices

### 1. Always Check Permissions in Controllers

```dart
// ❌ BAD - No permission check
Future<void> deleteProduct(int id) async {
  await database.deleteProduct(id);
}

// ✅ GOOD - Check permission first
Future<void> deleteProduct(int id) async {
  _permissions.requirePermission(
    Permission.deleteInventory,
    'delete product',
  );
  await database.deleteProduct(id);
}
```

### 2. Use Route Guards for Protected Pages

```dart
// ❌ BAD - No route protection
routes: {
  '/settings': (context) => const SettingsPage(),
}

// ✅ GOOD - Protected route
onGenerateRoute: (settings) {
  if (settings.name == '/settings') {
    return ProtectedRoute(
      requireOwner: true,
      settings: settings,
      builder: (context) => const SettingsPage(),
    );
  }
}
```

### 3. Hide UI Elements Based on Permissions

```dart
// ✅ GOOD - Hide edit button for helpers
if (_permissions.hasPermission(Permission.editInventory))
  ElevatedButton(
    onPressed: _editItem,
    child: const Text('Edit'),
  ),
```

### 4. Validate Backups Before Restoring

```dart
// ✅ GOOD - Backup is validated before restore
final success = await backupService.restoreBackup(path);

// Safety backup is automatically created before restoration
```

### 5. Use Activity Tracker for Session Monitoring

```dart
// ✅ GOOD - Automatically track user activity
@override
Widget build(BuildContext context) {
  return ActivityTracker(
    child: Scaffold(
      body: _buildContent(),
    ),
  );
}
```

### 6. Handle Permission Exceptions Gracefully

```dart
// ✅ GOOD - Catch and handle permission errors
try {
  _permissions.requirePermission(
    Permission.deleteInventory,
    'delete',
  );
  await deleteItem();
} on PermissionDeniedException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

---

## Security Checklist

- [ ] All owner-only pages use route guards
- [ ] All database operations check permissions
- [ ] UI elements are hidden based on role
- [ ] Automatic backups are enabled
- [ ] Firebase security rules are deployed
- [ ] Session timeout is configured
- [ ] All sensitive operations require permission checks
- [ ] Backup and restore processes are tested
- [ ] Firebase rules are tested in Firestore emulator

---

## Troubleshooting

### Session expires too quickly
Adjust `warningDuration` and `sessionTimeout` in `SessionTimeoutHandler`:

```dart
_sessionHandler.startSessionTimeout(
  context: context,
  onSessionExpired: _handleSessionExpired,
  customSessionTimeout: Duration(minutes: 30), // Extend to 30 minutes
);
```

### Backup fails with permission error
Ensure user has `Permission.exportBackup`:

```dart
final perms = PermissionService();
if (!perms.hasPermission(Permission.exportBackup)) {
  print('User cannot create backups');
}
```

### Firebase rules blocking legitimate requests
Check Firestore rules are deployed correctly:

```bash
firebase rules:test
```

---

## Support & Documentation

For more information:
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Flutter Authentication](https://firebase.flutter.dev/docs/auth/overview/)
- [Sqflite Documentation](https://pub.dev/packages/sqflite)
