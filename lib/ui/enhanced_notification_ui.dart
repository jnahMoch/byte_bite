import 'package:flutter/material.dart';
import 'package:byte_bite/exports.dart';

/// Enhanced POS Header with Interactive Notification Badge
/// Shows clickable notification badge with pending alert count
/// Works in both online and offline modes
/// 
/// Usage in POSHomePage:
/// ```dart
/// child: EnhancedPOSHeader(
///   onNotifications: () => _showNotificationsSheet(),
///   onSettings: () => _showSettingsSheet(),
/// ),
/// ```
class EnhancedPOSHeader extends StatefulWidget {
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final String businessName;
  final String userRole;

  const EnhancedPOSHeader({
    super.key,
    required this.onNotifications,
    required this.onSettings,
    this.businessName = 'Byte & Bite POS',
    this.userRole = 'Owner',
  });

  @override
  State<EnhancedPOSHeader> createState() => _EnhancedPOSHeaderState();
}

class _EnhancedPOSHeaderState extends State<EnhancedPOSHeader> {
  late NotificationBadgeService _badgeService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _badgeService = NotificationBadgeService();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _badgeService.initialize();
      // Listen to badge count changes for updates
      NotificationBadgeService.pendingBadgeCountNotifier.addListener(_onBadgeCountChanged);
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing notification badge service: $e');
    }
  }

  void _onBadgeCountChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleNotificationTap() async {
    // Show notifications when badge is tapped
    widget.onNotifications();
    
    // Mark all notifications as viewed
    final notifications = await _badgeService.getActiveBadges();
    debugPrint('${notifications.length} notifications shown');
  }

  @override
  void dispose() {
    NotificationBadgeService.pendingBadgeCountNotifier.removeListener(_onBadgeCountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF009661),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and Business Info
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/byte_and_bite_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.businessName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.userRole,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          // Actions: Notifications and Settings
          Row(
            children: [
              // Enhanced Notification Button with Badge
              _buildNotificationButton(),
              
              const SizedBox(width: 8),
              
              // Settings Button
              IconButton(
                onPressed: widget.onSettings,
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build notification button with animated badge indicator
  Widget _buildNotificationButton() {
    if (!_isInitialized) {
      return IconButton(
        onPressed: widget.onNotifications,
        icon: const Icon(
          Icons.notifications_outlined,
          color: Colors.white,
        ),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: NotificationBadgeService.pendingBadgeCountNotifier,
      builder: (context, pendingCount, _) {
        return ValueListenableBuilder<Map<String, int>>(
          valueListenable: NotificationBadgeService.badgePriorityNotifier,
          builder: (context, priorities, _) {
            // Determine highest priority
            late BadgePriority highestPriority;
            if (priorities.isEmpty) {
              highestPriority = BadgePriority.low;
            } else {
              final maxPriority = priorities.values.reduce((a, b) => a > b ? a : b);
              highestPriority = _getPriorityFromInt(maxPriority);
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                // Main notification button
                IconButton(
                  onPressed: pendingCount > 0 
                    ? _handleNotificationTap 
                    : widget.onNotifications,
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  tooltip: pendingCount > 0 
                    ? '$pendingCount pending notifications' 
                    : 'Notifications',
                ),

                // Badge indicator
                if (pendingCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: NotificationBadgeIndicator(
                      badgeCount: pendingCount,
                      priority: highestPriority,
                      animated: true,
                      size: 22,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Convert priority int to BadgePriority enum
  BadgePriority _getPriorityFromInt(int value) {
    switch (value) {
      case 3:
        return BadgePriority.critical;
      case 2:
        return BadgePriority.high;
      case 1:
        return BadgePriority.normal;
      default:
        return BadgePriority.low;
    }
  }
}

/// Enhanced Notifications Sheet showing interactive notifications
/// Display all pending alerts with direct action buttons
/// 
/// Usage in POSHomePage:
/// ```dart
/// _showNotificationsSheet() {
///   showModalBottomSheet(
///     context: context,
///     builder: (context) => EnhancedNotificationsSheet(
///       onNotificationResolved: () => setState(() {}),
///     ),
///   );
/// }
/// ```
class EnhancedNotificationsSheet extends StatefulWidget {
  final VoidCallback? onNotificationResolved;
  final ScrollController? scrollController;

  const EnhancedNotificationsSheet({
    super.key,
    this.onNotificationResolved,
    this.scrollController,
  });

  @override
  State<EnhancedNotificationsSheet> createState() =>
      _EnhancedNotificationsSheetState();
}

class _EnhancedNotificationsSheetState extends State<EnhancedNotificationsSheet> {
  late NotificationBadgeService _badgeService;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _badgeService = NotificationBadgeService();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _badgeService.getActiveBadges();
      final withActions = <Map<String, dynamic>>[];

      for (final notif in notifications) {
        final badgeId = notif['badge_id'] as String;
        final actions = await _badgeService.getBadgeActions(badgeId);
        withActions.add({
          ...notif,
          'actions': actions,
        });
      }

      if (mounted) {
        setState(() {
          _notifications = withActions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveBadge(String badgeId) async {
    await _badgeService.resolveBadge(badgeId);
    await _loadNotifications();
    widget.onNotificationResolved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                if (_notifications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_notifications.length}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All clear!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending notifications',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _notifications.map((notif) {
                  final badgeId = notif['badge_id'] as String;
                  final title = notif['title'] as String;
                  final description = notif['description'] as String?;
                  final priority = _getPriorityFromInt(notif['priority'] as int);
                  final actions = (notif['actions'] as List?)
                      ?.cast<Map<String, dynamic>>()
                      .map((action) => NotificationAction(
                            name: action['action_name'] as String,
                            label: action['action_label'] as String,
                            isPrimary: (action['is_primary'] as int) == 1,
                          ))
                      .toList() ?? [];

                  return InteractiveNotificationCard(
                    badgeId: badgeId,
                    title: title,
                    description: description,
                    priority: priority,
                    actions: actions,
                    onCardTap: () => _showNotificationDetail(notif),
                    onResolve: () => _resolveBadge(badgeId),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showNotificationDetail(Map<String, dynamic> notif) {
    // Show detailed view of notification
    debugPrint('Showing details for: ${notif['title']}');
  }

  BadgePriority _getPriorityFromInt(int value) {
    switch (value) {
      case 3:
        return BadgePriority.critical;
      case 2:
        return BadgePriority.high;
      case 1:
        return BadgePriority.normal;
      default:
        return BadgePriority.low;
    }
  }
}
