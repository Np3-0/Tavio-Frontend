class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.name,
    required this.description,
    required this.allergens,
    required this.price,
  });

  factory RestaurantMenuItem.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuItem(
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      allergens: json['allergens'] as String? ?? 'None',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String name;
  final String description;
  final String allergens;
  final double price;
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.distanceMiles,
    this.menuItems = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      cuisine: json['cuisine'] as String? ?? 'Unknown',
      distanceMiles: (json['distance_miles'] as num?)?.toDouble() ?? 
                     (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String id;
  final String name;
  final String cuisine;
  final double distanceMiles;
  final List<RestaurantMenuItem> menuItems;

  Restaurant copyWith({List<RestaurantMenuItem>? menuItems}) {
    return Restaurant(
      id: id,
      name: name,
      cuisine: cuisine,
      distanceMiles: distanceMiles,
      menuItems: menuItems ?? this.menuItems,
    );
  }
}

/// Default fallback restaurants when location is unavailable
const List<Restaurant> defaultRestaurants = <Restaurant>[
  Restaurant(
    id: '1',
    name: 'Food Place 1',
    cuisine: 'Italian',
    distanceMiles: 1.2,
  ),
  Restaurant(
    id: '2',
    name: 'Food Place 2',
    cuisine: 'American',
    distanceMiles: 2.0,
  ),
  Restaurant(
    id: '3',
    name: 'Green Bowl',
    cuisine: 'Healthy',
    distanceMiles: 0.8,
  ),
];
