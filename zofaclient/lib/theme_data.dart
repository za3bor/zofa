import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        fontSize: 32.0.sp,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.rubik(
        fontSize: 20.0.sp,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.rubik(
        fontSize: 20.0.sp,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.rubik(
        fontSize: 15.0.sp,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 4.0,
      titleTextStyle: GoogleFonts.rubik(
        fontSize: 25.0.sp,
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
          fontSize: 16.0.sp,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0.r),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.rubik(
          fontSize: 16.0.sp,
        ),
      ),
    ),

    // Icon Theme
    iconTheme: IconThemeData(
      color: iconColor,
      size: 24.sp,
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: 4.0,
      color: const Color.fromARGB(255, 222, 210, 206),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0.r),
      ),
      shadowColor: Colors.black26,
      margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
    ),

    // BottomNavigationBar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.white.withOpacity(0.7),
      selectedLabelStyle: GoogleFonts.rubik(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: GoogleFonts.rubik(
        fontSize: 12.sp,
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromARGB(255, 222, 210, 206),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.r),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 9.h),
      hintStyle: GoogleFonts.rubik(
        color: Colors.black,
        fontSize: 14.sp,
      ),
      prefixIconColor: primaryColor,
      suffixIconColor: primaryColor,
    ),

// Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor; // Color for selected state
        }
        return Colors.grey; // Color for unselected state
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor; // Track color for selected state
        }
        return Colors.grey.withOpacity(0.5); // Track color for unselected state
      }),
    ),
  );
}
