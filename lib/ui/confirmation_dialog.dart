import 'package:flutter/material.dart';

/// Reusable confirmation dialog for critical actions
/// Provides consistent UX across the app with customizable messages and styling
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? confirmColor;
  final Color? iconColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onCancel,
    this.icon,
    this.confirmColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final finalConfirmColor = confirmColor ?? const Color(0xFF009661);
    final finalIconColor = iconColor ?? Colors.orange;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: finalIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: finalIconColor, size: 24),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (onCancel != null) {
              onCancel!.call();
            } else {
              Navigator.pop(context, false);
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
          child: Text(
            cancelText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: finalConfirmColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    );
  }

  /// Show delete confirmation dialog
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    String? additionalMessage,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete $itemName',
        message:
            'Are you sure you want to permanently delete "$itemName"?${additionalMessage != null ? '\n\n$additionalMessage' : ''}',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        icon: Icons.delete_outline_rounded,
        iconColor: Colors.red,
        confirmColor: Colors.red,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ).then((result) => result ?? false);
  }

  /// Show edit confirmation dialog
  static Future<bool?> showEditConfirmation({
    required BuildContext context,
    required String itemName,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Save Changes',
        message: 'Do you want to save the changes to "$itemName"?',
        confirmText: 'Save',
        cancelText: 'Discard',
        icon: Icons.edit_outlined,
        iconColor: Colors.blue,
        confirmColor: const Color(0xFF3B82F6),
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ).then((result) => result ?? false);
  }

  /// Show restock confirmation dialog
  static Future<bool?> showRestockConfirmation({
    required BuildContext context,
    required String itemName,
    required int quantity,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Confirm Restock',
        message:
            'Add $quantity units to "$itemName"?\n\nThis action will update your inventory.',
        confirmText: 'Restock',
        cancelText: 'Cancel',
        icon: Icons.inventory_2_outlined,
        iconColor: Colors.green,
        confirmColor: const Color(0xFF10B981),
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ).then((result) => result ?? false);
  }

  /// Show mark as paid confirmation dialog
  static Future<bool?> showMarkAsPaidConfirmation({
    required BuildContext context,
    required String billName,
    required double amount,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Mark as Paid',
        message:
            'Mark "$billName" as paid?\n\nAmount: ₱${amount.toStringAsFixed(2)}\n\nThis action cannot be undone.',
        confirmText: 'Mark Paid',
        cancelText: 'Cancel',
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.green,
        confirmColor: const Color(0xFF009661),
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ).then((result) => result ?? false);
  }

  /// Show generic action confirmation dialog
  static Future<bool?> showActionConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? confirmColor,
    Color? iconColor,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        confirmColor: confirmColor,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    ).then((result) => result ?? false);
  }
}
