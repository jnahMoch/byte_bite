import 'package:flutter/material.dart';

class HelperBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const HelperBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isSelected: currentIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          _NavItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            isSelected: currentIndex == 1,
            onTap: () => onItemTapped(1),
          ),
          _CenterNavItem(
            isSelected: currentIndex == 2,
            onTap: () => onItemTapped(2),
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            isSelected: currentIndex == 3,
            onTap: () => onItemTapped(3),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Bills',
            isSelected: currentIndex == 4,
            onTap: () => onItemTapped(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF009661);
    final textColor = isSelected ? greenColor : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? greenColor.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: textColor, size: 22),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterNavItem({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF009661);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: greenColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: greenColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.point_of_sale, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 3),
          const Text(
            'POS',
            style: TextStyle(
              fontSize: 9,
              color: greenColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
