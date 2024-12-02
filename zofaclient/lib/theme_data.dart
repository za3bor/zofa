import 'package:flutter/material.dart';

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
    fontFamily: 'Assistant',

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
    ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 4.0,
      titleTextStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Assistant',
      ),
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          fontFamily: 'Assistant',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(
          fontSize: 16.0,
          fontFamily: 'Assistant',
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
      selectedLabelStyle: const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Assistant',
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12.0,
        fontFamily: 'Assistant',
      ),
    ),
    
    // Switch Theme for SwitchListTile
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(primaryColor), // Color of the thumb (the circular part)
      trackColor: WidgetStateProperty.all(Colors.grey), // Color of the track (background of the switch)
      overlayColor: WidgetStateProperty.all(primaryColor.withOpacity(0.2)), // Color of the thumb's hover/press state
    ),

    // Input Decoration Theme for TextField and TextFormField
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromARGB(255, 222, 210, 206),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      hintStyle: const TextStyle(color: Colors.black),
      prefixIconColor: primaryColor,
      suffixIconColor: primaryColor,
    ),
  );
}