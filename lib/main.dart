import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurantfinder/data/user_preferences_repository.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/utils/permissions.dart';
import 'package:restaurantfinder/widgets/allergy_dialog.dart';
import 'package:restaurantfinder/widgets/chat_menu.dart';
import 'package:restaurantfinder/widgets/find_menu.dart';
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

  int tab = 0;
  bool checkingPerms = false;
  bool notifications = true;
  bool location = true;
  bool voice = true;
  bool history = true;
  bool loadingAllergies = false;
  List<String> allergies = [];
  Map<String, String> allergyList = {};
  String permStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPerms();
      _loadAllergies();
      _loadSettings();
    });
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
            selectedIcon: Icon(Icons.perm_phone_msg, color: AppColors.Alabaster),
            icon: Icon(Icons.perm_phone_msg, color: AppColors.Ocean),
            label: 'Chat',
            tooltip: 'Open assistant chat',
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
          FindMenu(userAllergies: allergies),
          const ChatMenu(),
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
              setState(() => notifications = val);
              _saveSettings();
            },
            onLocationServicesChanged: (val) {
              setState(() => location = val);
              _saveSettings();
            },
            onVoiceAssistantChanged: (val) {
              setState(() => voice = val);
              _saveSettings();
            },
            onSaveSearchHistoryChanged: (val) {
              setState(() => history = val);
              _saveSettings();
            },
            onOpenAllergies: _showAllergyDialog,
            onPermissionRefresh: _checkPerms,
            onResetPreferences: () {
              setState(() {
                notifications = true;
                location = true;
                voice = true;
                history = true;
              });
              _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Back to normal.')),
              );
            },
          ),
        ][tab],
      ),
    );
  }
}
