import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeStorage {
  static const String _themeModeKey = 'app.theme_mode';

  Future<ThemeMode?> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_themeModeKey);
    if (storedValue == null || storedValue.isEmpty) {
      return null;
    }

    for (final themeMode in ThemeMode.values) {
      if (themeMode.name == storedValue) {
        return themeMode;
      }
    }

    await preferences.remove(_themeModeKey);
    return null;
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, themeMode.name);
  }
}
