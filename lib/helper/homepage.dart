import 'package:flutter/material.dart';

// UI Components
import 'ui/helper_dashboard_view.dart';
import 'ui/helper_analytics_view.dart';
import 'ui/helper_pos_grid_view.dart';
import 'ui/helper_basic_views.dart';
import 'ui/helper_inventory_view.dart';
import 'ui/helper_notifications_view.dart';
import 'ui/helper_settings_sheet.dart';
import 'ui/helper_header.dart';
import 'ui/helper_bottom_nav_bar.dart';

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

  @override
  void initState() {
    super.initState();
    _pages = [
      HelperDashboardView(onNavigate: _navigateToPage),
      const HelperAnalyticsView(),
      const HelperPOSGridView(),
      const HelperInventoryView(),
      const HelperBillsView(),
    ];
  }

  void _navigateToPage(int index) {
    setState(() => _currentIndex = index);
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) => HelperNotificationsView(),
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (ctx) => HelperSettingsSheet(
        scrollController: ScrollController(),
      ),
    );
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
            unreadNotificationsCount: 0,
          ),
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: HelperBottomNavBar(
        currentIndex: _currentIndex,
        onItemTapped: _navigateToPage,
      ),
    );
  }
}
