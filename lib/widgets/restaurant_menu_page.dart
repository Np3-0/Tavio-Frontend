import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

class RestaurantMenuPage extends StatelessWidget {
  const RestaurantMenuPage({
    required this.restaurant,
    required this.userAllergies,
    super.key,
  });

  final Restaurant restaurant;
  final List<String> userAllergies;

  bool _isBlocked(String itemAllergens) {
    if (userAllergies.isEmpty) return false;
    
    final blocked = userAllergies
        .map((a) => a.trim().toLowerCase())
        .toSet();
    
    final allergens = itemAllergens
        .split(',')
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty && a != 'none')
        .toSet();
    
    return allergens.any(blocked.contains);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = restaurant.menuItems.where((item) => !_isBlocked(item.allergens)).toList();
    final hidden = restaurant.menuItems.length - visible.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${restaurant.name} Menu', style: const TextStyle(color: AppColors.Alabaster)),
        backgroundColor: AppColors.Onyx,
        iconTheme: const IconThemeData(color: AppColors.Alabaster),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(header: true, child: Text('Popular items', style: theme.textTheme.titleLarge)),
          const SizedBox(height: 8),
          if (hidden > 0) Text('$hidden item(s) hidden due to your allergies.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Text('Looks like nothing here is safe for your allergies.', style: theme.textTheme.bodyLarge),
          for (final item in visible)
            Card(
              child: ListTile(
                minVerticalPadding: 10,
                title: Text(item.name),
                subtitle: Text('${item.description}\nAllergens: ${item.allergens}'),
                isThreeLine: true,
                trailing: Text('\$${item.price.toStringAsFixed(2)}', style: theme.textTheme.titleMedium),
              ),
            ),
        ],
      ),
    );
  }
}
