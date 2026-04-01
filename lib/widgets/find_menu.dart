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

  List<Restaurant> _sortedRestaurants(List<Restaurant> restaurants) {
    final sorted = [...restaurants];
    final hasDistance = sorted.any((restaurant) => restaurant.distanceMiles > 0);

    if (hasDistance) {
      sorted.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
    } else {
      sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return sorted;
  }

  String _distanceText(Restaurant restaurant) {
    if (restaurant.distanceMiles <= 0) return 'Distance unavailable';
    return '${restaurant.distanceMiles.toStringAsFixed(1)} mi away';
  }

  Widget _restaurantTile({
    required ThemeData theme,
    required Restaurant restaurant,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        minVerticalPadding: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFDDEAFF),
          child: Icon(icon, color: AppColors.Ocean),
        ),
        title: Text(restaurant.name, style: theme.textTheme.titleMedium),
        subtitle: Text(
          '${restaurant.cuisine} • ${_distanceText(restaurant)}',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openRestaurant(restaurant),
      ),
    );
  }

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
    final displayRestaurants = currentQuery.isEmpty
      ? _sortedRestaurants(widget.nearbyRestaurants)
      : _sortedRestaurants(searchResults);
    final recommendedRestaurants = _sortedRestaurants(widget.recommendedRestaurants);

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
                    ? _buildNearbyAndRecommended(theme, displayRestaurants, recommendedRestaurants)
                    : _buildSearchResults(theme, displayRestaurants),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyAndRecommended(
      ThemeData theme,
      List<Restaurant> nearbyList,
      List<Restaurant> recommendedList,
      ) {
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nearbyList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final restaurant = nearbyList[i];
              return _restaurantTile(
                theme: theme,
                restaurant: restaurant,
                icon: Icons.dining,
              );
            },
          ),
        const SizedBox(height: 30),
        if (recommendedList.isNotEmpty) ...[
          Text('Recommended for you', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendedList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final restaurant = recommendedList[i];
              return _restaurantTile(
                theme: theme,
                restaurant: restaurant,
                icon: Icons.favorite,
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
                return _restaurantTile(
                  theme: theme,
                  restaurant: restaurant,
                  icon: Icons.dining,
                );
              },
            ),
          ),
      ],
    );
  }
}
