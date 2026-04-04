import 'package:flutter/material.dart';
import '../../model/pos_item_model.dart';

/// Business logic utilities for Helper views
class HelperBusinessLogic {
  /// Check if a date is today
  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Get greeting message based on current hour
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! Ready to serve?';
    if (hour < 17) return 'Good Afternoon! Keep up the great work!';
    return 'Good Evening! Finishing strong!';
  }

  /// Get category icon based on category name
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'beverage':
        return Icons.local_cafe;
      default:
        return Icons.fastfood;
    }
  }

  /// Get category color based on category name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF6B35);
      case 'beverage':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF009661);
    }
  }

  /// Filter inventory items by category and search query
  static List<POSItem> filterItems(
    List<POSItem> items,
    String selectedCategory,
    String searchQuery,
  ) {
    var filtered = items.toList();
    if (selectedCategory != 'All') {
      filtered = filtered.where((i) => i.category == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (i) => i.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }
    return filtered;
  }

  /// Get list of unique categories from items
  static List<String> getCategories(List<POSItem> items) {
    final cats = items.map((e) => e.category).toSet().toList();
    return ['All', ...cats];
  }

  /// Get status icon based on status name
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'in stock':
        return Icons.check_circle;
      case 'low stock':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  /// Get count of low stock items
  static int getLowStockCount(List<POSItem> items) {
    return items.where((item) => item.stock <= item.lowStockAlert).length;
  }
}
