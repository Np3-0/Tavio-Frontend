class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.name,
    required this.description,
    required this.allergens,
    required this.price,
  });

  factory RestaurantMenuItem.fromJson(Map<String, dynamic> json) {
    final rawAllergens = json['allergens'] ?? json['dietary_info'];
    final allergens = switch (rawAllergens) {
      String value => value,
      List value => value.whereType<String>().join(', '),
      _ => 'None',
    };

    final rawPrice = json['price'] ?? json['item_price'];

    return RestaurantMenuItem(
      name: (json['name'] ?? json['item_name'] ?? 'Unknown') as String,
      description: json['description'] as String? ?? '',
      allergens: allergens.isEmpty ? 'None' : allergens,
      price: (rawPrice as num?)?.toDouble() ?? 0.0,
    );
  }

  final String name;
  final String description;
  final String allergens;
  final double price;
}

double _parseDistanceValue(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
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
    final rawId = json['id'];
    final rawDistanceMiles = json['distance_miles'] ?? json['distance'];
    final rawDistanceMeters = json['distance_meters'];

    double distanceMiles = 0.0;
    final parsedMiles = _parseDistanceValue(rawDistanceMiles);
    final parsedMeters = _parseDistanceValue(rawDistanceMeters);
    if (parsedMiles > 0) {
      distanceMiles = parsedMiles;
    } else if (parsedMeters > 0) {
      distanceMiles = parsedMeters / 1609.344;
    }

    return Restaurant(
      id: rawId?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      cuisine: (json['cuisine'] ?? json['cuisine_type'] ?? 'Unknown') as String,
      distanceMiles: distanceMiles,
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
