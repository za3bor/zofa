import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildThemeData() {
  const Color primaryColor = Color(0xFF7A6244);
  const Color accentColor = Color(0xFFDFCFBE);
  const Color backgroundColor = Color(0xFFF5EFE4);
  const Color iconColor = Color(0xFF7A6244);
  const Color textColor = Colors.black87;

  return ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    canvasColor: backgroundColor,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.brown,
    ).copyWith(
      secondary: accentColor,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.rubik(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.rubik(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.rubik(
        fontSize: 22.0,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.rubik(
        fontSize: 15.0,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 4.0,
      titleTextStyle: GoogleFonts.rubik(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.rubik(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.rubik(
          fontSize: 16.0,
        ),
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: iconColor,
      size: 24.0,
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: 4.0,
      color: const Color.fromARGB(255, 222, 210, 206),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
    ),

    // BottomNavigationBar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.white.withOpacity(0.7),
      selectedLabelStyle: GoogleFonts.rubik(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: GoogleFonts.rubik(
        fontSize: 12.0,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromARGB(255, 222, 210, 206),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      hintStyle: GoogleFonts.rubik(
        color: Colors.black,
      ),
      prefixIconColor: primaryColor,
      suffixIconColor: primaryColor,
    ),
  );
}
