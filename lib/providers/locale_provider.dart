import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Locale provider for runtime language switching
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  static const String _localeKey = 'language_code';
  
  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey);
    
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
  
  Future<void> clearLocale() async {
    state = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
  }
}

// Helper function to get locale name
String getLocaleName(Locale? locale) {
  if (locale == null) return 'System Default';
  
  switch (locale.languageCode) {
    case 'en':
      return 'English';
    case 'ta':
      return 'தமிழ் (Tamil)';
    default:
      return locale.languageCode;
  }
}
