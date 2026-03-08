import 'package:flutter/material.dart';

/// Category filter pills for menu items
class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final List<String> categories;
  final Function(String) onCategoryChanged;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((label) {
          final bool active = selectedCategory == label;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onCategoryChanged(label),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF00A66A) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey[800],
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
