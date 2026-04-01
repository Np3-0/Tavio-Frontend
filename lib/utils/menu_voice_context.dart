import 'package:restaurantfinder/data/restaurant_data.dart';

class MenuVoiceContext {
  MenuVoiceContext._();

  static final MenuVoiceContext instance = MenuVoiceContext._();

  String restaurantName = '';
  List<RestaurantMenuItem> menuItems = const [];

  bool get isActive => restaurantName.isNotEmpty;

  void update({
    required String restaurantName,
    required List<RestaurantMenuItem> menuItems,
  }) {
    this.restaurantName = restaurantName;
    this.menuItems = menuItems;
  }

  void clear() {
    restaurantName = '';
    menuItems = const [];
  }
}
