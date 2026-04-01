import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/data/user_preferences_repository.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/utils/API_endpoints.dart';
import 'package:restaurantfinder/utils/menu_voice_context.dart';
import 'package:restaurantfinder/utils/permissions.dart';
import 'package:restaurantfinder/utils/speech_assistant.dart';
import 'package:restaurantfinder/widgets/allergy_dialog.dart';
import 'package:restaurantfinder/widgets/find_menu.dart';
import 'package:restaurantfinder/widgets/restaurant_menu_page.dart';
import 'package:restaurantfinder/widgets/settings_menu.dart';

void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final color = ColorScheme.fromSeed(
      seedColor: AppColors.Ocean,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.Onyx,
      onPrimary: AppColors.Alabaster,
      secondary: AppColors.Ocean,
      onSecondary: AppColors.Alabaster,
      surface: Colors.white,
      onSurface: AppColors.Onyx,
      error: const Color(0xFFB00020),
    );

    final text = ThemeData.light().textTheme.copyWith(
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.Onyx),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.Onyx),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.Onyx),
      bodyLarge: const TextStyle(fontSize: 16, color: AppColors.Onyx),
      bodyMedium: const TextStyle(fontSize: 14, color: AppColors.Onyx),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: color,
        textTheme: text,
        cardTheme: const CardThemeData(elevation: 2),
        useMaterial3: true,
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppColors.Ocean),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.Ocean,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F4F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.Ocean, width: 2),
          ),
        ),
      ),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  final prefs = UserPreferencesRepository();
  late final SpeechAssistant voiceAssistant;
  AllergyDialogController? allergyDialogController;
  bool allergyDialogOpen = false;

  int tab = 0;
  bool checkingPerms = false;
  bool notifications = true;
  bool location = true;
  bool voice = true;
  bool history = true;
  bool loadingAllergies = false;
  bool listening = false;
  String heardCommand = '';
  List<String> allergies = [];
  Map<String, String> allergyList = {};
  String permStatus = 'Checking...';
  
  // Restaurant data
  List<Restaurant> nearbyRestaurants = [];
  List<Restaurant> recommendedRestaurants = [];
  bool loadingRestaurants = true;

  @override
  void initState() {
    super.initState();
    voiceAssistant = SpeechAssistant(
      isVoiceEnabled: () => voice,
      onFinalCommand: _handleVoiceCommand,
      onListeningChanged: (isListening) {
        if (!mounted) return;
        setState(() => listening = isListening);
      },
      onHeardCommandChanged: (words) {
        if (!mounted) return;
        setState(() => heardCommand = words);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    _checkPerms();
    await _loadAllergies();
    await _loadSettings();
    await _loadRestaurants();
    await _loadRecommendedRestaurants();
    await _initVoiceAssistant();
    _scheduleRestart();
  }

  @override
  void dispose() {
    voiceAssistant.dispose();
    super.dispose();
  }

  Future<void> _initVoiceAssistant() async => voiceAssistant.init(context: context);

  void _scheduleRestart() => voiceAssistant.scheduleRestart(context);

  Future<void> _announce(String message) async =>
      voiceAssistant.announce(message, context: context);

  Future<void> _loadAllergies() async {
    setState(() => loadingAllergies = true);
    allergyList = await prefs.loadAllowedAllergyLookup();
    allergies = await prefs.loadSavedAllergies();
    if (mounted) setState(() => loadingAllergies = false);
  }

  Future<void> _loadSettings() async {
    final saved = await prefs.loadGeneralSettings();
    if (!mounted) return;
    setState(() {
      notifications = saved['notificationsEnabled'] ?? true;
      location = saved['locationServicesEnabled'] ?? true;
      voice = saved['voiceAssistantEnabled'] ?? true;
      history = saved['saveSearchHistory'] ?? true;
    });

    if (saved['isFirstLaunch'] == true) {
      await _showAllergyDialog();
      await prefs.saveGeneralSettings(
        notificationsEnabled: notifications,
        locationServicesEnabled: location,
        voiceAssistantEnabled: voice,
        saveSearchHistory: history,
        isFirstLaunch: false,
      );
    }
  }

  Future<void> _saveSettings() {
    return prefs.saveGeneralSettings(
      notificationsEnabled: notifications,
      locationServicesEnabled: location,
      voiceAssistantEnabled: voice,
      saveSearchHistory: history,
      isFirstLaunch: false,
    );
  }

  Future<void> _loadRestaurants() async {
    try {
      setState(() => loadingRestaurants = true);
      final data = await getRestaurants();
      
      if (!mounted) return;
      
        final restaurants = data
          .map((item) => Restaurant.fromJson(
            item is Map<String, dynamic> ? item : {}))
          .toList();
      
      final hasDistance = restaurants.any((r) => r.distanceMiles > 0);
      if (location && hasDistance) {
        restaurants.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      } else {
        restaurants.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
      
      setState(() {
        nearbyRestaurants = restaurants.isEmpty ? defaultRestaurants : restaurants;
        loadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        nearbyRestaurants = defaultRestaurants;
        loadingRestaurants = false;
      });
      debugPrint('Error loading nearby restaurants: $e');
    }
  }

  Future<void> _loadRecommendedRestaurants() async {
    try {
      final data = await getRecommendations(
        cuisinePreferences: [],
        dietaryRestrictions: [],
        allergenExclusions: allergies,
        spicePreference: 'mild',
        pricePreference: 'cheap',
      );
      
      if (!mounted) return;
      
      final restaurants = data
          .map((item) {
            if (item is! Map<String, dynamic>) {
              return const Restaurant(
                id: '',
                name: 'Unknown',
                cuisine: 'Unknown',
                distanceMiles: 0.0,
              );
            }
            final restaurantJson =
                item['restaurant'] is Map<String, dynamic>
                    ? item['restaurant'] as Map<String, dynamic>
                    : item;
            return Restaurant.fromJson(restaurantJson);
          })
          .where((r) => r.id.isNotEmpty || r.name != 'Unknown')
          .toList();
      
      setState(() => recommendedRestaurants = restaurants);
    } catch (e) {
      debugPrint('Error loading recommended restaurants: $e');
      setState(() => recommendedRestaurants = []);
    }
  }

  Future<List<Restaurant>> _searchRestaurants(String query) async {
    try {
      final data = await getRestaurants();
      final normalized = query.toLowerCase().trim();

      final restaurants = data
          .map((item) => Restaurant.fromJson(
            item is Map<String, dynamic> ? item : {}))
          .where((r) => r.id.isNotEmpty)
          .toList();

      final nameMatches = restaurants
          .where((r) => r.name.toLowerCase().contains(normalized))
          .toList();
      if (nameMatches.isNotEmpty) {
        return nameMatches;
      }

      final cuisineMatches = restaurants
          .where((r) => r.cuisine.toLowerCase().contains(normalized))
          .toList();
      return cuisineMatches;
    } catch (e) {
      debugPrint('Error searching restaurants: $e');
      return <Restaurant>[];
    }
  }

  Future<void> _checkPerms() async {
    setState(() {
      checkingPerms = true;
      permStatus = 'Checking...';
    });

    final statuses = await requestAppPermissions();
    if (!mounted) return;

    final missing = statuses.entries
        .where((e) => e.value != PermissionStatus.granted)
        .map((e) => e.key.toString().split('.').last)
        .toList();

    setState(() {
      checkingPerms = false;
      permStatus = missing.isEmpty ? 'All set!' : 'Missing: ${missing.join(', ')}';
    });
  }

  Future<void> _startVoiceInput({bool announceStart = true}) async =>
      voiceAssistant.startVoiceInput(
        context: context,
        announceStart: announceStart,
      );

  Future<void> _pauseVoiceInput() async => voiceAssistant.pause();

  Future<void> _toggleVoiceInput() async {
    if (!voice) {
      await _setVoiceAssistant(true);
      return;
    }

    if (voiceAssistant.isListening) {
      await _pauseVoiceInput();
      await _announce('Voice control paused.');
      return;
    }

    await _startVoiceInput();
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => notifications = value);
    await _saveSettings();
    await _announce('Notifications ${value ? 'enabled' : 'disabled'}.');
  }

  Future<void> _setLocation(bool value) async {
    setState(() => location = value);
    await _saveSettings();
    await _announce('Location services ${value ? 'enabled' : 'disabled'}.');
  }

  Future<void> _setVoiceAssistant(bool value) async {
    setState(() => voice = value);
    await _saveSettings();

    if (!value) {
      await _pauseVoiceInput();
      await _announce('Voice assistant disabled.');
      return;
    }

    await _announce('Voice assistant enabled.');
    _scheduleRestart();
  }

  Future<void> _setHistory(bool value) async {
    setState(() => history = value);
    await _saveSettings();
    await _announce('Search history ${value ? 'enabled' : 'disabled'}.');
  }

  Future<void> _resetPreferences() async {
    setState(() {
      notifications = true;
      location = true;
      voice = true;
      history = true;
    });
    await _saveSettings();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Back to normal.')),
    );
    await _announce('Preferences reset to default values.');
  }

  Future<void> _handleVoiceCommand(String raw) async {
    final command = raw.toLowerCase().trim();
    final enable = command.contains('turn on') || command.contains('enable');
    final disable = command.contains('turn off') || command.contains('disable');
    final toggle = command.contains('toggle');

    if (await _handleMenuVoiceCommand(command)) {
      return;
    }

    if (await _handleAllergyVoiceCommand(command)) {
      return;
    }

    if (command == 'close' || command == 'close menu' || command == 'exit menu') {
      await _closeCurrentScreen();
      return;
    }

    if (command.contains('help') || command.contains('what can i say')) {
      await _announce(
        'You can say: go to find, go to settings, open allergies, add allergy name, remove allergy name, refresh permissions, '
        'turn on notifications, turn off location, toggle voice input, toggle search history, reset preferences, '
        'open restaurant name, list restaurants, search restaurant name or cuisine, save allergies, or close menu.',
      );
      return;
    }

    if (command.startsWith('open ')) {
      final restaurantName = command.substring(5).trim();
      await _openRestaurantByName(restaurantName);
      return;
    }

    if (command.contains('list restaurants') || command == 'restaurants') {
      await _listRestaurants();
      return;
    }

    if (command.startsWith('search ') || command.contains('search for')) {
      final searchQuery = command
          .replaceFirst('search for ', '')
          .replaceFirst('search ', '')
          .trim();
      if (searchQuery.isEmpty) {
        await _announce('Please say what to search for. You can search by restaurant name or cuisine.');
        return;
      }
      await _searchByQuery(searchQuery);
      return;
    }

    if (command.contains('go to find') || command.contains("find")) {
      setState(() => tab = 0);
      await _announce('Opened Find tab.');
      return;
    }

    if (command.contains('go to settings') || command.contains("settings")) {
      setState(() => tab = 1);
      await _announce('Opened Settings tab.');
      return;
    }

    if (command.contains('open allergies') || command.contains('set allergies') || command.contains('set allergens')) {
      setState(() => tab = 1);
      await _announce('Opening allergy settings.');
      await _showAllergyDialog();
      return;
    }

    if (command.contains('refresh permissions') || command.contains('check permissions')) {
      setState(() => tab = 1);
      await _announce('Checking permissions.');
      await _checkPerms();
      return;
    }

    if (command.contains('notifications')) {
      if (toggle) return _setNotifications(!notifications);
      if (enable) return _setNotifications(true);
      if (disable) return _setNotifications(false);
    }

    if (command.contains('location')) {
      if (toggle) return _setLocation(!location);
      if (enable) return _setLocation(true);
      if (disable) return _setLocation(false);
    }

    if (command.contains('voice assistant') || command.contains('voice input')) {
      if (toggle) return _setVoiceAssistant(!voice);
      if (enable) return _setVoiceAssistant(true);
      if (disable) return _setVoiceAssistant(false);
    }

    if (command.contains('search history') || command.contains('history')) {
      if (toggle) return _setHistory(!history);
      if (enable) return _setHistory(true);
      if (disable) return _setHistory(false);
    }

    if (command.contains('reset') || command.contains('default')) {
      await _resetPreferences();
      return;
    }

    await _announce('I did not recognize that command. Say help for available commands.');
  }

  Future<void> _closeCurrentScreen() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      await _announce('Closed menu.');
      return;
    }

    await _announce('There is no open menu to close.');
  }

  Restaurant? _findRestaurantByName(String query) {
    final normalizedQuery = _normalizeForMatching(query);
    if (normalizedQuery.isEmpty) return null;

    final localPool = <Restaurant>{
      ...nearbyRestaurants,
      ...recommendedRestaurants,
    }.toList();

    Restaurant? best;
    int bestScore = 0;

    for (final restaurant in localPool) {
      final score = _scoreRestaurantNameMatch(
        _normalizeForMatching(restaurant.name),
        normalizedQuery,
      );

      if (score > bestScore) {
        bestScore = score;
        best = restaurant;
      }
    }

    // Require at least a weak token or substring match to avoid random opens.
    if (bestScore < 40) return null;
    return best;
  }

  String _normalizeForMatching(String input) {
    final lower = input.toLowerCase();
    final folded = lower
        .replaceAll(RegExp(r'[àáâãäåāăą]'), 'a')
        .replaceAll(RegExp(r'[çćĉċč]'), 'c')
        .replaceAll(RegExp(r'[ďđ]'), 'd')
        .replaceAll(RegExp(r'[èéêëēĕėęě]'), 'e')
        .replaceAll(RegExp(r'[ĝğġģ]'), 'g')
        .replaceAll(RegExp(r'[ĥħ]'), 'h')
        .replaceAll(RegExp(r'[ìíîïĩīĭįı]'), 'i')
        .replaceAll(RegExp(r'[ĵ]'), 'j')
        .replaceAll(RegExp(r'[ķ]'), 'k')
        .replaceAll(RegExp(r'[ĺļľł]'), 'l')
        .replaceAll(RegExp(r'[ñńņň]'), 'n')
        .replaceAll(RegExp(r'[òóôõöøōŏő]'), 'o')
        .replaceAll(RegExp(r'[ŕŗř]'), 'r')
        .replaceAll(RegExp(r'[śŝşš]'), 's')
        .replaceAll(RegExp(r'[ţťŧ]'), 't')
        .replaceAll(RegExp(r'[ùúûüũūŭůűų]'), 'u')
        .replaceAll(RegExp(r'[ýÿŷ]'), 'y')
        .replaceAll(RegExp(r'[źżž]'), 'z')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return folded;
  }

  int _scoreRestaurantNameMatch(String candidate, String query) {
    if (candidate == query) return 100;
    if (candidate.contains(query) || query.contains(candidate)) return 80;

    final candidateTokens = candidate.split(' ').where((t) => t.isNotEmpty).toSet();
    final queryTokens = query.split(' ').where((t) => t.isNotEmpty).toSet();
    if (candidateTokens.isEmpty || queryTokens.isEmpty) return 0;

    final overlap = candidateTokens.where(queryTokens.contains).length;
    final tokenScore = (overlap / queryTokens.length * 70).round();

    final prefixBoost = candidateTokens.any((t) => queryTokens.any((q) => t.startsWith(q) || q.startsWith(t)))
        ? 20
        : 0;

    return tokenScore + prefixBoost;
  }

  Future<void> _openRestaurantByName(String restaurantName) async {
    final restaurant = _findRestaurantByName(restaurantName);
    if (restaurant == null) {
      await _announce('Could not find a restaurant matching $restaurantName. Say list restaurants to hear all options.');
      return;
    }

    setState(() => tab = 0);
    await _announce('Opening ${restaurant.name}.');

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuPage(
          restaurant: restaurant,
          userAllergies: allergies,
        ),
      ),
    );
  }

  Future<void> _listRestaurants() async {
    final names = nearbyRestaurants.map((r) => r.name).join(', ');
    await _announce('Available restaurants: $names');
  }

  Future<void> _searchByQuery(String query) async {
    final results = await _searchRestaurants(query);

    if (results.isEmpty) {
      await _announce('No restaurants found matching $query.');
      return;
    }

    setState(() => tab = 0);
    final names = results.map((r) => r.name).join(', ');
    await _announce('Found ${results.length} restaurants: $names');
  }

  Future<void> _showAllergyDialog() async {
    if (allergyList.isEmpty) {
      await _loadAllergies();
      if (!mounted || allergyList.isEmpty) return;
    }

    final controller = AllergyDialogController(
      allowedAllergyLookup: allergyList,
      initialAllergies: allergies,
    );
    allergyDialogController = controller;
    allergyDialogOpen = true;

    try {
      final result = await showAllergyDialog(
        context: context,
        initialAllergies: allergies,
        allowedAllergyLookup: allergyList,
        controller: controller,
      );

      if (!mounted || result == null) return;

      setState(() => allergies = result);
      await prefs.saveAllergies(result);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          result.isEmpty ? 'No allergies set.' : 'Got it: ${result.join(', ')}',
        )),
      );
    } finally {
      allergyDialogOpen = false;
      allergyDialogController = null;
    }
  }

  Future<bool> _handleAllergyVoiceCommand(String command) async {
    if (!allergyDialogOpen || allergyDialogController == null) {
      return false;
    }

    if (command == 'save' || command == 'save allergies' || command == 'done') {
      final result = allergyDialogController!.allergies;
      Navigator.of(context, rootNavigator: true).pop(result);
      await _announce('Saved allergies.');
      return true;
    }

    final match = RegExp(r'^(add|remove)\s+(.+)$').firstMatch(command);
    if (match == null) return false;

    final action = match.group(1)!;
    final allergyName = match.group(2)!.trim();
    if (allergyName.isEmpty) return false;

    final controller = allergyDialogController!;
    final success = action == 'add'
        ? controller.addAllergy(allergyName)
        : controller.removeAllergy(allergyName);

    if (success) {
      await _announce('${action == 'add' ? 'Added' : 'Removed'} $allergyName.');
    } else {
      await _announce('I could not ${action == 'add' ? 'add' : 'remove'} $allergyName.');
    }

    return true;
  }

  Future<bool> _handleMenuVoiceCommand(String command) async {
    final menuContext = MenuVoiceContext.instance;
    if (!menuContext.isActive) return false;

    if (command == 'list' || command == 'list items' || command == 'items') {
      await _announceMenuItems(menuContext);
      return true;
    }

    final detailsMatch = RegExp(
      r'^(details for menu item|details for|details)\s+(.+)$',
    ).firstMatch(command);
    if (detailsMatch == null) return false;

    final itemQuery = detailsMatch.group(2)?.trim() ?? '';
    if (itemQuery.isEmpty) {
      await _announce('Please say the menu item name after details for.');
      return true;
    }

    await _announceMenuItemDetails(menuContext, itemQuery);
    return true;
  }

  Future<void> _announceMenuItems(MenuVoiceContext menuContext) async {
    if (menuContext.menuItems.isEmpty) {
      await _announce('I do not have menu items loaded yet for ${menuContext.restaurantName}.');
      return;
    }

    final titles = menuContext.menuItems.map((item) => item.name).join(', ');
    await _announce('Menu items at ${menuContext.restaurantName}: $titles');
  }

  Future<void> _announceMenuItemDetails(
    MenuVoiceContext menuContext,
    String itemQuery,
  ) async {
    if (menuContext.menuItems.isEmpty) {
      await _announce('I do not have menu items loaded yet for ${menuContext.restaurantName}.');
      return;
    }

    final normalizedQuery = _normalizeForMatching(itemQuery);
    RestaurantMenuItem? best;
    int bestScore = 0;

    for (final item in menuContext.menuItems) {
      final score = _scoreRestaurantNameMatch(
        _normalizeForMatching(item.name),
        normalizedQuery,
      );
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    if (best == null || bestScore < 40) {
      await _announce('I could not find a menu item matching $itemQuery.');
      return;
    }

    final description = best.description.isEmpty ? 'No description provided.' : best.description;
    final allergens = best.allergens.isEmpty ? 'None listed.' : best.allergens;
    await _announce(
      'Details for ${best.name}: Description: $description Allergens: $allergens Price: ${best.price.toStringAsFixed(2)} dollars.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tavio', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.Alabaster)),
        backgroundColor: AppColors.Onyx,
        actions: [
          Semantics(
            button: true,
            label: listening ? 'Pause voice input' : 'Resume voice input',
            hint: 'Double tap to pause or resume always-on voice commands',
            child: IconButton(
              onPressed: _toggleVoiceInput,
              tooltip: listening ? 'Pause voice input' : 'Resume voice input',
              icon: Icon(
                listening ? Icons.hearing_disabled : Icons.hearing,
                color: AppColors.Alabaster,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => tab = i),
        indicatorColor: AppColors.Ocean,
        selectedIndex: tab,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.location_pin, color: AppColors.Alabaster),
            icon: Icon(Icons.location_pin, color: AppColors.Ocean),
            label: 'Find',
            tooltip: 'Find nearby restaurants',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings, color: AppColors.Alabaster),
            icon: Icon(Icons.settings, color: AppColors.Ocean),
            label: 'Settings',
            tooltip: 'Open settings',
          ),
        ],
      ),
      body: SafeArea(
        child: [
          FindMenu(
            userAllergies: allergies,
            nearbyRestaurants: nearbyRestaurants,
            recommendedRestaurants: recommendedRestaurants,
            onSearch: _searchRestaurants,
          ),
          SettingsMenu(
            notificationsEnabled: notifications,
            locationServicesEnabled: location,
            voiceAssistantEnabled: voice,
            saveSearchHistory: history,
            isLoadingAllergies: loadingAllergies,
            allergies: allergies,
            permissionSummary: permStatus,
            isCheckingPermissions: checkingPerms,
            onNotificationsChanged: (val) {
              _setNotifications(val);
            },
            onLocationServicesChanged: (val) {
              _setLocation(val);
            },
            onVoiceAssistantChanged: (val) {
              _setVoiceAssistant(val);
            },
            onSaveSearchHistoryChanged: (val) {
              _setHistory(val);
            },
            onOpenAllergies: _showAllergyDialog,
            onPermissionRefresh: _checkPerms,
            onResetPreferences: _resetPreferences,
          ),
        ][tab],
      ),
    );
  }
}
