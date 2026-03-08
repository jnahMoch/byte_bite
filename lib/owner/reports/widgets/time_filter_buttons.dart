import 'package:flutter/material.dart';

class TimeFilterButtons extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const TimeFilterButtons({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['Today', 'This Week', 'This Month', 'All Time'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => onFilterChanged(filter),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}
