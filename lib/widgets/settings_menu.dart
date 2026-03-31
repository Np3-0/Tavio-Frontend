import 'package:flutter/material.dart';
import 'package:restaurantfinder/utils/app_colors.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({
    required this.notificationsEnabled,
    required this.locationServicesEnabled,
    required this.voiceAssistantEnabled,
    required this.saveSearchHistory,
    required this.isLoadingAllergies,
    required this.allergies,
    required this.permissionSummary,
    required this.isCheckingPermissions,
    required this.onNotificationsChanged,
    required this.onLocationServicesChanged,
    required this.onVoiceAssistantChanged,
    required this.onSaveSearchHistoryChanged,
    required this.onOpenAllergies,
    required this.onPermissionRefresh,
    required this.onResetPreferences,
    super.key,
  });

  final bool notificationsEnabled;
  final bool locationServicesEnabled;
  final bool voiceAssistantEnabled;
  final bool saveSearchHistory;
  final bool isLoadingAllergies;
  final List<String> allergies;
  final String permissionSummary;
  final bool isCheckingPermissions;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onLocationServicesChanged;
  final ValueChanged<bool> onVoiceAssistantChanged;
  final ValueChanged<bool> onSaveSearchHistoryChanged;
  final VoidCallback onOpenAllergies;
  final VoidCallback onPermissionRefresh;
  final VoidCallback onResetPreferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('Settings', style: theme.textTheme.headlineSmall)),
          const SizedBox(height: 8),
          Text('Make the app work the way you want.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _ToggleSetting(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Get alerts about nearby places.',
                  value: notificationsEnabled,
                  onChanged: onNotificationsChanged,
                ),
                _ToggleSetting(
                  icon: Icons.location_on,
                  title: 'Share Your Location',
                  subtitle: 'Find restaurants near you.',
                  value: locationServicesEnabled,
                  onChanged: onLocationServicesChanged,
                ),
                _ToggleSetting(
                  icon: Icons.mic,
                  title: 'Voice Assistant',
                  subtitle: 'Use voice commands.',
                  value: voiceAssistantEnabled,
                  onChanged: onVoiceAssistantChanged,
                ),
                _ToggleSetting(
                  icon: Icons.history,
                  title: 'Save Your Searches',
                  subtitle: 'Remember what you looked up.',
                  value: saveSearchHistory,
                  onChanged: onSaveSearchHistoryChanged,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    minVerticalPadding: 12,
                    leading: const Icon(Icons.no_food, color: AppColors.Ocean),
                    title: const Text('Set Allergens'),
                    subtitle: Text(
                      isLoadingAllergies ? 'Loading...' : allergies.isEmpty ? 'None yet.' : allergies.join(', '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: isLoadingAllergies ? null : onOpenAllergies,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    minVerticalPadding: 12,
                    leading: const Icon(Icons.verified_user, color: AppColors.Ocean),
                    title: const Text('Your Permissions'),
                    subtitle: Text(permissionSummary),
                    trailing: isCheckingPermissions
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: onPermissionRefresh,
                            icon: const Icon(Icons.refresh, color: AppColors.Ocean),
                            tooltip: 'Check permissions again',
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    minVerticalPadding: 12,
                    leading: const Icon(Icons.lock_reset, color: AppColors.Ocean),
                    title: const Text('Reset Everything'),
                    subtitle: const Text('Back to how it started.'),
                    onTap: onResetPreferences,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  const _ToggleSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Icon(icon, color: AppColors.Ocean),
        title: Text(title),
        subtitle: Text(subtitle),
        activeTrackColor: AppColors.Ocean,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
