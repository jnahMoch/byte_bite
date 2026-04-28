import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/inventory_data.dart';

/// Notifications view for Helper showing low stock alerts.
///
/// UI matches the owner's NotificationsDetailView for consistency.
/// Accepts an optional [scrollController] so it works correctly inside
/// a DraggableScrollableSheet in homepage.dart.
///
/// Connects to two data sources:
/// 1. Firestore stream  — real-time stock updates from ANY device
/// 2. InventoryData.notifier — local updates from sales on THIS device
class HelperNotificationsView extends StatefulWidget {
  final ScrollController? scrollController;

  const HelperNotificationsView({super.key, this.scrollController});

  @override
  State<HelperNotificationsView> createState() =>
      _HelperNotificationsViewState();
}

class _HelperNotificationsViewState extends State<HelperNotificationsView> {
  // ── Firestore real-time stream ───────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _firestoreSub;
  bool _isLoadingFirestore = true;
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Source 1 — local inventory changes (sales on this device)
    InventoryData.notifier.addListener(_onInventoryChanged);

    // Source 2 — Firestore real-time stream (stock changes from any device)
    _firestoreSub = FirebaseFirestore.instance
        .collection('inventory')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String?;
        final stock = data['stock'] as int?;
        if (name == null || stock == null) continue;

        final index = InventoryData.items.indexWhere((i) => i.name == name);
        if (index != -1) {
          InventoryData.items[index].stock = stock;
        }
      }

      setState(() => _isLoadingFirestore = false);
    }, onError: (_) {
      if (mounted) setState(() => _isLoadingFirestore = false);
    });
  }

  @override
  void dispose() {
    InventoryData.notifier.removeListener(_onInventoryChanged);
    _firestoreSub?.cancel();
    super.dispose();
  }

  void _onInventoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lowStockItems = InventoryData.items
        .where((i) => i.stock <= i.lowStockAlert)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (lowStockItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        '${lowStockItems.length} alerts',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Firebase sync status indicator ───────────────────────────
              Row(
                children: [
                  Icon(
                    _isLoadingFirestore
                        ? Icons.cloud_sync_outlined
                        : Icons.cloud_done_outlined,
                    size: 14,
                    color: _isLoadingFirestore ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isLoadingFirestore
                        ? 'Syncing with Firebase...'
                        : 'Live from Firebase',
                    style: TextStyle(
                      color:
                          _isLoadingFirestore ? Colors.orange : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // ── Category chip — matches owner's filter row ───────────────
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: true,
                    selectedColor: const Color(0xFF009661),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('Low Stock Alerts'),
                    selected: false,
                    selectedColor: const Color(0xFF009661),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onSelected: (_) {},
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: _isLoadingFirestore
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF009661),
                  ),
                )
              : lowStockItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.green.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'All Good!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No notifications in this category.',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lowStockItems.length,
                      itemBuilder: (context, i) {
                        final item = lowStockItems[i];
                        return _notificationCard(
                          name: item.name,
                          message:
                              'Only ${item.stock} ${item.unit} remaining',
                          onTap: () => _showDetailSheet(
                            context,
                            name: item.name,
                            stock: item.stock,
                            unit: item.unit,
                            lowStockThreshold: item.lowStockAlert,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ── Notification card — matches owner's card style exactly ─────────────
  Widget _notificationCard({
    required String name,
    required String message,
    required VoidCallback onTap,
  }) {
    const accent = Colors.orange;
    final bg = Colors.orange.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Detail bottom sheet — matches owner's NotificationDetailView style ──
  void _showDetailSheet(
    BuildContext context, {
    required String name,
    required int stock,
    required String unit,
    required int lowStockThreshold,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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

              // Alert header card — matches owner style
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Low Stock Alert',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description — matches owner style
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'This product is running low on stock. Consider restocking soon to avoid stockouts.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stock information — matches owner's detail rows
              const Text(
                'Stock Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _detailRow('Product Name', name),
                    const Divider(height: 1),
                    _detailRow('Current Stock', '$stock $unit'),
                    const Divider(height: 1),
                    _detailRow(
                        'Low Stock Threshold', '$lowStockThreshold $unit'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recommendation — matches owner style
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommendation',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Contact the owner to restock this item and maintain inventory levels.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Back button — matches owner style
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009661),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}