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

  bool _containsBlockedAllergen(String itemAllergens, Set<String> blocked) {
    if (blocked.isEmpty) {
      return false;
    }

    final List<String> allergens = itemAllergens
        .split(',')
        .map((String value) => value.trim().toLowerCase())
        .where((String value) => value.isNotEmpty && value != 'none')
        .toList();

    return allergens.any(blocked.contains);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Set<String> blockedAllergies = userAllergies
        .map((String value) => value.trim().toLowerCase())
        .where((String value) => value.isNotEmpty)
        .toSet();
    final List<RestaurantMenuItem> visibleItems = restaurant.menuItems
        .where(
          (RestaurantMenuItem item) =>
              !_containsBlockedAllergen(item.allergens, blockedAllergies),
        )
        .toList();
      final int hiddenItemCount = restaurant.menuItems.length - visibleItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${restaurant.name} Menu',
          style: const TextStyle(color: AppColors.Alabaster),
        ),

        backgroundColor: AppColors.Onyx,
        iconTheme: const IconThemeData(color: AppColors.Alabaster),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Semantics(
            header: true,
            child: Text('Popular items', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          if (hiddenItemCount > 0)
            Text(
              '$hiddenItemCount item(s) hidden because of saved allergies.',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
          if (visibleItems.isEmpty)
            Text(
              'No menu items are available for your saved allergens.',
              style: theme.textTheme.bodyLarge,
            ),
          for (final RestaurantMenuItem item in visibleItems)
            Card(
              child: ListTile(
                minVerticalPadding: 10,
                title: Text(item.name),
                subtitle: Text(
                  '${item.description}\nAllergens: ${item.allergens}',
                ),
                isThreeLine: true,
                trailing: Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
