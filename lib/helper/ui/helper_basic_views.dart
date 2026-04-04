import 'package:flutter/material.dart';
import 'helper_bills_reminders_view.dart';

/// Simple POS view placeholder for Helper
class HelperPOSView extends StatelessWidget {
  const HelperPOSView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shopping_cart, size: 80, color: Color(0xFF009661)),
          SizedBox(height: 16),
          Text('POS System', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Helper can process orders here', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// Bills view for Helper - Use HelperBillsRemindersView
class HelperBillsView extends StatelessWidget {
  const HelperBillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelperBillsRemindersView();
  }
}
