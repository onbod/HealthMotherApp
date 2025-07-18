import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  late SharedPreferences _prefs;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData(
    primaryColor: const Color(0xFF7C4DFF),
    scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF7C4DFF),
      secondary: const Color(0xFF7C4DFF),
      surface: Colors.white,
      background: const Color(0xFFF3F4F6),
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
  );

  static final _darkTheme = ThemeData(
    primaryColor: const Color(0xFF7C4DFF),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF7C4DFF),
      secondary: const Color(0xFF7C4DFF),
      surface: const Color(0xFF2C2C2C),
      background: const Color(0xFF1A1A1A),
    ),
    cardColor: const Color(0xFF2C2C2C),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );
}
