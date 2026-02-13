import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

enum AppLanguage { russian, english }

enum MeasurementSystem { metric, imperial }

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();

  static final AppSettingsController instance = AppSettingsController._();

  static const String _themeKey = 'app_theme_preference';
  static const String _languageKey = 'app_language';
  static const String _measurementKey = 'app_measurement_system';
  static const String _ratingKey = 'app_rating';

  AppThemePreference _themePreference = AppThemePreference.system;
  AppLanguage _language = AppLanguage.russian;
  MeasurementSystem _measurementSystem = MeasurementSystem.metric;
  int? _rating;
  bool _isLoaded = false;

  AppThemePreference get themePreference => _themePreference;
  AppLanguage get language => _language;
  MeasurementSystem get measurementSystem => _measurementSystem;
  int? get rating => _rating;
  bool get isLoaded => _isLoaded;

  ThemeMode get themeMode {
    switch (_themePreference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  Locale get locale {
    switch (_language) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.russian:
        return const Locale('ru');
    }
  }

  String get localeTag => locale.languageCode;

  Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _themePreference = _themeFromRaw(
      prefs.getString(_themeKey),
      fallback: _themePreference,
    );
    _language = _languageFromRaw(
      prefs.getString(_languageKey),
      fallback: _language,
    );
    _measurementSystem = _measurementFromRaw(
      prefs.getString(_measurementKey),
      fallback: _measurementSystem,
    );
    _rating = prefs.getInt(_ratingKey);
    _isLoaded = true;
  }

  Brightness resolveBrightness(Brightness platformBrightness) {
    switch (_themePreference) {
      case AppThemePreference.light:
        return Brightness.light;
      case AppThemePreference.dark:
        return Brightness.dark;
      case AppThemePreference.system:
        return platformBrightness;
    }
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    if (_themePreference == preference) {
      return;
    }

    _themePreference = preference;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, preference.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }

  Future<void> setMeasurementSystem(MeasurementSystem system) async {
    if (_measurementSystem == system) {
      return;
    }

    _measurementSystem = system;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_measurementKey, system.name);
  }

  Future<void> setRating(int rating) async {
    if (rating < 1 || rating > 5 || _rating == rating) {
      return;
    }

    _rating = rating;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ratingKey, rating);
  }

  static AppThemePreference _themeFromRaw(
    String? raw, {
    required AppThemePreference fallback,
  }) {
    for (final value in AppThemePreference.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }

  static AppLanguage _languageFromRaw(
    String? raw, {
    required AppLanguage fallback,
  }) {
    for (final value in AppLanguage.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }

  static MeasurementSystem _measurementFromRaw(
    String? raw, {
    required MeasurementSystem fallback,
  }) {
    for (final value in MeasurementSystem.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }
}
