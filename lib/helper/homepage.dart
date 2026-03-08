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
  }

  void _navigateToPage(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
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
