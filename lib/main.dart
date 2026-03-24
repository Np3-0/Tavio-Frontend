import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurantfinder/utils/app_colors.dart';
import 'package:restaurantfinder/utils/permissions.dart';

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
  int currentPageIndex = 0;
  bool isCheckingPermissions = false;
  bool notificationsEnabled = true;
  bool locationServicesEnabled = true;
  bool voiceAssistantEnabled = true;
  bool saveSearchHistory = true;
  String permissionSummary = 'Pending permission check...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPermissionCheck();
    });
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Finder', style: TextStyle(color: AppColors.Alabaster)),
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
            selectedIcon: Icon(Icons.perm_phone_msg, color: AppColors.Alabaster),
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

      body: <Widget>[
        // Home page
        Card(
          elevation: 0,
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text('Restaurant Finder', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Find local restaurants in your area.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  SearchBar(
                    hintText: 'Search restaurants...',
                    leading: Icon(Icons.search),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 48),
                  Text('Restaurants near you', style: theme.textTheme.titleMedium),
                  Expanded(
                    child: ListView(
                      children: const <Widget>[
                        Card(child: ListTile(
                          leading: Icon(Icons.dining, color: AppColors.Ocean),
                          title: Text('Food Place 1'),
                          subtitle: Text('Food Type, distance away'),
                        )),
                        SizedBox(height: 12),
                        Card(child: ListTile(
                          leading: Icon(Icons.dining, color: AppColors.Ocean),
                          title: Text('Food Place 2'),
                          subtitle: Text('Food Type, distance away'),
                        )),
                        SizedBox(height: 12),
                      ],
                    )
                  ),
                ],
              )
            ),
          ),
        ),

        // Chat page
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 24),
              Text('Chat', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(
                'Voice-chat with our AI-assistant.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: 4,
                            itemBuilder: (BuildContext context, int index) {
                              if (index % 2 == 1) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(8.0),
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.Ocean,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      'Hello',
                                      style: theme.textTheme.bodyLarge!.copyWith(
                                        color: AppColors.Alabaster,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.Ocean,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    'Hi!',
                                    style: theme.textTheme.bodyLarge!.copyWith(
                                      color: AppColors.Alabaster,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.Ocean,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  // add voice input
                                },
                                icon: Icon(
                                  Icons.mic,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            IconButton(
                              onPressed: () {
                                //add code here
                              },
                              icon: const Icon(Icons.send, color: AppColors.Ocean),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// Settings page
        Card(
          elevation: 0,
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text('Settings Menu', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Change values and permissions for the app.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        Card(
                          child: SwitchListTile(
                            secondary: const Icon(Icons.notifications, color: AppColors.Ocean),
                            title: const Text('Push Notifications'),
                            subtitle: const Text('Get updates for nearby restaurants and offers.'),
                            activeTrackColor: AppColors.Ocean,
                            value: notificationsEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                notificationsEnabled = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: SwitchListTile(
                            secondary: const Icon(Icons.location_on, color: AppColors.Ocean),
                            title: const Text('Use Current Location'),
                            subtitle: const Text('Help find restaurants close to you.'),
                            activeTrackColor: AppColors.Ocean,
                            value: locationServicesEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                locationServicesEnabled = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: SwitchListTile(
                            secondary: const Icon(Icons.mic, color: AppColors.Ocean),
                            title: const Text('Voice Assistant'),
                            subtitle: const Text('Enable voice input in chat.'),
                            activeTrackColor: AppColors.Ocean,
                            value: voiceAssistantEnabled,
                            onChanged: (bool value) {
                              setState(() {
                                voiceAssistantEnabled = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: SwitchListTile(
                            secondary: const Icon(Icons.history, color: AppColors.Ocean),
                            title: const Text('Save Search History'),
                            subtitle: const Text('Keep recent searches for quick access.'),
                            activeTrackColor: AppColors.Ocean,
                            value: saveSearchHistory,
                            onChanged: (bool value) {
                              setState(() {
                                saveSearchHistory = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.verified_user, color: AppColors.Ocean),
                            title: const Text('Permission Status'),
                            subtitle: Text(permissionSummary),
                            trailing: isCheckingPermissions
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    onPressed: _runPermissionCheck,
                                    icon: const Icon(Icons.refresh, color: AppColors.Ocean),
                                    tooltip: 'Check again',
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.lock_reset, color: AppColors.Ocean),
                            title: const Text('Reset Preferences'),
                            subtitle: const Text('Restore all settings to defaults.'),
                            onTap: () {
                              setState(() {
                                notificationsEnabled = true;
                                locationServicesEnabled = true;
                                voiceAssistantEnabled = true;
                                saveSearchHistory = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Settings reset to defaults.')),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  ),
                ],
              )
            ),
          ),
        ),

      ][currentPageIndex],
    );
  }
}