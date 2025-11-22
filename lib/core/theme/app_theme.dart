import 'package:flutter/material.dart';

/// 🎨 AppTheme – Chủ đề hiện đại, hỗ trợ sáng/tối mượt mà & đồng bộ toàn hệ thống
class AppTheme {
  // ===== MÀU CHỦ ĐẠO =====
  static const Color primaryRed = Color(0xFFCA4746); // đỏ cam nhẹ
  static const Color darkBackground = Color(0xFF565656); // nền xám ấm
  static const Color darkSurface = Color(0xFF2A2A2C); // khối / card
  static const Color darkField = Color(0xFF38383A); // input cố định
  static const Color lightText = Color(0xFFF2F2F2);
  static const Color hintText = Colors.white54;
  static const Color white = Colors.white;

  // ===== DARK THEME =====
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryRed,

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF252525),
      elevation: 1.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: primaryRed),
    ),

    cardTheme: const CardThemeData(
      color: darkSurface,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      shadowColor: Colors.black54,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        shadowColor: Colors.black45,
        elevation: 8,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      ),
    ),

    // ⚡ Giữ ô nhập luôn xám đậm dù đổi theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkField, // cố định #38383A
      hintStyle: const TextStyle(color: hintText),
      labelStyle: const TextStyle(color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: primaryRed, width: 1.2),
      ),
      prefixIconColor: Colors.white70,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightText, fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      titleLarge: TextStyle(
        color: lightText,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      labelLarge: TextStyle(
        color: lightText,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),

    colorScheme: const ColorScheme.dark(
      primary: primaryRed,
      secondary: primaryRed,
      surface: darkSurface,
      onPrimary: white,
      onSurface: Colors.white70,
    ),
  );

  // ===== LIGHT THEME =====
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    primaryColor: primaryRed,
    scaffoldBackgroundColor: Colors.white, // 🌞 nền trắng sáng

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: primaryRed),
    ),

    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      shadowColor: Colors.grey,
    ),

    // ⚡ Không thay đổi nền input khi đổi theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkField, // giữ cùng màu xám đậm như dark
      hintStyle: const TextStyle(color: Colors.white60),
      labelStyle: const TextStyle(color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      prefixIconColor: Colors.white70,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6,
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
      titleLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      labelLarge: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),

    colorScheme: const ColorScheme.light(
      primary: primaryRed,
      secondary: primaryRed,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Colors.black87,
    ),
  );
}
