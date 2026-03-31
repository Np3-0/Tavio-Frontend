import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class UserPreferencesRepository {
  static const _file = 'user_preferences.json';
  static const _allergies = 'lib/utils/info/allergies.txt';

  Future<Map<String, String>> loadAllowedAllergyLookup() async {
    final content = await rootBundle.loadString(_allergies);
    final lookup = <String, String>{};
    
    for (final line in content.split(RegExp(r'\r?\n'))) {
      final allergy = line.trim();
      if (allergy.isNotEmpty) {
        lookup[allergy.toLowerCase()] = allergy;
      }
    }
    return lookup;
  }

  Future<List<String>> loadSavedAllergies() async {
    final data = await _read();
    final value = data['allergens'];
    if (value is! List) return [];
    
    return value
        .whereType<String>()
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  Future<void> saveAllergies(List<String> allergies) async {
    final file = await _getFile();
    final data = await _read();
    
    final sanitized = <String>[];
    final seen = <String>{};
    for (final a in allergies) {
      final trimmed = a.trim();
      if (trimmed.isEmpty) continue;
      
      final key = trimmed.toLowerCase();
      if (seen.contains(key)) continue;
      
      seen.add(key);
      sanitized.add(trimmed);
    }
    
    data['allergens'] = sanitized;
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data), flush: true);
  }

  Future<Map<String, bool>> loadGeneralSettings() async {
    final data = await _read();
    
    return {
      'notificationsEnabled': data['notificationsEnabled'] as bool? ?? true,
      'locationServicesEnabled': data['locationServicesEnabled'] as bool? ?? true,
      'voiceAssistantEnabled': data['voiceAssistantEnabled'] as bool? ?? true,
      'saveSearchHistory': data['saveSearchHistory'] as bool? ?? true,
      'isFirstLaunch': data['isFirstLaunch'] as bool? ?? true,
    };
  }

  Future<void> saveGeneralSettings({
    required bool notificationsEnabled,
    required bool locationServicesEnabled,
    required bool voiceAssistantEnabled,
    required bool saveSearchHistory,
    bool isFirstLaunch = false,
  }) async {
    final file = await _getFile();
    final data = await _read();
    
    data['notificationsEnabled'] = notificationsEnabled;
    data['locationServicesEnabled'] = locationServicesEnabled;
    data['voiceAssistantEnabled'] = voiceAssistantEnabled;
    data['saveSearchHistory'] = saveSearchHistory;
    data['isFirstLaunch'] = isFirstLaunch;
    
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data), flush: true);
  }

  Future<Map<String, dynamic>> _read() async {
    final file = await _getFile();
    try {
      final content = await file.readAsString();
      final parsed = jsonDecode(content);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      // oh well
    }
    return {'allergens': [], 'location': 2};
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$_file');
    
    if (await file.exists()) return file;
    
    final defaults = {
      'allergens': [],
      'location': 2,
      'notificationsEnabled': true,
      'locationServicesEnabled': true,
      'voiceAssistantEnabled': true,
      'saveSearchHistory': true,
      'isFirstLaunch': true,
    };
    
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(defaults), flush: true);
    return file;
  }
}
