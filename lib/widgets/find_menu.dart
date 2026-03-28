import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/widgets/restaurant_menu_page.dart';

class FindMenu extends StatelessWidget {
  const FindMenu({super.key});

  void _openRestaurantMenu(BuildContext context, Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestaurantMenuPage(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text('Restaurant Finder', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Find local restaurants in your area.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              SearchBar(
                hintText: 'Search restaurants...',
                leading: const Icon(Icons.search),
                onChanged: (value) {},
              ),
              const SizedBox(height: 48),
              Text('Restaurants near you', style: theme.textTheme.titleMedium),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    for (final Restaurant restaurant
                        in sampleRestaurants) ...<Widget>[
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.dining,
                            color: AppColors.Ocean,
                          ),
                          title: Text(restaurant.name),
                          subtitle: Text(
                            '${restaurant.cuisine}, ${restaurant.distanceMiles.toStringAsFixed(1)} miles away',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openRestaurantMenu(context, restaurant),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
