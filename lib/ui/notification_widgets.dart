import 'package:flutter/material.dart';
import '../data/notification_badge_service.dart';

/// Animated notification badge indicator widget
/// Shows red dot/badge with count and visual emphasis
class NotificationBadgeIndicator extends StatefulWidget {
  final int badgeCount;
  final VoidCallback? onTap;
  final BadgePriority priority;
  final bool animated;
  final double size;

  const NotificationBadgeIndicator({
    super.key,
    this.badgeCount = 0,
    this.onTap,
    this.priority = BadgePriority.normal,
    this.animated = true,
    this.size = 24,
  });

  @override
  State<NotificationBadgeIndicator> createState() =>
      _NotificationBadgeIndicatorState();
}

class _NotificationBadgeIndicatorState extends State<NotificationBadgeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animated && widget.badgeCount > 0) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat();
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getBadgeColor() {
    switch (widget.priority) {
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

  @override
  Widget build(BuildContext context) {
    if (widget.badgeCount == 0) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    final badgeColor = _getBadgeColor();

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.animated)
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: widget.size + 8,
                height: widget.size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withValues(alpha: 0.2),
                ),
              ),
            ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive notification card with action buttons
class InteractiveNotificationCard extends StatelessWidget {
  final String badgeId;
  final String title;
  final String? description;
  final BadgePriority priority;
  final List<NotificationAction> actions;
  final VoidCallback onCardTap;
  final VoidCallback? onResolve;

  const InteractiveNotificationCard({
    super.key,
    required this.badgeId,
    required this.title,
    this.description,
    this.priority = BadgePriority.normal,
    this.actions = const [],
    required this.onCardTap,
    this.onResolve,
  });

  Color _getPriorityColor() {
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

  IconData _getPriorityIcon() {
    switch (priority) {
      case BadgePriority.critical:
        return Icons.error;
      case BadgePriority.high:
        return Icons.warning;
      case BadgePriority.normal:
        return Icons.info;
      case BadgePriority.low:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: priorityColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: priorityColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with title and icon
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPriorityIcon(),
                      color: priorityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                  if (onResolve != null)
                    IconButton(
                      onPressed: onResolve,
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions
                      .map((action) => NotificationActionButton(
                            action: action,
                            priority: priority,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual action button for notifications
class NotificationActionButton extends StatefulWidget {
  final NotificationAction action;
  final BadgePriority priority;

  const NotificationActionButton({
    super.key,
    required this.action,
    required this.priority,
  });

  @override
  State<NotificationActionButton> createState() =>
      _NotificationActionButtonState();
}

class _NotificationActionButtonState extends State<NotificationActionButton> {
  bool _isLoading = false;

  Future<void> _handleAction() async {
    setState(() => _isLoading = true);
    try {
      await widget.action.onPressed?.call();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getButtonColor() {
    if (widget.action.backgroundColor != null) {
      return widget.action.backgroundColor!;
    }
    if (widget.action.isPrimary) {
      switch (widget.priority) {
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
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getButtonColor();
    final textColor = widget.action.isPrimary ? Colors.white : Colors.black87;

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleAction,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Icon(widget.action.icon, size: 18),
      label: Text(widget.action.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Data class for notification actions
class NotificationAction {
  final String name;
  final String label;
  final IconData icon;
  final Future<void> Function()? onPressed;
  final bool isPrimary;
  final Color? backgroundColor;

  NotificationAction({
    required this.name,
    required this.label,
    this.icon = Icons.check,
    this.onPressed,
    this.isPrimary = false,
    this.backgroundColor,
  });
}

/// Badge indicator for bottom navigation
class NavigationBadgeIndicator extends StatelessWidget {
  final int badgeCount;
  final bool showPulse;

  const NavigationBadgeIndicator({
    super.key,
    this.badgeCount = 0,
    this.showPulse = true,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeCount == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Center(
          child: Text(
            badgeCount > 99 ? '99+' : '$badgeCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
