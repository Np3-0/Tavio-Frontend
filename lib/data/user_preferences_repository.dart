import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class UserPreferencesRepository {
  static const String _preferencesFileName = 'user_preferences.json';
  static const String _allergiesAsset = 'lib/utils/info/allergies.txt';

  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _locationServicesEnabledKey = 'locationServicesEnabled';
  static const String _voiceAssistantEnabledKey = 'voiceAssistantEnabled';
  static const String _saveSearchHistoryKey = 'saveSearchHistory';

  Future<Map<String, String>> loadAllowedAllergyLookup() async {
    final String content = await rootBundle.loadString(_allergiesAsset);
    final Map<String, String> lookup = <String, String>{};

    for (final String line in content.split(RegExp(r'\r?\n'))) {
      final String allergy = line.trim();
      if (allergy.isEmpty) {
        continue;
      }
      lookup[allergy.toLowerCase()] = allergy;
    }

    return lookup;
  }

  Future<List<String>> loadSavedAllergies() async {
    final Map<String, dynamic> data = await _readPreferences();
    final dynamic allergensValue = data['allergens'];
    if (allergensValue is! List<dynamic>) {
      return <String>[];
    }

    return allergensValue
        .whereType<String>()
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
  }

  Future<void> saveAllergies(List<String> allergies) async {
    final File file = await _ensurePreferencesFile();
    final Map<String, dynamic> data = await _readPreferences();

    final List<String> sanitized = <String>[];
    final Set<String> seen = <String>{};
    for (final String allergy in allergies) {
      final String trimmed = allergy.trim();
      final String key = trimmed.toLowerCase();
      if (trimmed.isEmpty || seen.contains(key)) {
        continue;
      }
      seen.add(key);
      sanitized.add(trimmed);
    }

    data['allergens'] = sanitized;
    final String encoded = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(encoded, flush: true);
  }

  Future<Map<String, bool>> loadGeneralSettings() async {
    final Map<String, dynamic> data = await _readPreferences();

    return <String, bool>{
      _notificationsEnabledKey: _boolOrDefault(
        data[_notificationsEnabledKey],
        true,
      ),
      _locationServicesEnabledKey: _boolOrDefault(
        data[_locationServicesEnabledKey],
        true,
      ),
      _voiceAssistantEnabledKey: _boolOrDefault(
        data[_voiceAssistantEnabledKey],
        true,
      ),
      _saveSearchHistoryKey: _boolOrDefault(data[_saveSearchHistoryKey], true),
    };
  }

  Future<void> saveGeneralSettings({
    required bool notificationsEnabled,
    required bool locationServicesEnabled,
    required bool voiceAssistantEnabled,
    required bool saveSearchHistory,
  }) async {
    final File file = await _ensurePreferencesFile();
    final Map<String, dynamic> data = await _readPreferences();

    data[_notificationsEnabledKey] = notificationsEnabled;
    data[_locationServicesEnabledKey] = locationServicesEnabled;
    data[_voiceAssistantEnabledKey] = voiceAssistantEnabled;
    data[_saveSearchHistoryKey] = saveSearchHistory;

    final String encoded = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(encoded, flush: true);
  }

  Future<Map<String, dynamic>> _readPreferences() async {
    final File file = await _ensurePreferencesFile();
    final String content = await file.readAsString();

    try {
      final dynamic parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (_) {
      // Fall through to safe defaults.
    }

    return <String, dynamic>{'allergens': <String>[], 'location': 2};
  }

  Future<File> _ensurePreferencesFile() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final File file = File(
      '${appDirectory.path}${Platform.pathSeparator}$_preferencesFileName',
    );

    if (await file.exists()) {
      return file;
    }

    Map<String, dynamic> defaults = <String, dynamic>{
      'allergens': <String>[],
      'location': 2,
      _notificationsEnabledKey: true,
      _locationServicesEnabledKey: true,
      _voiceAssistantEnabledKey: true,
      _saveSearchHistoryKey: true,
    };

    final String encoded = const JsonEncoder.withIndent('  ').convert(defaults);
    await file.writeAsString(encoded, flush: true);
    return file;
  }

  bool _boolOrDefault(dynamic value, bool defaultValue) {
    if (value is bool) {
      return value;
    }
    return defaultValue;
  }
}
