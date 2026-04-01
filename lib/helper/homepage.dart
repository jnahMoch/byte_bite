import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

// UI Components
import 'ui/helper_dashboard_view.dart';
import 'ui/helper_basic_views.dart';
import 'ui/helper_inventory_view.dart';
import 'ui/helper_notifications_view.dart';
import 'ui/helper_settings_sheet.dart';

/// Main Helper Home Page
///
/// Organizes navigation between different helper views:
/// - Dashboard: Overview and quick actions
/// - POS: Point of sale system
/// - Bills: Order history
/// - Inventory: Stock management
/// - Notifications: Alerts
/// - Settings: Account management
class HelperHomePage extends StatefulWidget {
  const HelperHomePage({super.key});

  @override
  State<HelperHomePage> createState() => _HelperHomePageState();
}

class _HelperHomePageState extends State<HelperHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  // ── Offline + Cloud Sync ─────────────────────────────────────────────────
  // Same pattern as owner homepage.dart.
  // connectivity_plus v6 returns List<ConnectivityResult>.
  bool _isOnline = true;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pages = [
      HelperDashboardView(onNavigate: _navigateToPage),
      const HelperPOSView(),
      const HelperBillsView(),
      const HelperInventoryView(),
      HelperNotificationsView(),
      HelperSettingsSheet(scrollController: ScrollController()),
    ];

    // ── Offline + Cloud Sync ───────────────────────────────────────────────
    // Step 1 — check current status on startup.
    Connectivity()
        .checkConnectivity()
        .then((List<ConnectivityResult> results) {
      if (mounted) setState(() => _isOnline = _hasConnection(results));
    });

    // Step 2 — listen for changes throughout the session.
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
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
      body: Column(
        children: [
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _navigateToPage,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF009661),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'POS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Bills',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
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