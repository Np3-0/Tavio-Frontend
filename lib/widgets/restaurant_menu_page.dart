import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/utils/API_endpoints.dart';
import 'package:restaurantfinder/utils/menu_voice_context.dart';

class RestaurantMenuPage extends StatefulWidget {
  const RestaurantMenuPage({
    required this.restaurant,
    required this.userAllergies,
    super.key,
  });

  final Restaurant restaurant;
  final List<String> userAllergies;

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  late Future<List<dynamic>> _menuFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _menuFuture = getRestaurantMenu(widget.restaurant.id);
    MenuVoiceContext.instance.update(
      restaurantName: widget.restaurant.name,
      menuItems: const [],
    );
  }

  @override
  void dispose() {
    MenuVoiceContext.instance.clear();
    _searchController.dispose();
    super.dispose();
  }

  bool _isBlocked(String itemAllergens) {
    if (widget.userAllergies.isEmpty) return false;
    
    final blocked = widget.userAllergies
        .map((a) => a.trim().toLowerCase())
        .toSet();
    
    final allergens = itemAllergens
        .split(',')
        .map((a) => a.trim().toLowerCase())
        .where((a) => a.isNotEmpty && a != 'none')
        .toSet();
    
    return allergens.any(blocked.contains);
  }

  List<RestaurantMenuItem> _parseMenuItems(dynamic data) {
    if (data is List) {
      final parsedItems = data
          .map((item) => RestaurantMenuItem.fromJson(
              item is Map<String, dynamic> ? item : {}))
          .toList();

      final seen = <String>{};
      final deduped = <RestaurantMenuItem>[];
      for (final item in parsedItems) {
        final key =
            '${item.name.trim().toLowerCase()}|${item.description.trim().toLowerCase()}|${item.allergens.trim().toLowerCase()}|${item.price.toStringAsFixed(2)}';
        if (seen.add(key)) {
          deduped.add(item);
        }
      }

      return deduped;
    }
    return [];
  }

  bool _matchesSearch(RestaurantMenuItem item) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    return item.name.toLowerCase().contains(query) ||
        item.description.toLowerCase().contains(query) ||
        item.allergens.toLowerCase().contains(query);
  }

  List<RestaurantMenuItem> _allowedItems(List<RestaurantMenuItem> items) {
    return items.where((item) => !_isBlocked(item.allergens)).toList();
  }

  List<RestaurantMenuItem> _visibleItems(List<RestaurantMenuItem> allowedItems) {
    return allowedItems.where(_matchesSearch).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.restaurant.name} Menu',
            style: const TextStyle(color: AppColors.Alabaster)),
        backgroundColor: AppColors.Onyx,
        iconTheme: const IconThemeData(color: AppColors.Alabaster),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading menu: ${snapshot.error}',
                  style: theme.textTheme.bodyMedium),
            );
          }

          final items = _parseMenuItems(snapshot.data ?? <dynamic>[]);
          final allowedItems = _allowedItems(items);
          MenuVoiceContext.instance.update(
            restaurantName: widget.restaurant.name,
            menuItems: allowedItems,
          );
          final visible = _visibleItems(allowedItems);
          final hidden = items.length - allowedItems.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Semantics(
                  header: true,
                  child: Text('Menu items',
                      style: theme.textTheme.titleLarge)),
              const SizedBox(height: 8),
              SearchBar(
                controller: _searchController,
                hintText: 'Search this menu',
                leading: const Icon(Icons.search),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 10),
              if (hidden > 0)
                Text('$hidden item(s) hidden due to your allergies.',
                    style: theme.textTheme.bodyMedium),
              if (_searchQuery.trim().isNotEmpty)
                Text('Showing ${visible.length} match(es) for "${_searchQuery.trim()}".',
                    style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Text(
                    _searchQuery.trim().isNotEmpty
                        ? 'No menu items matched your search.'
                        : 'Looks like nothing here is safe for your allergies.',
                    style: theme.textTheme.bodyLarge),
              for (final item in visible)
                Card(
                  child: ListTile(
                    minVerticalPadding: 10,
                    title: Text(item.name),
                    subtitle: Text(
                        '${item.description}\nAllergens: ${item.allergens}'),
                    isThreeLine: true,
                    trailing: Text('\$${item.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
