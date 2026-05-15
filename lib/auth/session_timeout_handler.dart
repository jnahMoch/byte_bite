import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../user_storage.dart';
import 'permission_service.dart';

class SessionTimeoutHandler {
  static final SessionTimeoutHandler _instance = SessionTimeoutHandler._();

  factory SessionTimeoutHandler() {
    return _instance;
  }

  SessionTimeoutHandler._();

  Timer? _inactivityTimer;
  Timer? _warningTimer;
  VoidCallback? _onSessionExpired;
  VoidCallback? _onSessionWarning;

  /// Duration of inactivity before warning user (default: 20 minutes)
  static const Duration warningDuration = Duration(minutes: 20);

  /// Duration of total session before forced logout (default: 25 minutes)
  static const Duration sessionTimeout = Duration(minutes: 25);

  /// Start session timeout monitoring
  /// Requires [onSessionExpired] callback to handle logout
  void startSessionTimeout({
    required BuildContext context,
    required VoidCallback onSessionExpired,
    VoidCallback? onSessionWarning,
    Duration customWarningDuration = warningDuration,
    Duration customSessionTimeout = sessionTimeout,
  }) {
    _onSessionExpired = onSessionExpired;
    _onSessionWarning = onSessionWarning;

    // Reset timers whenever user is active
    _resetInactivityTimer(
      context: context,
      warningDuration: customWarningDuration,
      sessionTimeout: customSessionTimeout,
    );
  }

  /// Reset the inactivity timer (call this on user interaction)
  void resetActivity({
    required BuildContext context,
    Duration customWarningDuration = warningDuration,
    Duration customSessionTimeout = sessionTimeout,
  }) {
    _resetInactivityTimer(
      context: context,
      warningDuration: customWarningDuration,
      sessionTimeout: customSessionTimeout,
    );
  }

  /// Internal method to reset timers
  void _resetInactivityTimer({
    required BuildContext context,
    required Duration warningDuration,
    required Duration sessionTimeout,
  }) {
    // Cancel existing timers
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();

    // Set warning timer
    _warningTimer = Timer(warningDuration, () {
      _showSessionWarning(context);
      if (_onSessionWarning != null) {
        _onSessionWarning!();
      }
    });

    // Set expiration timer
    _inactivityTimer = Timer(sessionTimeout, () {
      _expireSession(context);
    });
  }

  /// Show session timeout warning dialog
  void _showSessionWarning(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout Warning'),
        content: const Text(
          'Your session will expire in 5 minutes due to inactivity. '
          'Click "Continue Session" to stay logged in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
                resetActivity(context: context);
              }
            },
            child: const Text('Continue Session'),
          ),
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
                _expireSession(context);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Handle session expiration
  Future<void> _expireSession(BuildContext context) async {
    try {
      // Sign out from Firebase and clear local user data
      await UserStorage.logout();
    } catch (e) {
      debugPrint('Error during session expiration: $e');
    }

    if (_onSessionExpired != null && context.mounted) {
      _onSessionExpired!();
    }
  }

  /// Stop session timeout monitoring
  void stopSessionTimeout() {
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();
    _onSessionExpired = null;
    _onSessionWarning = null;
  }

  /// Check if current session is still valid
  Future<bool> isSessionValid() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Verify user is still active in the system
      final permService = PermissionService();
      return await permService.validateUserIsActive();
    } catch (e) {
      return false;
    }
  }

  /// Force logout (used for security events like password change)
  Future<void> forceLogout(BuildContext context) async {
    stopSessionTimeout();
    
    try {
      await UserStorage.logout();
    } catch (e) {
      debugPrint('Error during force logout: $e');
    }

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
}

/// Mixin to be used in State classes for automatic session monitoring
mixin SessionTimeoutMixin<T extends StatefulWidget> on State<T> {
  late SessionTimeoutHandler _sessionHandler;

  @override
  void initState() {
    super.initState();
    _sessionHandler = SessionTimeoutHandler();
    
    // Start session timeout monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sessionHandler.startSessionTimeout(
          context: context,
          onSessionExpired: _handleSessionExpired,
          onSessionWarning: _handleSessionWarning,
        );
      }
    });
  }

  @override
  void dispose() {
    _sessionHandler.stopSessionTimeout();
    super.dispose();
  }

  /// Call this method on any user interaction to keep session alive
  void onUserActivity() {
    if (mounted) {
      _sessionHandler.resetActivity(context: context);
    }
  }

  /// Override this to handle session expiration
  void _handleSessionExpired() {
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Override this to handle session warning
  void _handleSessionWarning() {
    // Can be overridden in subclasses
  }
}

/// Widget to wrap any scrollable/interactive widget for automatic activity tracking
class ActivityTracker extends StatefulWidget {
  final Widget child;
  final SessionTimeoutHandler? sessionHandler;

  const ActivityTracker({
    required this.child,
    this.sessionHandler,
    super.key,
  });

  @override
  State<ActivityTracker> createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends State<ActivityTracker> {
  late SessionTimeoutHandler _handler;

  @override
  void initState() {
    super.initState();
    _handler = widget.sessionHandler ?? SessionTimeoutHandler();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handler.resetActivity(context: context),
      onPanDown: (_) => _handler.resetActivity(context: context),
      child: widget.child,
    );
  }
}
