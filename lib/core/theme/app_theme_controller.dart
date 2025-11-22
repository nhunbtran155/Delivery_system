import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  // Gọi notifyListeners() với delay để đảm bảo animation chạy mượt
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? true;
    notifyListeners();
  }

  ThemeData get themeData => _isDark ? _darkTheme : _lightTheme;

  // ====== Giao diện tối (nền xám) ======
  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF565656),
    cardColor: const Color(0xFF1E1E1E),
    primaryColor: Colors.redAccent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF565656),
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.dark(primary: Colors.redAccent),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
    ),
  );

  // ====== Giao diện sáng (nền trắng) ======
  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    cardColor: const Color(0xFFF5F5F5),
    primaryColor: Colors.redAccent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    colorScheme: const ColorScheme.light(primary: Colors.redAccent),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      bodyLarge: TextStyle(color: Colors.black87),
    ),
  );
}
