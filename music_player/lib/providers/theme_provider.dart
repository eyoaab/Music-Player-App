import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  static const String _themeSystem = 'system';
  static const String _themeLight = 'light';
  static const String _themeDark = 'dark';

  String _themeMode = _themeSystem;
  bool _isLoading = true;

  ThemeProvider() {
    _loadThemePreference();
  }

  String get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  bool get isDarkMode {
    if (_themeMode == _themeSystem) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == _themeDark;
  }

  ThemeData get currentTheme =>
      isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = prefs.getString(_themePreferenceKey) ?? _themeSystem;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      _themeMode = _themeSystem;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(String mode) async {
    if (mode != _themeSystem && mode != _themeLight && mode != _themeDark) {
      return;
    }

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, mode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  void toggleTheme() {
    if (_themeMode == _themeSystem) {
      setThemeMode(isDarkMode ? _themeLight : _themeDark);
    } else {
      setThemeMode(_themeMode == _themeDark ? _themeLight : _themeDark);
    }
  }

  void setToSystemTheme() {
    setThemeMode(_themeSystem);
  }

  void setToLightTheme() {
    setThemeMode(_themeLight);
  }

  void setToDarkTheme() {
    setThemeMode(_themeDark);
  }
}
