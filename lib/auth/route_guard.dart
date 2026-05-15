import 'package:flutter/material.dart';
import 'permission_service.dart';

class RouteGuard {
  static final RouteGuard _instance = RouteGuard._();

  factory RouteGuard() {
    return _instance;
  }

  RouteGuard._();

  /// Check if the current user can access an owner-only page
  /// Throws [PermissionDeniedException] if access is denied
  void requireOwnerAccess({
    required String routeName,
    String? customMessage,
  }) {
    final permService = PermissionService();
    if (!permService.isOwner()) {
      throw PermissionDeniedException(
        customMessage ?? 'Unauthorized access to $routeName. Owner access required.',
      );
    }
  }

  /// Check if the current user can access a helper page (any authenticated user)
  /// Throws [PermissionDeniedException] if not authenticated
  void requireAuthentication({
    required String routeName,
    String? customMessage,
  }) {
    final permService = PermissionService();
    if (permService.getCurrentUserRole() == null) {
      throw PermissionDeniedException(
        customMessage ?? 'Authentication required to access $routeName',
      );
    }
  }

  /// Check if the current user has a specific permission
  /// Throws [PermissionDeniedException] if denied
  void requirePermission({
    required Permission permission,
    required String routeName,
    String? customMessage,
  }) {
    final permService = PermissionService();
    if (!permService.hasPermission(permission)) {
      throw PermissionDeniedException(
        customMessage ?? 'Unauthorized: User does not have permission to access $routeName',
      );
    }
  }

  /// Build a guarded widget that checks owner access before rendering
  /// Shows unauthorized screen if access is denied
  Widget buildOwnerOnlyWidget({
    required String routeName,
    required WidgetBuilder builder,
    WidgetBuilder? unauthorizedBuilder,
  }) {
    try {
      requireOwnerAccess(routeName: routeName);
      return Builder(builder: builder);
    } catch (e) {
      return _buildUnauthorizedScreen(e.toString());
    }
  }

  /// Build a guarded widget with permission check
  Widget buildPermissionGuardedWidget({
    required Permission permission,
    required String routeName,
    required WidgetBuilder builder,
    WidgetBuilder? unauthorizedBuilder,
  }) {
    try {
      requirePermission(
        permission: permission,
        routeName: routeName,
      );
      return Builder(builder: builder);
    } catch (e) {
      return _buildUnauthorizedScreen(e.toString());
    }
  }

  /// Build unauthorized access screen
  static Widget _buildUnauthorizedScreen(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Access Denied',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation guard middleware - use in MaterialApp routes
class ProtectedRoute extends MaterialPageRoute {
  final RouteGuard guard;
  final Permission? requiredPermission;
  final bool requireOwner;

  ProtectedRoute({
    required WidgetBuilder builder,
    required RouteSettings settings,
    this.requiredPermission,
    this.requireOwner = false,
    RouteGuard? guard,
  })  : guard = guard ?? RouteGuard(),
        super(
    builder: (context) {
      try {
        final g = guard ?? RouteGuard();
        if (requireOwner) {
          g.requireOwnerAccess(routeName: settings.name ?? 'unknown');
        } else if (requiredPermission != null) {
          g.requirePermission(
            permission: requiredPermission,
            routeName: settings.name ?? 'unknown',
          );
        } else {
          g.requireAuthentication(routeName: settings.name ?? 'unknown');
        }
        return builder(context);
      } on PermissionDeniedException catch (e) {
        return _UnauthorizedPage(message: e.message);
      }
    },
    settings: settings,
  );
}

/// Page shown when access is denied
class _UnauthorizedPage extends StatelessWidget {
  final String message;

  const _UnauthorizedPage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
