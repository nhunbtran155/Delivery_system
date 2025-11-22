import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌗 ThemeProvider – Quản lý chế độ sáng / tối toàn app
/// ------------------------------------------------------
/// • Ghi nhớ theme bằng SharedPreferences
/// • Đồng bộ toàn hệ thống (ThemeMode.system)
/// • Cập nhật realtime toàn app mà không reload Splash/Login
class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    // ⚡ Chỉ load theme sau khi widget binding sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadThemeMode();
    });
  }

  /// Lấy theme hiện tại
  ThemeMode get themeMode => _themeMode;

  /// Kiểm tra đang ở Dark Mode
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// 🔁 Chuyển đổi theme và lưu vào SharedPreferences
  Future<void> toggleTheme(bool isOn) async {
    final newMode = isOn ? ThemeMode.dark : ThemeMode.light;

    // ⚡ Chỉ notify nếu có thay đổi để tránh rebuild dư thừa
    if (newMode != _themeMode) {
      _themeMode = newMode;
      notifyListeners();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      _themeMode == ThemeMode.dark
          ? 'dark'
          : _themeMode == ThemeMode.light
          ? 'light'
          : 'system',
    );
  }

  /// 💾 Load theme đã lưu khi khởi động app
  Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);

      switch (saved) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        default:
          _themeMode = ThemeMode.system;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [ThemeProvider] Lỗi khi load theme: $e');
    }
  }
}
