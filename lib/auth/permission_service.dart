import 'package:byte_bite/user_storage.dart';

enum Permission {
  // User management
  manageUsers,
  createHelper,
  deleteHelper,
  editHelper,
  deactivateUser,

  // Inventory management
  viewInventory,
  editInventory,
  deleteInventory,
  restockInventory,

  // Sales & Transactions
  viewSales,
  viewSaleDetails,
  viewTransactions,
  processSale,

  // Expenses & Bills
  viewExpenses,
  createExpense,
  editExpense,
  deleteExpense,
  approveBill,
  payBill,

  // Reports & Analytics
  viewReports,
  viewDetailedAnalytics,
  exportData,

  // Data Management
  importData,
  exportBackup,
  manageBackups,
  viewAuditLog,

  // Settings
  manageSettings,
  viewSettings,
}

enum Role { owner, helper }

class PermissionService {
  static final PermissionService _instance = PermissionService._();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._();

  static const Map<Role, Set<Permission>> _rolePermissions = {
    Role.owner: {
      // User management
      Permission.manageUsers,
      Permission.createHelper,
      Permission.deleteHelper,
      Permission.editHelper,
      Permission.deactivateUser,

      // Inventory
      Permission.viewInventory,
      Permission.editInventory,
      Permission.deleteInventory,
      Permission.restockInventory,

      // Sales
      Permission.viewSales,
      Permission.viewSaleDetails,
      Permission.viewTransactions,

      // Expenses
      Permission.viewExpenses,
      Permission.createExpense,
      Permission.editExpense,
      Permission.deleteExpense,
      Permission.approveBill,
      Permission.payBill,

      // Reports
      Permission.viewReports,
      Permission.viewDetailedAnalytics,
      Permission.exportData,

      // Data Management
      Permission.importData,
      Permission.exportBackup,
      Permission.manageBackups,
      Permission.viewAuditLog,

      // Settings
      Permission.manageSettings,
      Permission.viewSettings,
    },
    Role.helper: {
      // Sales & basic inventory viewing
      Permission.viewInventory,
      Permission.processSale,
      Permission.viewSales,
      Permission.viewSaleDetails,
      Permission.viewTransactions,
      Permission.viewSettings,
    },
  };

  /// Get the current user's role
  Role? getCurrentUserRole() {
    final roleString = UserStorage.currentUserRole?.trim().toLowerCase();
    if (roleString == 'owner') return Role.owner;
    if (roleString == 'helper') return Role.helper;
    return null;
  }

  /// Check if current user has a specific permission
  bool hasPermission(Permission permission) {
    final role = getCurrentUserRole();
    if (role == null) return false;
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Check if current user has any of the given permissions
  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((p) => hasPermission(p));
  }

  /// Check if current user has all of the given permissions
  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((p) => hasPermission(p));
  }

  /// Get all permissions for a specific role
  Set<Permission> getPermissionsForRole(Role role) {
    return _rolePermissions[role] ?? {};
  }

  /// Check if user is Owner
  bool isOwner() => getCurrentUserRole() == Role.owner;

  /// Check if user is Helper
  bool isHelper() => getCurrentUserRole() == Role.helper;

  /// Throw exception if user lacks permission (for controller/logic validation)
  void requirePermission(Permission permission, String action) {
    if (!hasPermission(permission)) {
      throw PermissionDeniedException(
        'Permission denied: User lacks $permission permission to $action',
      );
    }
  }

  /// Throw exception if user is not an Owner
  void requireOwner() {
    if (!isOwner()) {
      throw PermissionDeniedException(
        'This action is only available to the Owner.',
      );
    }
  }

  /// Validate that user is still active in Firebase
  Future<bool> validateUserIsActive() async {
    try {
      final profile = await UserStorage.getCurrentUserProfilePersistent();
      final isActive = profile['isActive'] != 'false';
      return isActive;
    } catch (e) {
      return false;
    }
  }
}

/// Exception thrown when a permission is denied
class PermissionDeniedException implements Exception {
  final String message;

  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}
