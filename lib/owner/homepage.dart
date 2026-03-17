import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'home/ui/analytics_view.dart';
import 'home/ui/bills_reminders_view.dart';
import 'home/ui/dashboard_view.dart';
import 'home/ui/inventory_menu_view.dart';
import 'home/ui/pos_grid_view.dart';
import 'home/ui/notifications_sheet.dart';
import 'home/ui/settings_sheet.dart';
import 'home/ui/pos_header.dart';
import 'home/ui/pos_bottom_nav_bar.dart';

// Re-export UI components and data for backward compatibility
export '../data/inventory_data.dart';
export '../data/sales_data.dart';
export '../data/bills_data.dart';
export '../model/pos_item_model.dart';
export '../model/sales_transaction_model.dart';
export '../model/bill_model.dart';
export 'home/ui/analytics_view.dart';
export 'home/ui/bills_reminders_view.dart';
export 'home/ui/bills_view.dart';
export 'home/ui/dashboard_view.dart';
export 'home/ui/data_management_view.dart';
export 'home/ui/inventory_menu_view.dart';
export 'home/ui/inventory_view.dart';
export 'home/ui/menu_view.dart';
export 'home/ui/pos_grid_view.dart';
export 'home/ui/reports_view.dart';
export 'home/ui/notifications_sheet.dart';
export 'home/ui/settings_sheet.dart';

class POSHomePage extends StatefulWidget {
  const POSHomePage({super.key});

  @override
  State<POSHomePage> createState() => _POSHomePageState();
}

class _POSHomePageState extends State<POSHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  // ── Offline + Cloud Sync ─────────────────────────────────────────────────
  // connectivity_plus v6 changed the API:
  //   OLD (v4/v5): Stream<ConnectivityResult>        — single value
  //   NEW (v6):    Stream<List<ConnectivityResult>>  — list of values
  //
  // _hasConnection() handles this by checking whether ANY item in the list
  // is not ConnectivityResult.none, making it safe for all v6 versions.
  bool _isOnline = true;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardView(onNavigate: _onPageNavigate),
      const AnalyticsView(),
      const POSGridView(),
      const InventoryMenuView(),
      const BillsRemindersView(),
    ];

    // ── Offline + Cloud Sync ───────────────────────────────────────────────
    // Step 1 — snapshot current status on startup.
    // checkConnectivity() in v6 returns List<ConnectivityResult>.
    Connectivity()
        .checkConnectivity()
        .then((List<ConnectivityResult> results) {
      if (mounted) setState(() => _isOnline = _hasConnection(results));
    });

    // Step 2 — stream changes for the rest of the session.
    // Firestore manages the actual data sync automatically;
    // this only drives the UI banner.
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (!mounted) return;
      final nowOnline = _hasConnection(results);
      final wasOffline = !_isOnline;
      setState(() => _isOnline = nowOnline);

      // Snackbar only on offline → online transition (not every event)
      if (nowOnline && wasOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Back online — syncing data to Firebase…'),
              ],
            ),
            backgroundColor: Color(0xFF009661),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    // ──────────────────────────────────────────────────────────────────────
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  void _onPageNavigate(int pageIndex) {
    setState(() => _currentIndex = pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          POSHeader(
            onNotifications: _showNotificationsSheet,
            onSettings: _showSettingsBottomSheet,
          ),

          // ── Offline banner ───────────────────────────────────────────────
          // Visible only when _isOnline == false.
          // Firestore continues serving cached reads and queuing writes
          // while this banner is showing — nothing is lost.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isOnline
                ? const SizedBox.shrink()
                : const _OfflineBanner(key: ValueKey('offline')),
          ),
          // ────────────────────────────────────────────────────────────────

          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: POSBottomNavBar(
        currentIndex: _currentIndex,
        onItemTapped: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            SettingsSheet(scrollController: scrollController),
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) =>
            NotificationsSheet(scrollController: scrollController),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFLINE BANNER — purely presentational, contains no logic
// ─────────────────────────────────────────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF59E0B),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline — data saved locally, will sync when reconnected.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}