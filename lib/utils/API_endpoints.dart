import 'package:http/http.dart' as http;
import 'dart:convert';

const String URL = 'http://44.222.171.66';

Future<List<dynamic>> getRestaurants() async {
  try {
    final res = await http.get(Uri.parse('$URL/restaurants/'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load restaurants. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching restaurants: $e');
  }
}

Future<Map<String, dynamic>> getRestaurant(String restaurantId) async {
  try {
    final res = await http.get(Uri.parse('$URL/restaurants/$restaurantId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load restaurant. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching restaurant: $e');
  }
}

Future<dynamic> getRestaurantMenu(String restaurantId) async {
  try {
    final res = await http.get(
      Uri.parse('$URL/restaurants/$restaurantId/menu'),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load menu. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching menu: $e');
  }
}

Future<dynamic> discoverRestaurants({
  required String query,
  required double latitude,
  required double longitude,
  int radiusMeters = 3000,
  String travelMode = 'DRIVE',
  int? maxTravelTimeMinutes,
}) async {
  try {
    final queryParams = {
      'query': query,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius_meters': radiusMeters.toString(),
      'travel_mode': travelMode,
      if (maxTravelTimeMinutes != null)
        'max_travel_time_minutes': maxTravelTimeMinutes.toString(),
    };

    final uri = Uri.parse('$URL/discover/restaurants')
        .replace(queryParameters: queryParams);

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 422) {
      final error = jsonDecode(res.body);
      throw Exception('Validation error: ${error['detail']}');
    } else {
      throw Exception('Failed to discover restaurants. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error discovering restaurants: $e');
  }
}

Future<List<dynamic>> getRecommendations({
  List<String> cuisinePreferences = const [],
  List<String> dietaryRestrictions = const [],
  String spicePreference = 'mild',
  String pricePreference = 'cheap',
  int maxTravelTimeMinutes = 0,
  List<String> preferredTags = const [],
}) async {
  try {
    final payload = {
      'cuisine_preferences': cuisinePreferences,
      'dietary_restrictions': dietaryRestrictions,
      'spice_preference': spicePreference,
      'price_preference': pricePreference,
      'max_travel_time_minutes': maxTravelTimeMinutes,
      'preferred_tags': preferredTags,
    };

    final res = await http.post(
      Uri.parse('$URL/recommendations/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else if (res.statusCode == 422) {
      final error = jsonDecode(res.body);
      throw Exception('Validation error: ${error['detail']}');
    } else {
      throw Exception('Failed to get recommendations. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching recommendations: $e');
  }
}