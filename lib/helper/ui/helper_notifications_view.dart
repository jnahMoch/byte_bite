import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/inventory_data.dart';

/// Notifications view for Helper showing low stock alerts.
///
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
                    ),
                  ),
                  if (lowStockItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${lowStockItems.length} alerts',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Firebase sync status indicator ─────────────────────────
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
              // ────────────────────────────────────────────────────────────
            ],
          ),
        ),
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
                          const Text(
                            'No low stock alerts at the moment',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      // Use scrollController from DraggableScrollableSheet
                      // so the bottom sheet drags correctly
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lowStockItems.length,
                      itemBuilder: (context, i) {
                        final item = lowStockItems[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
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
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.name} - Only ${item.stock} ${item.unit} remaining',
                                      style: const TextStyle(
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Contact owner to restock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}