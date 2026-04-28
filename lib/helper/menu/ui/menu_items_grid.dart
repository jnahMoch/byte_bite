import 'package:flutter/material.dart';

/// Menu items grid display
class MenuItemsGrid extends StatelessWidget {
  final List<Map<String, String>> filteredItems;
  final Function(Map<String, String>) onAddToCart;

  const MenuItemsGrid({
    super.key,
    required this.filteredItems,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        itemCount: filteredItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, idx) => _MenuItemCard(
          item: filteredItems[idx],
          onTap: () => onAddToCart(filteredItems[idx]),
        ),
      ),
    );
  }
}

/// Individual menu item card
class _MenuItemCard extends StatelessWidget {
  final Map<String, String> item;
  final VoidCallback onTap;

  const _MenuItemCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFood = item['category'] == 'Food';
    final iconData = isFood ? Icons.restaurant_rounded : Icons.local_cafe_rounded;
    final iconColor = isFood ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
    final imageUrl = item['image'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image or icon placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl.isNotEmpty
                    ? _buildMenuImage(imageUrl, iconData, iconColor)
                    : Center(
                        child: Icon(iconData, size: 40, color: iconColor.withValues(alpha: 0.6)),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Product details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(item['price'] ?? '', style: const TextStyle(color: Color(0xFF009661), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('Stock: ${item['stock']}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuImage(String imageUrl, IconData iconData, Color iconColor) {
    Widget fallbackIcon() => Center(
      child: Icon(iconData, size: 40, color: iconColor.withValues(alpha: 0.6)),
    );

    if (imageUrl.isEmpty) {
      return fallbackIcon();
    }

    // Check if it's an asset path
    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => fallbackIcon(),
        ),
      );
    }

    // Otherwise, treat as network URL
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => fallbackIcon(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          );
        },
      ),
    );
  }
}
