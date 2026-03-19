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
        /// Home page
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
                        const SizedBox(height: 12),
                        Card(child: ListTile(
                          leading: Icon(Icons.dining, color: AppColors.Ocean),
                          title: Text('Food Place 2'),
                          subtitle: Text('Food Type, distance away'),
                        )),
                        const SizedBox(height: 12),
                      ],
                    )
                  ),
                ],
              )
            ),
          ),
        ),

        /// Notifications page
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 1'),
                  subtitle: Text('This is a notification'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 2'),
                  subtitle: Text('This is a notification'),
                ),
              ),
            ],
          ),
        ),

        /// Messages page
        ListView.builder(
          reverse: true,
          itemCount: 2,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Hello',
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.onPrimary,
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
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Hi!',
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ][currentPageIndex],
    );
  }
}