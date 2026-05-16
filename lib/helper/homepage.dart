import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

// UI Components
import '../data/bills_data.dart';
import 'ui/helper_dashboard_view.dart';
import 'ui/helper_analytics_view.dart';
import 'ui/helper_bottom_nav_bar.dart';
import 'ui/helper_header.dart';
import 'ui/helper_inventory_view.dart';
import 'ui/helper_notifications_view.dart';
import 'ui/helper_pos_grid_view.dart';
import 'ui/helper_settings_sheet.dart';
import 'ui/helper_bills_reminders_view.dart';
import '../data/inventory_data.dart';
import 'logic/inventory_controller.dart';
import '../owner/home/logic/bills_controller.dart';
import '../owner/home/logic/transactions_controller.dart';
import '../data/sales_data.dart';

/// Main Helper Home Page
///
/// Organizes navigation between different helper views:
/// - Dashboard: Overview and quick actions
/// - Analytics: Sales and stock insights
/// - POS: Point of sale system
/// - Inventory: Stock management
/// - Bills: Order history and reminders
/// Notifications and Settings are opened from the top header actions.
class HelperHomePage extends StatefulWidget {
  const HelperHomePage({super.key});

  @override
  State<HelperHomePage> createState() => _HelperHomePageState();
}

class _HelperHomePageState extends State<HelperHomePage> {
  int _currentIndex = 0;
  final InventoryController _inventoryController = const InventoryController();
  final TransactionsController _transactionsController =
      const TransactionsController();
  final BillsController _billsController = const BillsController();
  final GlobalKey<HelperDashboardViewState> _dashboardKey = GlobalKey();
  late final List<Widget> _pages;

  // ── Offline + Cloud Sync ─────────────────────────────────────────────────
  // Same pattern as owner homepage.dart.
  // connectivity_plus v6 returns List<ConnectivityResult>.
  bool _isOnline = true;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  int get _unreadNotificationsCount =>
      InventoryData.items.where((i) => i.stock <= i.lowStockAlert).length;
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _hydrateInventoryFromStorage() async {
    try {
      var loadedItems = await _inventoryController.loadProducts();
      if (loadedItems.isEmpty) {
        loadedItems = await _inventoryController.bootstrapLocalFromSeedIfEmpty(
          InventoryData.items,
        );
      }
      if (loadedItems.isEmpty) return;

      InventoryData.items
        ..clear()
        ..addAll(loadedItems);
      InventoryData.notifier.value = List.from(InventoryData.items);

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // Keep existing in-memory defaults if hydration fails.
    }
  }

  Future<void> _hydrateDashboardDataFromStorage() async {
    try {
      // Step 1: Restore from Firestore into SQLite (best-effort)
      await _transactionsController.restoreTransactionsFromFirebase();
      await _billsController.restoreBillsFromFirebase();

      // Step 2: Load from SQLite into in-memory lists
      final loadedTransactions = await _transactionsController
          .loadPersistedTransactions();
      if (loadedTransactions.isNotEmpty) {
        SalesData.transactions
          ..clear()
          ..addAll(loadedTransactions);
        SalesData.notifier.value++;
      }

      final loadedBills = await _billsController.loadBills();
      if (loadedBills.isNotEmpty) {
        BillsData.bills
          ..clear()
          ..addAll(loadedBills);
        BillsData.notifier.value++;
      }

      // Step 3: Refresh dashboard with new data
      if (mounted) {
        _dashboardKey.currentState?.refresh();
      }
    } catch (_) {
      // Keep current in-memory summary data if hydration fails.
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HelperDashboardView(key: _dashboardKey, onNavigate: _navigateToPage),
      const HelperAnalyticsView(),
      const HelperPOSGridView(),
      const HelperInventoryView(),
      const HelperBillsRemindersView(),
    ];

    _hydrateInventoryFromStorage();
    _hydrateDashboardDataFromStorage();

    // ── Offline + Cloud Sync ───────────────────────────────────────────────
    // Step 1 — check current status on startup.
    Connectivity().checkConnectivity().then((List<ConnectivityResult> results) {
      if (mounted) setState(() => _isOnline = _hasConnection(results));
    });

    // Step 2 — listen for changes throughout the session.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!mounted) return;
      final nowOnline = _hasConnection(results);
      final wasOffline = !_isOnline;
      setState(() => _isOnline = nowOnline);

      // Snackbar only on offline → online transition
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

  void _navigateToPage(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          HelperHeader(
            onNotifications: _showNotificationsSheet,
            onSettings: _showSettingsBottomSheet,
            unreadNotificationsCount: _unreadNotificationsCount,
          ),
          // ── Offline banner ─────────────────────────────────────────────
          // Sits at the very top of the screen above the current page.
          // Each helper page renders its own header below this banner.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isOnline
                ? const SizedBox.shrink()
                : const _OfflineBanner(key: ValueKey('offline')),
          ),
          // ──────────────────────────────────────────────────────────────
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: HelperBottomNavBar(
        currentIndex: _currentIndex,
        onItemTapped: _navigateToPage,
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
            HelperSettingsSheet(scrollController: scrollController),
      ),
    );
  }

  Future<void> _showNotificationsSheet() async {
    final result = await showModalBottomSheet(
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
            HelperNotificationsView(scrollController: scrollController),
      ),
    );

    if (result == 'go_inventory') {
      _navigateToPage(3);
    } else if (result == 'go_bills') {
      _navigateToPage(4);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFLINE BANNER — purely presentational, no logic
// Identical to the one in owner/homepage.dart for consistency.
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
