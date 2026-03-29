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
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text('Settings', style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage accessibility, privacy, and app preferences.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: <Widget>[
                Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    secondary: const Icon(
                      Icons.notifications,
                      color: AppColors.Ocean,
                    ),
                    title: const Text('Push Notifications'),
                    subtitle: const Text(
                      'Get updates for nearby restaurants and offers.',
                    ),
                    activeTrackColor: AppColors.Ocean,
                    value: notificationsEnabled,
                    onChanged: onNotificationsChanged,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    secondary: const Icon(
                      Icons.location_on,
                      color: AppColors.Ocean,
                    ),
                    title: const Text('Use Current Location'),
                    subtitle: const Text(
                      'Help find restaurants close to you.',
                    ),
                    activeTrackColor: AppColors.Ocean,
                    value: locationServicesEnabled,
                    onChanged: onLocationServicesChanged,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    secondary: const Icon(
                      Icons.mic,
                      color: AppColors.Ocean,
                    ),
                    title: const Text('Voice Assistant'),
                    subtitle: const Text('Enable voice input in chat.'),
                    activeTrackColor: AppColors.Ocean,
                    value: voiceAssistantEnabled,
                    onChanged: onVoiceAssistantChanged,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    secondary: const Icon(
                      Icons.history,
                      color: AppColors.Ocean,
                    ),
                    title: const Text('Save Search History'),
                    subtitle: const Text(
                      'Keep recent searches for quick access.',
                    ),
                    activeTrackColor: AppColors.Ocean,
                    value: saveSearchHistory,
                    onChanged: onSaveSearchHistoryChanged,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Set allergens',
                  hint: 'Opens allergy selection dialog',
                  child: Card(
                    child: ListTile(
                      minVerticalPadding: 12,
                      leading: const Icon(
                        Icons.no_food,
                        color: AppColors.Ocean,
                      ),
                      title: const Text('Set Allergens'),
                      subtitle: Text(
                        isLoadingAllergies
                            ? 'Loading saved allergies...'
                            : allergies.isEmpty
                                ? 'No allergies saved yet.'
                                : allergies.join(', '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isLoadingAllergies ? null : onOpenAllergies,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    minVerticalPadding: 12,
                    leading: const Icon(
                      Icons.verified_user,
                      color: AppColors.Ocean,
                    ),
                    title: const Text('Permission Status'),
                    subtitle: Text(permissionSummary),
                    trailing: isCheckingPermissions
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            onPressed: onPermissionRefresh,
                            icon: const Icon(
                              Icons.refresh,
                              color: AppColors.Ocean,
                            ),
                            tooltip: 'Check permissions again',
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Reset preferences',
                  hint: 'Restores all settings to defaults',
                  child: Card(
                    child: ListTile(
                      minVerticalPadding: 12,
                      leading: const Icon(
                        Icons.lock_reset,
                        color: AppColors.Ocean,
                      ),
                      title: const Text('Reset Preferences'),
                      subtitle: const Text(
                        'Restore all settings to defaults.',
                      ),
                      onTap: onResetPreferences,
                    ),
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
