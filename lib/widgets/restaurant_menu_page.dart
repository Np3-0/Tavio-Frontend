import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

class RestaurantMenuPage extends StatelessWidget {
  const RestaurantMenuPage({required this.restaurant, super.key});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
          Text('Popular items', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final RestaurantMenuItem item in restaurant.menuItems)
            Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(item.description),
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
