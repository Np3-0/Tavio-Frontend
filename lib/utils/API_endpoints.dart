import 'package:http/http.dart' as http;
import 'dart:convert';

const String URL = 'http://44.222.171.66:8000';

dynamic _decodeResponseBody(String body) {
  final decoded = jsonDecode(body);
  if (decoded is String) {
    // Some API gateways return stringified JSON.
    try {
      return jsonDecode(decoded);
    } catch (_) {
      return decoded;
    }
  }
  return decoded;
}

String _validationDetail(dynamic errorPayload) {
  if (errorPayload is! Map<String, dynamic>) return 'Invalid request.';
  final detail = errorPayload['detail'];
  if (detail is String) return detail;
  if (detail is List && detail.isNotEmpty) {
    final first = detail.first;
    if (first is Map<String, dynamic>) {
      return first['msg'] as String? ?? 'Invalid request.';
    }
    return detail.join(', ');
  }
  return 'Invalid request.';
}

List<dynamic> _extractListPayload(dynamic payload, List<String> candidateKeys) {
  if (payload is List) return payload;
  if (payload is Map<String, dynamic>) {
    for (final key in candidateKeys) {
      final value = payload[key];
      if (value is List) return value;
    }
  }
  return <dynamic>[];
}

List<dynamic> _flattenMenuPayload(dynamic payload) {
  if (payload is List) return payload;
  if (payload is Map<String, dynamic>) {
    final menu = payload['menu'];
    if (menu is Map<String, dynamic>) {
      final items = <dynamic>[];
      for (final sectionItems in menu.values) {
        if (sectionItems is List) {
          items.addAll(sectionItems);
        }
      }
      return items;
    }
  }
  return <dynamic>[];
}

Future<List<dynamic>> getRestaurants() async {
  try {
    final res = await http.get(Uri.parse('$URL/restaurants/'));
    if (res.statusCode == 200) {
      return _extractListPayload(_decodeResponseBody(res.body), const [
        'restaurants',
        'results',
        'data',
      ]);
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
      final decoded = _decodeResponseBody(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Unexpected restaurant response format.');
    } else {
      throw Exception('Failed to load restaurant. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching restaurant: $e');
  }
}

Future<List<dynamic>> getRestaurantMenu(String restaurantId) async {
  try {
    final res = await http.get(
      Uri.parse('$URL/restaurants/$restaurantId/menu'),
    );
    if (res.statusCode == 200) {
      return _flattenMenuPayload(_decodeResponseBody(res.body));
    } else if (res.statusCode == 404) {
      return <dynamic>[];
    } else {
      throw Exception('Failed to load menu. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching menu: $e');
  }
}

Future<List<dynamic>> discoverRestaurants({
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
      return _extractListPayload(_decodeResponseBody(res.body), const [
        'restaurants',
        'results',
        'data',
      ]);
    } else if (res.statusCode == 422) {
      final error = _decodeResponseBody(res.body);
      throw Exception('Validation error: ${_validationDetail(error)}');
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
  List<String> allergenExclusions = const [],
  String spicePreference = 'mild',
  String pricePreference = 'cheap',
  int maxTravelTimeMinutes = 0,
  List<String> preferredTags = const [],
}) async {
  try {
    final payload = {
      'cuisine_preferences': cuisinePreferences,
      'dietary_restrictions': dietaryRestrictions,
      'allergen_exclusions': allergenExclusions,
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
      return _extractListPayload(_decodeResponseBody(res.body), const [
        'recommendations',
        'results',
        'data',
      ]);
    } else if (res.statusCode == 422) {
      final error = _decodeResponseBody(res.body);
      throw Exception('Validation error: ${_validationDetail(error)}');
    } else {
      throw Exception('Failed to get recommendations. Status: ${res.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching recommendations: $e');
  }
}