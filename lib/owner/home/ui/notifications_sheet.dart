import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../logic/notifications_controller.dart';
import 'notification_detail_view.dart';

class NotificationsSheet extends StatefulWidget {
  final ScrollController scrollController;
  const NotificationsSheet({super.key, required this.scrollController});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final NotificationsController _controller = const NotificationsController();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _loadError;
  String _selectedCategory = 'all';

  // ── Firestore real-time stream ───────────────────────────────────────────
  // Listens to the 'inventory' collection so the sheet auto-refreshes
  // when stock changes from ANY device (owner or helper).
  // The controller already writes TO Firestore on every sync — this closes
  // the loop by reading back from Firestore in real-time.
  StreamSubscription<QuerySnapshot>? _firestoreSub;
  bool _isFirestoreSynced = false;
  // ─────────────────────────────────────────────────────────────────────────

  static const List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'All Notifications'},
    {'key': 'lowstock', 'label': 'Low Stock Alerts'},
    {'key': 'bill', 'label': 'Bill Reminders'},
  ];

  List<Map<String, dynamic>> _filterNotifications(
    List<Map<String, dynamic>> source,
  ) {
    if (_selectedCategory == 'all') return source;
    return source
        .where((n) => (n['type'] ?? '').toString() == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadPersistedAlerts();
    _subscribeToFirestore();
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    super.dispose();
  }

  // ── Firestore stream subscription ────────────────────────────────────────
  // Watches the 'inventory' collection for real-time stock changes.
  // When Firestore fires (any device updated stock), we re-sync the
  // controller and reload so the sheet reflects the latest state.
  // If offline, Firestore serves the cached snapshot automatically.
  void _subscribeToFirestore() {
    _firestoreSub = FirebaseFirestore.instance
        .collection('inventory')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;

      // Let the controller re-evaluate low stock alerts against fresh data
      await _controller.syncLowStockAlertsWithInventory();
      await _loadPersistedAlerts();

      if (mounted) setState(() => _isFirestoreSynced = true);
    }, onError: (_) {
      // Offline or error — keep showing local data silently
      if (mounted) setState(() => _isFirestoreSynced = false);
    });
  }
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadPersistedAlerts() async {
    try {
      final alerts = await _controller.getAllNotificationsSorted();

      if (!mounted) return;
      setState(() {
        _notifications = alerts;
        _loadError = null;
      });

      // Opening the notifications view marks current alerts as read.
      // Keep it non-blocking so UI still renders cards even if this fails.
      _controller.markAllAsRead();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Unable to load notifications right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filterNotifications(_notifications);
    final visibleCount = filteredNotifications.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
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
                  '$visibleCount',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Firebase sync status indicator ─────────────────────────────
          Row(
            children: [
              Icon(
                _isFirestoreSynced
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_sync_outlined,
                size: 14,
                color: _isFirestoreSynced ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                _isFirestoreSynced
                    ? 'Live from Firebase'
                    : 'Syncing with Firebase...',
                style: TextStyle(
                  color: _isFirestoreSynced ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // ────────────────────────────────────────────────────────────────

          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final key = category['key']!;
                final label = category['label']!;
                final isSelected = _selectedCategory == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.grey.shade200,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.grey.shade500
                          : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.grey.shade800
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = key;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null && _notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _loadError!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _loadError = null;
                      });
                      _loadPersistedAlerts();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (filteredNotifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
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
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No notifications for this category',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            )
          else ...[
            ...filteredNotifications.map(
              (alert) => _alertCard(context, alert),
            ),
          ],
        ],
      ),
    );
  }

  Widget _alertCard(BuildContext context, Map<String, dynamic> alert) {
    final type = (alert['type'] ?? 'lowstock').toString();
    final isLowStock = type == 'lowstock';
    final accent = isLowStock ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLowStock ? Colors.orange.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLowStock ? Icons.warning_amber : Icons.receipt_long,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  alert['message'],
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final id = (alert['id'] ?? '').toString();
              if (id.isNotEmpty && isLowStock) {
                await _controller.markAsRead(id);
              }
              final item = alert['item'];
              final currentStock = item is Map<String, dynamic>
                  ? (item['stock'] as num?)?.toInt() ?? 0
                  : (item.stock as int? ?? 0);
              final unit = item is Map<String, dynamic>
                  ? (item['unit'] as String? ?? 'pcs')
                  : (item.unit as String? ?? 'pcs');
              final lowStockThreshold = item is Map<String, dynamic>
                  ? (item['lowStockAlert'] as num?)?.toInt() ?? 0
                  : (item.lowStockAlert as int? ?? 0);
              if (!context.mounted) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationDetailView(
                    productName: alert['name'],
                    alertType: alert['type'],
                    currentStock: currentStock,
                    unit: unit,
                    lowStockThreshold: lowStockThreshold,
                    amountDue:
                        (alert['amountDue'] as num?)?.toDouble() ??
                        (item is Map<String, dynamic>
                            ? (item['amountDue'] as num?)?.toDouble()
                            : null),
                    dueDate:
                        (alert['dueDate'] as String?) ??
                        (item is Map<String, dynamic>
                            ? (item['dueDate'] as String?)
                            : null),
                    paymentStatus:
                        (alert['paymentStatus'] as String?) ??
                        (item is Map<String, dynamic>
                            ? (item['paymentStatus'] as String?)
                            : null),
                  ),
                ),
              );
              if (result != null && mounted) {
                Navigator.pop(context, result);
              }
            },
            child: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}