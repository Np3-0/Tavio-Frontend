import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/widgets/restaurant_menu_page.dart';

class FindMenu extends StatelessWidget {
  const FindMenu({required this.userAllergies, super.key});

  final List<String> userAllergies;

  void _openRestaurantMenu(BuildContext context, Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestaurantMenuPage(
          restaurant: restaurant,
          userAllergies: userAllergies,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text('Find Restaurants', style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse nearby menus and open restaurant details.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Semantics(
            textField: true,
            label: 'Search restaurants',
            hint: 'Type a restaurant name or cuisine',
            child: SearchBar(
              hintText: 'Search restaurants or cuisines',
              leading: const Icon(Icons.search),
              onChanged: (value) {},
            ),
          ),
          const SizedBox(height: 20),
          Text('Restaurants near you', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: sampleRestaurants.length,
              separatorBuilder: (_, int index) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Restaurant restaurant = sampleRestaurants[index];

                return Semantics(
                  button: true,
                  label:
                      '${restaurant.name}, ${restaurant.cuisine}, ${restaurant.distanceMiles.toStringAsFixed(1)} miles away. Double tap to open menu.',
                  child: Card(
                    child: ListTile(
                      minVerticalPadding: 14,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDDEAFF),
                        child: Icon(Icons.dining, color: AppColors.Ocean),
                      ),
                      title: Text(
                        restaurant.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${restaurant.cuisine} • ${restaurant.distanceMiles.toStringAsFixed(1)} mi',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openRestaurantMenu(context, restaurant),
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
