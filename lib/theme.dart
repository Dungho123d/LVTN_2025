import 'package:flutter/material.dart';

class AppTheme {
  static const Color mainTeal = Color(0xFF00A6B2); // màu theo ảnh bạn gửi

  static ThemeData lightTheme = ThemeData(
    primaryColor: mainTeal, // dùng trực tiếp
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: mainTeal,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: mainTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: mainTeal, // Flutter sẽ tự sinh các sắc thái từ màu này
    ),
  );
}
