import 'package:flutter/material.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/utils/API_endpoints.dart';

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
  late Future<dynamic> _menuFuture;

  @override
  void initState() {
    super.initState();
    _menuFuture = getRestaurantMenu(widget.restaurant.id);
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
      return data
          .map((item) => RestaurantMenuItem.fromJson(
              item is Map<String, dynamic> ? item : {}))
          .toList();
    }
    return [];
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
      body: FutureBuilder<dynamic>(
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

          final items = _parseMenuItems(snapshot.data ?? []);
          final visible = items
              .where((item) => !_isBlocked(item.allergens))
              .toList();
          final hidden = items.length - visible.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Semantics(
                  header: true,
                  child: Text('Menu items',
                      style: theme.textTheme.titleLarge)),
              const SizedBox(height: 8),
              if (hidden > 0)
                Text('$hidden item(s) hidden due to your allergies.',
                    style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Text('Looks like nothing here is safe for your allergies.',
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
