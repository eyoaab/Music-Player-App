import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color lightPrimary = Color(0xFFFFD700); // Yellow
  static const Color lightAccent = Color(0xFFFFA000); // Amber accent
  static const Color lightBackground = Colors.white;
  static const Color lightScaffoldBackground = Color(0xFFF8F8F8);
  static const Color lightText = Color(0xFF212121);
  static const Color lightSecondaryText = Color(0xFF757575);

  // Dark theme colors
  static const Color darkPrimary = Color(0xFFFFD54F); // Yellow for dark theme
  static const Color darkAccent = Color(0xFFFFB300); // Amber accent for dark
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkScaffoldBackground = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;

  // Common colors
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color iconColor = Color(0xFF616161);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightAccent,
      background: lightBackground,
      error: errorColor,
      onPrimary: Colors.black, // Text on primary color
      onSecondary: Colors.black, // Text on secondary color
      surface: Colors.white,
      onSurface: lightText,
    ),
    scaffoldBackgroundColor: lightScaffoldBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: lightPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightPrimary,
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.black54,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: lightText),
      displayMedium: TextStyle(color: lightText),
      displaySmall: TextStyle(color: lightText),
      headlineMedium: TextStyle(color: lightText),
      headlineSmall: TextStyle(color: lightText, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: lightText, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: lightText, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: lightText, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: lightText),
      bodyMedium: TextStyle(color: lightText),
      bodySmall: TextStyle(color: lightSecondaryText),
      labelLarge: TextStyle(color: lightText, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: lightSecondaryText),
    ),
    iconTheme: const IconThemeData(color: iconColor),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: darkPrimary,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkAccent,
      background: darkBackground,
      error: errorColor,
      onPrimary: Colors.black, // Text on primary color
      onSecondary: Colors.black, // Text on secondary color
      surface: const Color(0xFF2C2C2C),
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: darkScaffoldBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2C2C2C),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkPrimary,
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.black54,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkText),
      displayMedium: TextStyle(color: darkText),
      displaySmall: TextStyle(color: darkText),
      headlineMedium: TextStyle(color: darkText),
      headlineSmall: TextStyle(color: darkText, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: darkText, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: darkText, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: darkText, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: darkText),
      bodyMedium: TextStyle(color: darkText),
      bodySmall: TextStyle(color: darkSecondaryText),
      labelLarge: TextStyle(color: darkText, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(color: darkSecondaryText),
    ),
    iconTheme: const IconThemeData(color: darkAccent),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
