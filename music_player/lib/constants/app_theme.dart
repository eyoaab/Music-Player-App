import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Luxury theme colors
  static const Color lightPrimary = Color(0xFF8A6D3B); // Gold-brown
  static const Color lightAccent = Color(0xFFD4AF37); // Metallic gold
  static const Color lightBackground = Colors.white;
  static const Color lightScaffoldBackground = Color(0xFFF8F8F8);
  static const Color lightText = Color(0xFF212121);
  static const Color lightSecondaryText = Color(0xFF757575);

  // Dark luxury theme colors
  static const Color darkPrimary = Color(0xFFBFA67A); // Soft gold
  static const Color darkAccent = Color(0xFFD4AF37); // Metallic gold
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkScaffoldBackground = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
  static const Color darkSecondaryText = Colors.white70;

  // Common colors
  static const Color errorColor = Color(0xFFB00020); // Deep red
  static const Color successColor = Color(0xFF4CAF50);
  static const Color iconColor = Color(0xFF8A6D3B); // Gold-brown

  // Get luxury text theme
  static TextTheme _getLuxuryTextTheme(
      TextTheme base, Color textColor, Color secondaryTextColor) {
    return base.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        textStyle: base.displayLarge
            ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        textStyle: base.displayMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        textStyle: base.displaySmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        textStyle: base.headlineMedium
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        textStyle: base.headlineSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      ),
      titleLarge: GoogleFonts.montserrat(
        textStyle: base.titleLarge?.copyWith(
            color: textColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      titleMedium: GoogleFonts.montserrat(
        textStyle: base.titleMedium?.copyWith(
            color: textColor, fontWeight: FontWeight.w600, letterSpacing: 0.25),
      ),
      titleSmall: GoogleFonts.montserrat(
        textStyle: base.titleSmall
            ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
      bodyLarge: GoogleFonts.lato(
        textStyle: base.bodyLarge?.copyWith(
            color: textColor, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      ),
      bodyMedium: GoogleFonts.lato(
        textStyle:
            base.bodyMedium?.copyWith(color: textColor, letterSpacing: 0.15),
      ),
      bodySmall: GoogleFonts.lato(
        textStyle: base.bodySmall
            ?.copyWith(color: secondaryTextColor, letterSpacing: 0.1),
      ),
      labelLarge: GoogleFonts.montserrat(
        textStyle: base.labelLarge?.copyWith(
            color: textColor, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      labelSmall: GoogleFonts.lato(
        textStyle: base.labelSmall
            ?.copyWith(color: secondaryTextColor, letterSpacing: 0.5),
      ),
    );
  }

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightAccent,
      background: lightBackground,
      error: errorColor,
      onPrimary: Colors.white, // Text on primary color
      onSecondary: Colors.white, // Text on secondary color
      surface: Colors.white,
      onSurface: lightText,
    ),
    scaffoldBackgroundColor: lightScaffoldBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: lightPrimary),
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: lightPrimary,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: lightPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: lightPrimary.withOpacity(0.05), width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: lightPrimary.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: lightPrimary,
      unselectedItemColor: Colors.black54,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: _getLuxuryTextTheme(
        ThemeData.light().textTheme, lightText, lightSecondaryText),
    iconTheme: const IconThemeData(color: iconColor, size: 24),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.lato(
        color: lightSecondaryText,
        fontSize: 16,
      ),
      labelStyle: GoogleFonts.montserrat(
        color: lightPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: lightPrimary.withOpacity(0.1),
      thickness: 1,
      space: 1,
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
      surface: Color(0xFF2C2C2C),
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: darkScaffoldBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: darkPrimary),
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: darkPrimary,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF252525),
      elevation: 3,
      shadowColor: darkPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkPrimary.withOpacity(0.08), width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: darkPrimary.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF252525),
      selectedItemColor: darkPrimary,
      unselectedItemColor: Colors.white70,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: _getLuxuryTextTheme(
        ThemeData.dark().textTheme, darkText, darkSecondaryText),
    iconTheme: const IconThemeData(color: darkPrimary, size: 24),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.lato(
        color: darkSecondaryText,
        fontSize: 16,
      ),
      labelStyle: GoogleFonts.montserrat(
        color: darkPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: darkPrimary.withOpacity(0.15),
      thickness: 1,
      space: 1,
    ),
  );
}
