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
    return const MaterialApp(home: NavigationExample());
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  final UserPreferencesRepository _preferencesRepository =
      UserPreferencesRepository();

  int currentPageIndex = 0;
  bool isCheckingPermissions = false;
  bool notificationsEnabled = true;
  bool locationServicesEnabled = true;
  bool voiceAssistantEnabled = true;
  bool saveSearchHistory = true;
  bool isLoadingAllergies = false;
  final List<String> allergies = <String>[];
  Map<String, String> allowedAllergyLookup = <String, String>{};
  String permissionSummary = 'Pending permission check...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPermissionCheck();
      _loadAllergyPreferences();
      _loadGeneralSettings();
    });
  }

  Future<void> _loadAllergyPreferences() async {
    setState(() {
      isLoadingAllergies = true;
    });

    final Map<String, String> loadedLookup = await _preferencesRepository
        .loadAllowedAllergyLookup();
    final List<String> savedAllergies = await _preferencesRepository
        .loadSavedAllergies();

    if (!mounted) {
      return;
    }

    setState(() {
      allowedAllergyLookup = loadedLookup;
      allergies
        ..clear()
        ..addAll(savedAllergies);
      isLoadingAllergies = false;
    });
  }

  Future<void> _loadGeneralSettings() async {
    final Map<String, bool> savedSettings = await _preferencesRepository
        .loadGeneralSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      notificationsEnabled = savedSettings['notificationsEnabled'] ?? true;
      locationServicesEnabled =
          savedSettings['locationServicesEnabled'] ?? true;
      voiceAssistantEnabled = savedSettings['voiceAssistantEnabled'] ?? true;
      saveSearchHistory = savedSettings['saveSearchHistory'] ?? true;
    });
  }

  Future<void> _saveGeneralSettings() {
    return _preferencesRepository.saveGeneralSettings(
      notificationsEnabled: notificationsEnabled,
      locationServicesEnabled: locationServicesEnabled,
      voiceAssistantEnabled: voiceAssistantEnabled,
      saveSearchHistory: saveSearchHistory,
    );
  }

  Future<void> _runPermissionCheck() async {
    setState(() {
      isCheckingPermissions = true;
      permissionSummary = 'Checking location, voice, camera, and photos...';
    });

    final statuses = await requestAppPermissions();
    if (!mounted) {
      return;
    }

    final missing = statuses.entries
        .where((entry) => entry.value != PermissionStatus.granted)
        .map((entry) => entry.key.toString().split('.').last)
        .toList();

    setState(() {
      isCheckingPermissions = false;
      permissionSummary = missing.isEmpty
          ? 'All requested permissions granted.'
          : 'Missing: ${missing.join(', ')}';
    });
  }

  Future<void> _showAllergyDialog() async {
    if (allowedAllergyLookup.isEmpty) {
      await _loadAllergyPreferences();
      if (!mounted || allowedAllergyLookup.isEmpty) {
        return;
      }
    }

    final List<String>? updatedAllergies = await showAllergyDialog(
      context: context,
      initialAllergies: allergies,
      allowedAllergyLookup: allowedAllergyLookup,
    );

    if (!mounted || updatedAllergies == null) {
      return;
    }

    setState(() {
      allergies
        ..clear()
        ..addAll(updatedAllergies);
    });

    await _preferencesRepository.saveAllergies(updatedAllergies);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allergies.isEmpty
              ? 'No allergies saved.'
              : 'Saved allergies: ${allergies.join(', ')}',
        ),
      ),
    );
  }

  Widget _buildCurrentPage(BuildContext context) {
    switch (currentPageIndex) {
      case 0:
        return FindMenu(userAllergies: allergies);
      case 1:
        return const ChatMenu();
      case 2:
        return SettingsMenu(
          notificationsEnabled: notificationsEnabled,
          locationServicesEnabled: locationServicesEnabled,
          voiceAssistantEnabled: voiceAssistantEnabled,
          saveSearchHistory: saveSearchHistory,
          isLoadingAllergies: isLoadingAllergies,
          allergies: allergies,
          permissionSummary: permissionSummary,
          isCheckingPermissions: isCheckingPermissions,
          onNotificationsChanged: (bool value) {
            setState(() {
              notificationsEnabled = value;
            });
            _saveGeneralSettings();
          },
          onLocationServicesChanged: (bool value) {
            setState(() {
              locationServicesEnabled = value;
            });
            _saveGeneralSettings();
          },
          onVoiceAssistantChanged: (bool value) {
            setState(() {
              voiceAssistantEnabled = value;
            });
            _saveGeneralSettings();
          },
          onSaveSearchHistoryChanged: (bool value) {
            setState(() {
              saveSearchHistory = value;
            });
            _saveGeneralSettings();
          },
          onOpenAllergies: _showAllergyDialog,
          onPermissionRefresh: _runPermissionCheck,
          onResetPreferences: () {
            setState(() {
              notificationsEnabled = true;
              locationServicesEnabled = true;
              voiceAssistantEnabled = true;
              saveSearchHistory = true;
            });
            _saveGeneralSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings reset to defaults.')),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurant Finder',
          style: TextStyle(color: AppColors.Alabaster),
        ),
        backgroundColor: AppColors.Onyx,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: AppColors.Ocean,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.location_pin, color: AppColors.Alabaster),
            icon: Icon(Icons.location_pin, color: AppColors.Onyx),
            label: 'Find',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.perm_phone_msg,
              color: AppColors.Alabaster,
            ),
            icon: Icon(Icons.perm_phone_msg, color: AppColors.Onyx),
            label: 'Chat',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings, color: AppColors.Alabaster),
            icon: Icon(Icons.settings, color: AppColors.Onyx),
            label: 'Settings',
          ),
        ],
      ),
      body: _buildCurrentPage(context),
    );
  }
}
