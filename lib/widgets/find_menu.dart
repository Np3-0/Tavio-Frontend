import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/widgets/restaurant_menu_page.dart';

typedef RestaurantSearchCallback = Future<List<Restaurant>> Function(String query);

class FindMenu extends StatefulWidget {
  const FindMenu({
    required this.userAllergies,
    required this.nearbyRestaurants,
    required this.recommendedRestaurants,
    required this.onSearch,
    super.key,
  });

  final List<String> userAllergies;
  final List<Restaurant> nearbyRestaurants;
  final List<Restaurant> recommendedRestaurants;
  final RestaurantSearchCallback onSearch;

  @override
  State<FindMenu> createState() => _FindMenuState();
}

class _FindMenuState extends State<FindMenu> {
  List<Restaurant> searchResults = [];
  bool isSearching = false;
  String currentQuery = '';

  Future<void> _handleSearch(String query) async {
    setState(() {
      currentQuery = query;
      isSearching = true;
    });

    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    try {
      final results = await widget.onSearch(query);
      if (mounted) {
        setState(() {
          searchResults = results;
          isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuPage(
          restaurant: restaurant,
          userAllergies: widget.userAllergies,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayRestaurants =
        currentQuery.isEmpty ? widget.nearbyRestaurants : searchResults;

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
            onChanged: _handleSearch,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: isSearching
                ? const Center(child: CircularProgressIndicator())
                : currentQuery.isEmpty
                    ? _buildNearbyAndRecommended(theme, displayRestaurants)
                    : _buildSearchResults(theme, displayRestaurants),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyAndRecommended(
      ThemeData theme, List<Restaurant> nearbyList) {
    return ListView(
      children: [
        Text('What\'s near you', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (nearbyList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No nearby restaurants found.',
                style: theme.textTheme.bodyMedium),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearbyList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final restaurant = nearbyList[i];
                return SizedBox(
                  width: 280,
                  child: Card(
                    child: ListTile(
                      minVerticalPadding: 14,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDDEAFF),
                        child: Icon(Icons.dining, color: AppColors.Ocean),
                      ),
                      title: Text(restaurant.name,
                          style: theme.textTheme.titleMedium),
                      subtitle: Text(
                        '${restaurant.cuisine} • ${restaurant.distanceMiles.toStringAsFixed(1)} mi',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openRestaurant(restaurant),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 30),
        if (widget.recommendedRestaurants.isNotEmpty) ...[
          Text('Recommended for you', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.recommendedRestaurants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final restaurant = widget.recommendedRestaurants[i];
              return Card(
                child: ListTile(
                  minVerticalPadding: 14,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDDEAFF),
                    child: Icon(Icons.favorite, color: AppColors.Ocean),
                  ),
                  title: Text(restaurant.name,
                      style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    '${restaurant.cuisine} • ${restaurant.distanceMiles.toStringAsFixed(1)} mi',
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openRestaurant(restaurant),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme, List<Restaurant> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search results for "$currentQuery"',
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No restaurants found matching your search.',
                style: theme.textTheme.bodyMedium),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final restaurant = results[i];
                return Card(
                  child: ListTile(
                    minVerticalPadding: 14,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDDEAFF),
                      child: Icon(Icons.dining, color: AppColors.Ocean),
                    ),
                    title: Text(restaurant.name,
                        style: theme.textTheme.titleMedium),
                    subtitle: Text(
                      '${restaurant.cuisine} • ${restaurant.distanceMiles.toStringAsFixed(1)} mi',
                      style: theme.textTheme.bodyMedium,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openRestaurant(restaurant),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
