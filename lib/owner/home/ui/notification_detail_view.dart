import 'package:flutter/material.dart';

import '../logic/notifications_controller.dart';

class NotificationsDetailView extends StatefulWidget {
  const NotificationsDetailView({super.key});

  @override
  State<NotificationsDetailView> createState() =>
      _NotificationsDetailViewState();
}

class _NotificationsDetailViewState extends State<NotificationsDetailView> {
  final NotificationsController _controller = const NotificationsController();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final results = await _controller.getNotificationsByCategory(
      _selectedCategory,
    );
    if (!mounted) return;
    setState(() {
      _notifications = results;
      _isLoading = false;
    });
  }

  Future<void> _onCategorySelected(String category) async {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    await _loadNotifications();
  }

  Widget _categoryButton({required String label, required String value}) {
    final selected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _onCategorySelected(value),
      selectedColor: const Color(0xFF009661),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF4B5563),
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _notificationCard(Map<String, dynamic> notification) {
    final type = (notification['type'] ?? 'lowstock').toString();
    final isLowStock = type == 'lowstock';
    final accent = isLowStock ? Colors.orange : Colors.blue;
    final bg = isLowStock ? Colors.orange.shade50 : Colors.blue.shade50;
    final icon = isLowStock ? Icons.warning_amber : Icons.receipt_long;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (notification['name'] ?? '').toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (notification['message'] ?? '').toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final id = (notification['id'] ?? '').toString();
              if (id.isNotEmpty && type == 'lowstock') {
                await _controller.markAsRead(id);
              }

              final item = notification['item'];
              final currentStock = item is Map<String, dynamic>
                  ? (item['stock'] as num?)?.toInt() ?? 0
                  : (item.stock as int? ?? 0);
              final unit = item is Map<String, dynamic>
                  ? (item['unit'] as String? ?? 'pcs')
                  : (item.unit as String? ?? 'pcs');
              final lowStockThreshold = item is Map<String, dynamic>
                  ? (item['lowStockAlert'] as num?)?.toInt() ?? 0
                  : (item.lowStockAlert as int? ?? 0);

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationDetailView(
                    productName: (notification['name'] ?? '').toString(),
                    alertType: type,
                    currentStock: currentStock,
                    unit: unit,
                    lowStockThreshold: lowStockThreshold,
                    amountDue:
                        (notification['amountDue'] as num?)?.toDouble() ??
                        (item is Map<String, dynamic>
                            ? (item['amountDue'] as num?)?.toDouble()
                            : null),
                    dueDate:
                        (notification['dueDate'] as String?) ??
                        (item is Map<String, dynamic>
                            ? (item['dueDate'] as String?)
                            : null),
                    paymentStatus:
                        (notification['paymentStatus'] as String?) ??
                        (item is Map<String, dynamic>
                            ? (item['paymentStatus'] as String?)
                            : null),
                    reminderTitle: (notification['name'] ?? '').toString(),
                    scheduledDateTime: item is Map<String, dynamic>
                        ? (item['scheduledDateTime'] as String?)
                        : null,
                    notes: item is Map<String, dynamic>
                        ? (item['notes'] as String?)
                        : null,
                  ),
                ),
              );
            },
            child: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _categoryButton(label: 'All', value: 'all'),
                _categoryButton(label: 'Low Stock Alerts', value: 'lowstock'),
                _categoryButton(label: 'Bills & Reminders', value: 'bills'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications in this category.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) =>
                          _notificationCard(_notifications[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetailView extends StatelessWidget {
  final String productName;
  final String alertType;
  final int currentStock;
  final String unit;
  final int lowStockThreshold;
  final double? amountDue;
  final String? dueDate;
  final String? paymentStatus;
  final String? reminderTitle;
  final String? scheduledDateTime;
  final String? notes;

  const NotificationDetailView({
    super.key,
    required this.productName,
    required this.alertType,
    required this.currentStock,
    required this.unit,
    required this.lowStockThreshold,
    this.amountDue,
    this.dueDate,
    this.paymentStatus,
    this.reminderTitle,
    this.scheduledDateTime,
    this.notes,
  });

  bool get _isLowStock => alertType == 'lowstock';
  bool get _isBill => alertType == 'bill';
  bool get _isReminder => alertType == 'reminder';

  String _displayDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Not specified';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Widget _detailValueCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockSection() {
    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              row('Product Name', productName),
              const Divider(height: 1),
              row('Current Stock', '$currentStock $unit'),
              const Divider(height: 1),
              row('Low Stock Threshold', '$lowStockThreshold $unit'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillSection() {
    final dueAmountText = amountDue == null
        ? 'Not specified'
        : 'Php ${amountDue!.toStringAsFixed(2)}';

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bill Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              row('Bill Name', productName),
              const Divider(height: 1),
              row('Amount Due', dueAmountText),
              const Divider(height: 1),
              row('Due Date', _displayDate(dueDate)),
              const Divider(height: 1),
              row('Payment Status', paymentStatus ?? 'Pending'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        _detailValueCard(
          label: 'Reminder Title',
          value: reminderTitle ?? productName,
          color: const Color(0xFF1E40AF),
        ),
        const SizedBox(height: 10),
        _detailValueCard(
          label: 'Scheduled Date/Time',
          value: _displayDate(scheduledDateTime),
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 10),
        _detailValueCard(
          label: 'Notes',
          value: (notes == null || notes!.trim().isEmpty)
              ? 'No notes provided'
              : notes!,
          color: const Color(0xFF0F766E),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    if (_isLowStock) return _buildLowStockSection();
    if (_isBill) return _buildBillSection();
    if (_isReminder) return _buildReminderSection();
    return _buildBillSection();
  }

  String _getAlertTypeDisplay() {
    switch (alertType) {
      case 'lowstock':
        return 'Low Stock Alert';
      case 'bill':
        return 'Bills & Reminder';
      default:
        return 'Alert';
    }
  }

  Color _getAlertColor() {
    switch (alertType) {
      case 'lowstock':
        return Colors.orange;
      case 'bill':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon() {
    switch (alertType) {
      case 'lowstock':
        return Icons.warning_amber;
      case 'bill':
        return Icons.receipt_long;
      default:
        return Icons.info;
    }
  }

  String _getAlertDescription() {
    switch (alertType) {
      case 'lowstock':
        return 'This product is running low on stock. Consider restocking soon to avoid stockouts.';
      case 'bill':
        return 'You have an active bill reminder. Review and settle it before the due date to avoid penalties.';
      default:
        return 'Alert details';
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = _getAlertColor();

    // Determine dynamic label and navigation intent based on alert type
    final String actionLabel;
    VoidCallback actionCallback;
    if (_isLowStock) {
      actionLabel = 'Go to Inventory';
      actionCallback = () => Navigator.pop(context, 'go_inventory');
    } else if (_isBill || _isReminder) {
      actionLabel = 'Go to Bills';
      actionCallback = () => Navigator.pop(context, 'go_bills');
    } else {
      actionLabel = 'Back to Notifications';
      actionCallback = () => Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: alertColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alertColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getAlertIcon(), color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAlertTypeDisplay(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: alertColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _getAlertDescription(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category-specific details (Stock/Bill/Reminder)
            _buildDetailsSection(),
            const SizedBox(height: 24),

            // Recommendation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommendation',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLowStock
                              ? 'Restock this item soon to maintain inventory levels and avoid stockouts.'
                              : (_isBill
                                    ? 'Settle this bill before the due date and keep your reminders updated.'
                                    : 'Review this reminder and schedule follow-up actions if needed.'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button (dynamic label + routing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: actionCallback,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009661),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
