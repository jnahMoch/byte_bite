import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

/// Badge priority levels enum
enum BadgePriority {
  critical(3), // Red badge
  high(2), // Orange badge
  normal(1), // Yellow badge
  low(0); // Gray badge

  final int value;
  const BadgePriority(this.value);
}

/// Service to manage notification badges and visual indicators
/// Persists badge state locally for offline support
class NotificationBadgeService {
  static const String _badgeTable = 'NotificationBadges';
  static const String _actionTable = 'NotificationActions';

  // ValueNotifiers for reactive UI updates
  static final ValueNotifier<int> pendingBadgeCountNotifier =
      ValueNotifier<int>(0);
  static final ValueNotifier<List<String>> activeBadgeIdsNotifier =
      ValueNotifier<List<String>>([]);
  static final ValueNotifier<Map<String, int>> badgePriorityNotifier =
      ValueNotifier<Map<String, int>>({});

  static bool _initialized = false;

  /// Initialize badge tables
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final db = await DatabaseHelper.instance.database;

      // Create badge tracking table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_badgeTable (
          badge_id TEXT PRIMARY KEY,
          notification_id TEXT NOT NULL,
          type TEXT NOT NULL,
          priority INTEGER NOT NULL DEFAULT 1,
          title TEXT NOT NULL,
          description TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          action_type TEXT,
          action_data TEXT
        )
      ''');

      // Create action tracking table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_actionTable (
          action_id TEXT PRIMARY KEY,
          badge_id TEXT NOT NULL,
          action_name TEXT NOT NULL,
          action_label TEXT NOT NULL,
          action_color TEXT,
          icon_name TEXT,
          is_primary INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY(badge_id) REFERENCES $_badgeTable(badge_id)
        )
      ''');

      _initialized = true;
      await _loadBadgesFromDb();
    } catch (e) {
      debugPrint('Error initializing badge service: $e');
    }
  }

  /// Add a new notification badge
  Future<void> addBadge({
    required String badgeId,
    required String notificationId,
    required String type,
    required String title,
    String? description,
    BadgePriority priority = BadgePriority.normal,
    String? actionType,
    String? actionData,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      await db.insert(
        _badgeTable,
        {
          'badge_id': badgeId,
          'notification_id': notificationId,
          'type': type,
          'priority': priority.value,
          'title': title,
          'description': description,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
          'action_type': actionType,
          'action_data': actionData,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _updateBadgeNotifiers();
    } catch (e) {
      debugPrint('Error adding badge: $e');
    }
  }

  /// Add action buttons to a badge
  Future<void> addBadgeAction({
    required String badgeId,
    required String actionName,
    required String actionLabel,
    String? actionColor,
    String? iconName,
    bool isPrimary = false,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final actionId = '${badgeId}_${actionName}_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(
        _actionTable,
        {
          'action_id': actionId,
          'badge_id': badgeId,
          'action_name': actionName,
          'action_label': actionLabel,
          'action_color': actionColor,
          'icon_name': iconName,
          'is_primary': isPrimary ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error adding badge action: $e');
    }
  }

  /// Get all active badges
  Future<List<Map<String, dynamic>>> getActiveBadges() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query(
        _badgeTable,
        where: 'is_active = 1',
        orderBy: 'priority DESC, updated_at DESC',
      );
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      return [];
    }
  }

  /// Get actions for a specific badge
  Future<List<Map<String, dynamic>>> getBadgeActions(String badgeId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query(
        _actionTable,
        where: 'badge_id = ?',
        whereArgs: [badgeId],
        orderBy: 'is_primary DESC',
      );
    } catch (e) {
      debugPrint('Error fetching badge actions: $e');
      return [];
    }
  }

  /// Mark badge as resolved/inactive
  Future<void> resolveBadge(String badgeId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        _badgeTable,
        {
          'is_active': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'badge_id = ?',
        whereArgs: [badgeId],
      );

      await _updateBadgeNotifiers();
    } catch (e) {
      debugPrint('Error resolving badge: $e');
    }
  }

  /// Get badge count by priority
  Future<Map<BadgePriority, int>> getBadgeCountByPriority() async {
    try {
      final badges = await getActiveBadges();
      final counts = <BadgePriority, int>{};

      for (final priority in BadgePriority.values) {
        counts[priority] = badges
            .where((b) => (b['priority'] as int) == priority.value)
            .length;
      }

      return counts;
    } catch (e) {
      debugPrint('Error counting badges: $e');
      return {};
    }
  }

  /// Check if there are critical badges
  Future<bool> hasCriticalBadges() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM $_badgeTable WHERE is_active = 1 AND priority >= ?',
        [BadgePriority.critical.value],
      );
      return (result.first['cnt'] as int) > 0;
    } catch (e) {
      debugPrint('Error checking critical badges: $e');
      return false;
    }
  }

  /// Load badges and update notifiers
  Future<void> _loadBadgesFromDb() async {
    try {
      final badges = await getActiveBadges();
      final badgeIds = badges.map((b) => b['badge_id'] as String).toList();
      final priorityMap = <String, int>{};

      for (final badge in badges) {
        priorityMap[badge['badge_id'] as String] = badge['priority'] as int;
      }

      activeBadgeIdsNotifier.value = badgeIds;
      badgePriorityNotifier.value = priorityMap;
      pendingBadgeCountNotifier.value = badges.length;
    } catch (e) {
      debugPrint('Error loading badges: $e');
    }
  }

  /// Update notifiers after badge changes
  Future<void> _updateBadgeNotifiers() async {
    await _loadBadgesFromDb();
  }

  /// Clear all resolved badges (maintenance)
  Future<void> clearResolvedBadges() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        _badgeTable,
        where: 'is_active = 0 AND updated_at < ?',
        whereArgs: [
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String()
        ],
      );
    } catch (e) {
      debugPrint('Error clearing resolved badges: $e');
    }
  }
}
