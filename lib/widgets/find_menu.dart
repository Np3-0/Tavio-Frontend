import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/widgets/restaurant_menu_page.dart';

class FindMenu extends StatelessWidget {
  const FindMenu({required this.userAllergies, super.key});

  final List<String> userAllergies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('Find Restaurants', style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text('Check out what\'s nearby.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          SearchBar(
            hintText: 'Try a place name or type of food',
            leading: const Icon(Icons.search),
            onChanged: (value) {},
          ),
          const SizedBox(height: 20),
          Text('What\'s near you', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: sampleRestaurants.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final restaurant = sampleRestaurants[i];
                return Card(
                  child: ListTile(
                    minVerticalPadding: 14,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDDEAFF),
                      child: Icon(Icons.dining, color: AppColors.Ocean),
                    ),
                    title: Text(restaurant.name, style: theme.textTheme.titleMedium),
                    subtitle: Text(
                      '${restaurant.cuisine} • ${restaurant.distanceMiles.toStringAsFixed(1)} mi',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RestaurantMenuPage(
                          restaurant: restaurant,
                          userAllergies: userAllergies,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
