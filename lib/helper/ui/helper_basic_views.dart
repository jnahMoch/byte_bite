import 'package:flutter/material.dart';

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

/// Simple Bills view placeholder for Helper
class HelperBillsView extends StatelessWidget {
  const HelperBillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.receipt_long, size: 80, color: Color(0xFF009661)),
          SizedBox(height: 16),
          Text('Bills & Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('View and manage bills here', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
