class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.name,
    required this.description,
    required this.allergens,
    required this.price,
  });

  final String name;
  final String description;
  final String allergens;
  final double price;
}

class Restaurant {
  const Restaurant({
    required this.name,
    required this.cuisine,
    required this.distanceMiles,
    required this.menuItems,
  });

  final String name;
  final String cuisine;
  final double distanceMiles;
  final List<RestaurantMenuItem> menuItems;
}

const List<Restaurant> sampleRestaurants = <Restaurant>[
  Restaurant(
    name: 'Food Place 1',
    cuisine: 'Italian',
    distanceMiles: 1.2,
    menuItems: <RestaurantMenuItem>[
      RestaurantMenuItem(
        name: 'Margherita Pizza',
        description: 'Classic tomato sauce, mozzarella, basil',
        allergens: 'Gluten, Dairy',
        price: 12.99,
      ),
      RestaurantMenuItem(
        name: 'Pasta Alfredo',
        description: 'Creamy parmesan sauce over fettuccine',
        allergens: 'Gluten, Dairy',
        price: 13.49,
      ),
      RestaurantMenuItem(
        name: 'Tiramisu',
        description: 'Espresso-soaked ladyfingers and mascarpone',
        allergens: 'Gluten, Dairy, Eggs',
        price: 6.75,
      ),
    ],
  ),
  Restaurant(
    name: 'Food Place 2',
    cuisine: 'American',
    distanceMiles: 2.0,
    menuItems: <RestaurantMenuItem>[
      RestaurantMenuItem(
        name: 'Crispy Chicken Sandwich',
        description: 'Lettuce, tomato, house aioli',
        allergens: 'Gluten, Eggs',
        price: 10.49,
      ),
      RestaurantMenuItem(
        name: 'Loaded Fries',
        description: 'Cheddar, bacon bits, green onion',
        allergens: 'Dairy',
        price: 7.25,
      ),
      RestaurantMenuItem(
        name: 'Chocolate Brownie',
        description: 'Served warm with vanilla ice cream',
        allergens: 'Gluten, Dairy, Eggs',
        price: 6.00,
      ),
    ],
  ),
  Restaurant(
    name: 'Green Bowl',
    cuisine: 'Healthy',
    distanceMiles: 0.8,
    menuItems: <RestaurantMenuItem>[
      RestaurantMenuItem(
        name: 'Garden Salad',
        description: 'Mixed greens, cucumber, vinaigrette',
          allergens: 'None',
        price: 8.25,
      ),
      RestaurantMenuItem(
        name: 'Protein Power Bowl',
        description: 'Quinoa, chickpeas, avocado, greens',
        allergens: 'None',
        price: 11.75,
      ),
      RestaurantMenuItem(
        name: 'Fresh Fruit Cup',
        description: 'Seasonal fruit medley',
        allergens: 'None',
        price: 5.50,
      ),
    ],
  ),
];
