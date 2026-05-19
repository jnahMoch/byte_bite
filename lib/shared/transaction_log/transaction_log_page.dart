import 'package:flutter/material.dart';

import '../../user_storage.dart';
import 'dashboard_transaction_log_section.dart';

class TransactionLogPage extends StatelessWidget {
  static const routeName = '/transaction-log';

  const TransactionLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = UserStorage.currentUserRole ?? 'Helper';
    debugPrint(
      '[TLog Page] Building with role=$role, currentUser=${UserStorage.currentUser}',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction Log',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF18212F),
          ),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DashboardTransactionLogSection(role: role),
        ),
      ),
    );
  }
}
