import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String apiKey;
  final String aiProvider;
  final String? aiModel;
  final String companionName;

  const AppSettings({
    this.apiKey = '',
    this.aiProvider = 'gemini',
    this.aiModel = 'gemini-2.5-flash',
    this.companionName = '阿樹',
  });

  AppSettings copyWith({
    String? apiKey,
    String? aiProvider,
    String? aiModel,
    String? companionName,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      aiProvider: aiProvider ?? this.aiProvider,
      aiModel: aiModel ?? this.aiModel,
      companionName: companionName ?? this.companionName,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiKey': apiKey,
        'aiProvider': aiProvider,
        'aiModel': aiModel,
        'companionName': companionName,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      apiKey: json['apiKey'] as String? ?? '',
      aiProvider: json['aiProvider'] as String? ?? 'gemini',
      aiModel: json['aiModel'] as String?,
      companionName: json['companionName'] as String? ?? '阿樹',
    );
  }

  bool get hasApiKey => apiKey.isNotEmpty;
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('app_settings');
    if (json != null) {
      state = AppSettings.fromJson(jsonDecode(json));
    }
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', jsonEncode(settings.toJson()));
    state = settings;
  }

  Future<void> reset() async {
    const defaultSettings = AppSettings();
    await save(defaultSettings);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
