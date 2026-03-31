import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurantfinder/data/restaurant_data.dart';
import 'package:restaurantfinder/data/user_preferences_repository.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/utils/API_endpoints.dart';
import 'package:restaurantfinder/utils/permissions.dart';
import 'package:restaurantfinder/widgets/allergy_dialog.dart';
import 'package:restaurantfinder/widgets/find_menu.dart';
import 'package:restaurantfinder/widgets/restaurant_menu_page.dart';
import 'package:restaurantfinder/widgets/settings_menu.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  int tab = 0;
  bool checkingPerms = false;
  bool notifications = true;
  bool location = true;
  bool voice = true;
  bool history = true;
  bool loadingAllergies = false;
  bool listening = false;
  bool voiceReady = false;
  bool speaking = false;
  bool pausedByUser = false;
  bool restartPending = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    _checkPerms();
    _loadAllergies();
    await _loadSettings();
    await _loadRestaurants();
    await _loadRecommendedRestaurants();
    await _initVoiceAssistant();
    _scheduleRestart();
  }

  @override
  void dispose() {
    speech.stop();
    tts.stop();
    super.dispose();
  }

  Future<void> _initVoiceAssistant() async {
    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.46);
    await tts.setVolume(1.0);
    await tts.awaitSpeakCompletion(true);

    final available = await speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (_) {
        if (!mounted) return;
        setState(() => listening = false);
        _announce('I could not understand that. Please try again.');
      },
    );

    if (!mounted) return;
    setState(() => voiceReady = available);
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    final nowListening = status == 'listening';
    if (listening != nowListening) {
      setState(() => listening = nowListening);
    }

    final stopped = status == 'done' || status == 'notListening';
    if (stopped) {
      _scheduleRestart();
    }
  }

  void _scheduleRestart() {
    if (!mounted || restartPending || pausedByUser || speaking || !voice || !voiceReady) {
      return;
    }

    if (speech.isListening || listening) return;
    restartPending = true;

    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      restartPending = false;
      if (!mounted || pausedByUser || speaking || !voice || !voiceReady) return;
      if (speech.isListening || listening) return;
      await _startVoiceInput(announceStart: false);
    });
  }

  Future<void> _announce(String message) async {
    if (mounted) {
      await SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    }
    if (!voice) return;

    if (speech.isListening || listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
    }

    speaking = true;
    await tts.stop();
    await tts.speak(message);
    speaking = false;
    _scheduleRestart();
  }

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
      
      List<Restaurant> restaurants = [];
      if (data is List) {
        restaurants = data
            .map((item) => Restaurant.fromJson(
                item is Map<String, dynamic> ? item : {}))
            .toList();
      }
      
      // Sort by distance and take first 3
      restaurants.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      final topThree = restaurants.take(3).toList();
      
      setState(() {
        nearbyRestaurants = topThree.isEmpty ? defaultRestaurants : topThree;
        loadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        nearbyRestaurants = defaultRestaurants;
        loadingRestaurants = false;
      });
      print('Error loading nearby restaurants: $e');
    }
  }

  Future<void> _loadRecommendedRestaurants() async {
    try {
      final data = await getRecommendations(
        cuisinePreferences: [],
        dietaryRestrictions: [],
        spicePreference: 'mild',
        pricePreference: 'cheap',
      );
      
      if (!mounted) return;
      
      List<Restaurant> restaurants = [];
      if (data is List) {
        restaurants = data
            .map((item) => Restaurant.fromJson(
                item is Map<String, dynamic> ? item : {}))
            .toList();
      }
      
      setState(() => recommendedRestaurants = restaurants);
    } catch (e) {
      print('Error loading recommended restaurants: $e');
      setState(() => recommendedRestaurants = []);
    }
  }

  Future<List<Restaurant>> _searchRestaurants(String query) async {
    try {
      final data = await discoverRestaurants(
        query: query,
        latitude: 0.0,
        longitude: 0.0,
        radiusMeters: 5000,
        travelMode: 'DRIVE',
      );
      
      List<Restaurant> restaurants = [];
      if (data is List) {
        restaurants = data
            .map((item) => Restaurant.fromJson(
                item is Map<String, dynamic> ? item : {}))
            .toList();
      } else if (data is Map<String, dynamic>) {
        // Handle wrapped response
        final restaurantList = data['restaurants'];
        if (restaurantList is List) {
          restaurants = restaurantList
              .map((item) => Restaurant.fromJson(
                  item is Map<String, dynamic> ? item : {}))
              .toList();
        }
      }
      
      return restaurants;
    } catch (e) {
      print('Error searching restaurants: $e');
      return [];
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

  Future<void> _startVoiceInput({bool announceStart = true}) async {
    if (!voice) {
      await _announce('Voice assistant is disabled in settings.');
      return;
    }

    if (!voiceReady) {
      await _initVoiceAssistant();
      if (!voiceReady) {
        await _announce('Voice input is unavailable on this device.');
        return;
      }
    }

    final mic = await Permission.microphone.request();
    if (mic != PermissionStatus.granted) {
      await _announce('Microphone permission is required for voice control.');
      return;
    }

    pausedByUser = false;

    if (speech.isListening || listening) {
      return;
    }

    if (announceStart) {
      await _announce('Listening for commands.');
    }

    if (mounted) {
      setState(() {
        heardCommand = '';
        listening = true;
      });
    }

    await speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted || result.recognizedWords.isEmpty) return;
        setState(() => heardCommand = result.recognizedWords);
        if (result.finalResult) {
          speech.stop();
          _handleVoiceCommand(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _pauseVoiceInput() async {
    pausedByUser = true;
    await speech.stop();
    if (mounted) setState(() => listening = false);
  }

  Future<void> _toggleVoiceInput() async {
    if (!voice) {
      await _setVoiceAssistant(true);
      return;
    }

    if (speech.isListening || listening) {
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
      pausedByUser = true;
      await speech.stop();
      if (mounted) setState(() => listening = false);
      await _announce('Voice assistant disabled.');
      return;
    }

    pausedByUser = false;
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

    if (command == 'close' || command == 'close menu' || command == 'exit menu') {
      await _closeCurrentScreen();
      return;
    }

    if (command.contains('help') || command.contains('what can i say')) {
      await _announce(
        'You can say: go to find, go to settings, open allergies, refresh permissions, '
        'turn on notifications, turn off location, toggle voice assistant, toggle search history, reset preferences, '
        'open restaurant name, list restaurants, search cuisine type, or close menu.',
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
      final cuisineQuery = command.replaceAll('search ', '').replaceAll('search for ', '').trim();
      await _searchByCuisine(cuisineQuery);
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

    if (command.contains('voice assistant')) {
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
    final normalized = query.toLowerCase().trim();
    try {
      return nearbyRestaurants.firstWhere(
        (r) => r.name.toLowerCase().contains(normalized),
        orElse: () => throw StateError('not found'),
      );
    } catch (_) {
      return null;
    }
  }

  List<Restaurant> _searchRestaurantsByCuisine(String cuisine) {
    final normalized = cuisine.toLowerCase().trim();
    return nearbyRestaurants
        .where((r) => r.cuisine.toLowerCase().contains(normalized))
        .toList();
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

  Future<void> _searchByCuisine(String cuisine) async {
    final results = _searchRestaurantsByCuisine(cuisine);
    if (results.isEmpty) {
      await _announce('No restaurants found with $cuisine cuisine.');
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

    final result = await showAllergyDialog(
      context: context,
      initialAllergies: allergies,
      allowedAllergyLookup: allergyList,
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
