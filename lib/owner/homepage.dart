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
